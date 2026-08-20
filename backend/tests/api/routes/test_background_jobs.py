from datetime import UTC, datetime

import pytest
from unittest.mock import patch
from app.repositories.background_job import BackgroundJobRepository
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session


from app.jobs.registry import BACKGROUND_JOBS
from app.models.background_job import BackgroundJob
from app.models.background_job_run import BackgroundJobRun
from app.models.enums import BackgroundJobStatus
from app.models.user import User



def create_local_user(
    db_session: Session,
    *,
    is_admin: bool,
) -> User:
    """Create the local application user for route authorization tests."""

    user = User(
        display_name="Administrator" if is_admin else "Regular User",
        is_local=True,
        is_admin=is_admin,
    )

    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)

    return user


def create_job(
    db_session: Session,
    *,
    key: str = "metadata_sync",
    name: str = "Metadata sync",
    schedule: str = "Every 8h",
    status: BackgroundJobStatus = BackgroundJobStatus.IDLE,
) -> BackgroundJob:
    """Create and persist a background job."""

    job = BackgroundJob(
        key=key,
        name=name,
        schedule=schedule,
        status=status,
    )

    db_session.add(job)
    db_session.commit()
    db_session.refresh(job)

    return job


def create_run(
    db_session: Session,
    *,
    job: BackgroundJob,
    status: BackgroundJobStatus = BackgroundJobStatus.SUCCESS,
    duration_ms: int = 100,
    result: dict[str, object] | None = None,
) -> BackgroundJobRun:
    """Create and persist a background job run."""

    now = datetime.now(UTC)

    run = BackgroundJobRun(
        job_id=job.id,
        status=status,
        started_at=now,
        finished_at=now,
        duration_ms=duration_ms,
        result=result,
    )

    db_session.add(run)
    db_session.commit()
    db_session.refresh(run)

    return run


def test_list_background_jobs_requires_admin(
    client: TestClient,
    db_session: Session,
) -> None:
    """Reject background job listing for non-administrators."""

    create_local_user(
        db_session,
        is_admin=False,
    )

    response = client.get(
        "/api/v1/background-jobs",
    )

    assert response.status_code == 403
    assert response.json()["error"]["code"] == "admin_required"


def test_list_background_jobs_returns_registered_jobs(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return the state of every registered background job."""

    create_local_user(
        db_session,
        is_admin=True,
    )

    response = client.get(
        "/api/v1/background-jobs",
    )

    assert response.status_code == 200

    body = response.json()

    assert len(body) == len(BACKGROUND_JOBS)

    metadata_sync = next(
        item
        for item in body
        if item["key"] == "metadata_sync"
    )

    assert metadata_sync["name"] == "Metadata sync"
    assert metadata_sync["schedule"] == "Every 8h"
    assert metadata_sync["status"] == "idle"


def test_list_background_jobs_returns_persisted_state(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return persisted execution state for registered jobs."""

    create_local_user(
        db_session,
        is_admin=True,
    )

    job = create_job(
        db_session,
        status=BackgroundJobStatus.SUCCESS,
    )

    create_run(
        db_session,
        job=job,
        duration_ms=125,
        result={
            "checked": 140,
            "refreshed": 23,
            "skipped": 117,
            "failed": 0,
        },
    )

    job.last_duration_ms = 125
    job.last_error = None

    db_session.commit()

    response = client.get(
        "/api/v1/background-jobs",
    )

    assert response.status_code == 200

    metadata_sync = next(
        item
        for item in response.json()
        if item["key"] == "metadata_sync"
    )

    assert metadata_sync["status"] == "success"
    assert metadata_sync["last_duration_ms"] == 125
    assert metadata_sync["last_result"] == {
        "checked": 140,
        "refreshed": 23,
        "skipped": 117,
        "failed": 0,
    }


def test_list_background_job_runs_requires_admin(
    client: TestClient,
    db_session: Session,
) -> None:
    """Reject background job history for non-administrators."""

    create_local_user(
        db_session,
        is_admin=False,
    )

    response = client.get(
        "/api/v1/background-jobs/metadata_sync/runs",
    )

    assert response.status_code == 403
    assert response.json()["error"]["code"] == "admin_required"


def test_list_background_job_runs_returns_history(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return recent runs for a registered background job."""

    create_local_user(
        db_session,
        is_admin=True,
    )

    job = create_job(
        db_session,
    )

    first_run = create_run(
        db_session,
        job=job,
        duration_ms=100,
    )

    second_run = create_run(
        db_session,
        job=job,
        duration_ms=200,
    )

    response = client.get(
        "/api/v1/background-jobs/metadata_sync/runs",
    )

    assert response.status_code == 200

    body = response.json()

    assert len(body) == 2

    returned_ids = {
        item["id"]
        for item in body
    }

    assert returned_ids == {
        str(first_run.id),
        str(second_run.id),
    }


def test_list_background_job_runs_returns_empty_when_no_runs_exist(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return an empty history for a registered job without executions."""

    create_local_user(
        db_session,
        is_admin=True,
    )

    response = client.get(
        "/api/v1/background-jobs/metadata_sync/runs",
    )

    assert response.status_code == 200
    assert response.json() == []


def test_list_background_job_runs_returns_404_for_unknown_job(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return HTTP 404 for an unregistered background job."""

    create_local_user(
        db_session,
        is_admin=True,
    )

    response = client.get(
        "/api/v1/background-jobs/not-a-job/runs",
    )

    assert response.status_code == 404
    assert response.json() == {
        "error": {
            "code": "background_job_not_found",
            "message": "Background job not found.",
        }
    }


def test_list_background_job_runs_applies_limit(
    client: TestClient,
    db_session: Session,
) -> None:
    """Limit the number of returned job executions."""

    create_local_user(
        db_session,
        is_admin=True,
    )

    job = create_job(
        db_session,
    )

    for duration in range(5):
        create_run(
            db_session,
            job=job,
            duration_ms=duration,
        )

    response = client.get(
        "/api/v1/background-jobs/metadata_sync/runs",
        params={
            "limit": 2,
        },
    )

    assert response.status_code == 200
    assert len(response.json()) == 2


@pytest.mark.parametrize(
    "limit",
    [
        0,
        101,
    ],
)
def test_list_background_job_runs_rejects_invalid_limit(
    client: TestClient,
    db_session: Session,
    limit: int,
) -> None:
    """Reject history limits outside the supported range."""

    create_local_user(
        db_session,
        is_admin=True,
    )

    response = client.get(
        "/api/v1/background-jobs/metadata_sync/runs",
        params={
            "limit": limit,
        },
    )

    assert response.status_code == 422


def test_run_background_job_now_requires_admin(
    client: TestClient,
    db_session: Session,
) -> None:
    """Reject manual background job execution for non-administrators."""

    create_local_user(
        db_session,
        is_admin=False,
    )

    response = client.post(
        "/api/v1/background-jobs/metadata_sync/run",
    )

    assert response.status_code == 403
    assert response.json()["error"]["code"] == "admin_required"


def test_run_background_job_now_returns_404_for_unknown_job(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return HTTP 404 when manually running an unknown job."""

    create_local_user(
        db_session,
        is_admin=True,
    )

    response = client.post(
        "/api/v1/background-jobs/not-a-job/run",
    )

    assert response.status_code == 404
    assert response.json() == {
        "error": {
            "code": "background_job_not_found",
            "message": "Background job not found.",
        }
    }


def test_run_background_job_now_returns_409_when_job_is_running(
    client: TestClient,
    db_session: Session,
) -> None:
    """Reject manual execution when the job is already running."""

    create_local_user(
        db_session,
        is_admin=True,
    )

    create_job(
        db_session,
        status=BackgroundJobStatus.RUNNING,
    )

    response = client.post(
        "/api/v1/background-jobs/metadata_sync/run",
    )

    assert response.status_code == 409
    assert response.json() == {
        "error": {
            "code": "background_job_already_running",
            "message": "Background job is already running.",
        }
    }

def test_list_background_jobs_returns_last_result_from_failed_run(
    client: TestClient,
    db_session: Session,
) -> None:
    """Expose summary metrics from the latest failed execution."""

    create_local_user(
        db_session,
        is_admin=True,
    )

    job = create_job(
        db_session,
        status=BackgroundJobStatus.FAILED,
    )

    create_run(
        db_session,
        job=job,
        status=BackgroundJobStatus.FAILED,
        result={
            "checked": 10,
            "refreshed": 4,
            "skipped": 5,
            "failed": 1,
        },
    )

    response = client.get(
        "/api/v1/background-jobs",
    )

    assert response.status_code == 200

    metadata_sync = next(
        item
        for item in response.json()
        if item["key"] == "metadata_sync"
    )

    assert metadata_sync["status"] == "failed"

    assert metadata_sync["last_result"] == {
        "checked": 10,
        "refreshed": 4,
        "skipped": 5,
        "failed": 1,
    }


def test_list_background_jobs_ignores_unsupported_last_result(
    client: TestClient,
    db_session: Session,
) -> None:
    """Ignore result payloads that do not contain supported summary metrics."""

    create_local_user(
        db_session,
        is_admin=True,
    )

    job = create_job(
        db_session,
        status=BackgroundJobStatus.SUCCESS,
    )

    create_run(
        db_session,
        job=job,
        result={
            "message": "Different job result.",
        },
    )

    response = client.get(
        "/api/v1/background-jobs",
    )

    assert response.status_code == 200

    metadata_sync = next(
        item
        for item in response.json()
        if item["key"] == "metadata_sync"
    )

    assert metadata_sync["last_result"] is None


def test_run_background_job_now_accepts_manual_execution(
    client: TestClient,
    db_session: Session,
) -> None:
    """Accept manual execution and expose the running job state."""

    create_local_user(
        db_session,
        is_admin=True,
    )

    with patch(
        "app.api.routes.background_jobs.run_background_job_manually",
    ) as runner:
        response = client.post(
            "/api/v1/background-jobs/metadata_sync/run",
        )

    assert response.status_code == 202

    payload = response.json()

    assert payload["job"]["key"] == "metadata_sync"
    assert payload["job"]["name"] == "Metadata sync"
    assert payload["job"]["schedule"] == "Every 8h"
    assert payload["job"]["status"] == "running"

    runner.assert_called_once_with(
        "metadata_sync",
    )

def test_run_background_job_now_persists_running_state(
    client: TestClient,
    db_session: Session,
) -> None:
    """Persist running state before dispatching manual execution."""

    create_local_user(
        db_session,
        is_admin=True,
    )

    with patch(
        "app.api.routes.background_jobs.run_background_job_manually",
    ):
        response = client.post(
            "/api/v1/background-jobs/metadata_sync/run",
        )

    assert response.status_code == 202

    repository = BackgroundJobRepository(
        db_session,
    )

    job = repository.get_by_key(
        "metadata_sync",
    )

    assert job is not None
    assert job.status == BackgroundJobStatus.RUNNING