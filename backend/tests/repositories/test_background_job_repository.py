from datetime import datetime, timedelta, timezone

from sqlalchemy.orm import Session

from app.models.background_job import BackgroundJob
from app.models.background_job_run import BackgroundJobRun
from app.models.enums import BackgroundJobStatus
from app.repositories.background_job import BackgroundJobRepository

def test_add_and_get_background_job(
    db_session: Session,
) -> None:
    """Persist and retrieve a background job by key."""

    repository = BackgroundJobRepository(
        db_session,
    )

    job = BackgroundJob(
        key="metadata_sync",
        name="Metadata sync",
        schedule="Every 8h",
        status=BackgroundJobStatus.IDLE,
    )

    repository.add(job)
    repository.commit()

    result = repository.get_by_key(
        "metadata_sync",
    )

    assert result is not None
    assert result.id == job.id
    assert result.key == "metadata_sync"
    assert result.name == "Metadata sync"
    assert result.schedule == "Every 8h"
    assert result.status == BackgroundJobStatus.IDLE

def test_get_by_key_returns_none_when_job_does_not_exist(
    db_session: Session,
) -> None:
    """Return None when a background job does not exist."""

    repository = BackgroundJobRepository(
        db_session,
    )

    result = repository.get_by_key(
        "unknown_job",
    )

    assert result is None

def test_list_all_returns_jobs_ordered_by_name(
    db_session: Session,
) -> None:
    """Return background jobs ordered by name."""

    repository = BackgroundJobRepository(
        db_session,
    )

    repository.add(
        BackgroundJob(
            key="metadata_sync",
            name="Metadata sync",
            schedule="Every 8h",
            status=BackgroundJobStatus.IDLE,
        )
    )

    repository.add(
        BackgroundJob(
            key="backup",
            name="Backup",
            schedule="Daily",
            status=BackgroundJobStatus.IDLE,
        )
    )

    repository.commit()

    result = repository.list_all()

    assert [
        job.key
        for job in result
    ] == [
        "backup",
        "metadata_sync",
    ]

def test_add_run_persists_background_job_run(
    db_session: Session,
) -> None:
    """Persist an execution for a background job."""

    repository = BackgroundJobRepository(
        db_session,
    )

    job = BackgroundJob(
        key="metadata_sync",
        name="Metadata sync",
        schedule="Every 8h",
        status=BackgroundJobStatus.IDLE,
    )

    repository.add(job)
    repository.commit()

    started_at = datetime.now(timezone.utc)

    run = BackgroundJobRun(
        job_id=job.id,
        status=BackgroundJobStatus.SUCCESS,
        started_at=started_at,
        finished_at=started_at,
        duration_ms=125,
    )

    repository.add_run(run)
    repository.commit()

    result = repository.list_runs(
        job_id=job.id,
    )

    assert len(result) == 1

    stored_run = result[0]

    assert stored_run.id == run.id
    assert stored_run.job_id == job.id
    assert stored_run.status == BackgroundJobStatus.SUCCESS
    assert stored_run.duration_ms == 125
    assert stored_run.error is None

def test_add_run_persists_background_job_run(
    db_session: Session,
) -> None:
    """Persist an execution for a background job."""

    repository = BackgroundJobRepository(
        db_session,
    )

    job = BackgroundJob(
        key="metadata_sync",
        name="Metadata sync",
        schedule="Every 8h",
        status=BackgroundJobStatus.IDLE,
    )

    repository.add(job)
    repository.commit()

    started_at = datetime.now(timezone.utc)

    run = BackgroundJobRun(
        job_id=job.id,
        status=BackgroundJobStatus.SUCCESS,
        started_at=started_at,
        finished_at=started_at,
        duration_ms=125,
    )

    repository.add_run(run)
    repository.commit()

    result = repository.list_runs(
        job_id=job.id,
    )

    assert len(result) == 1

    stored_run = result[0]

    assert stored_run.id == run.id
    assert stored_run.job_id == job.id
    assert stored_run.status == BackgroundJobStatus.SUCCESS
    assert stored_run.duration_ms == 125
    assert stored_run.error is None


def test_list_runs_returns_most_recent_first(
    db_session: Session,
) -> None:
    """Return job executions ordered from newest to oldest."""

    repository = BackgroundJobRepository(
        db_session,
    )

    job = BackgroundJob(
        key="metadata_sync",
        name="Metadata sync",
        schedule="Every 8h",
        status=BackgroundJobStatus.IDLE,
    )

    repository.add(job)
    repository.commit()

    now = datetime.now(timezone.utc)

    old_run = BackgroundJobRun(
        job_id=job.id,
        status=BackgroundJobStatus.SUCCESS,
        started_at=now - timedelta(hours=8),
    )

    new_run = BackgroundJobRun(
        job_id=job.id,
        status=BackgroundJobStatus.SUCCESS,
        started_at=now,
    )

    repository.add_run(old_run)
    repository.add_run(new_run)
    repository.commit()

    result = repository.list_runs(
        job_id=job.id,
    )

    assert len(result) == 2
    assert result[0].id == new_run.id
    assert result[1].id == old_run.id


def test_list_runs_only_returns_runs_for_requested_job(
    db_session: Session,
) -> None:
    """Only return executions belonging to the requested job."""

    repository = BackgroundJobRepository(
        db_session,
    )

    metadata_job = BackgroundJob(
        key="metadata_sync",
        name="Metadata sync",
        schedule="Every 8h",
        status=BackgroundJobStatus.IDLE,
    )

    backup_job = BackgroundJob(
        key="backup",
        name="Backup",
        schedule="Daily",
        status=BackgroundJobStatus.IDLE,
    )

    repository.add(metadata_job)
    repository.add(backup_job)
    repository.commit()

    now = datetime.now(timezone.utc)

    repository.add_run(
        BackgroundJobRun(
            job_id=metadata_job.id,
            status=BackgroundJobStatus.SUCCESS,
            started_at=now,
        )
    )

    repository.add_run(
        BackgroundJobRun(
            job_id=backup_job.id,
            status=BackgroundJobStatus.SUCCESS,
            started_at=now,
        )
    )

    repository.commit()

    result = repository.list_runs(
        job_id=metadata_job.id,
    )

    assert len(result) == 1
    assert result[0].job_id == metadata_job.id


def test_list_runs_respects_limit(
    db_session: Session,
) -> None:
    """Limit the number of returned job executions."""

    repository = BackgroundJobRepository(
        db_session,
    )

    job = BackgroundJob(
        key="metadata_sync",
        name="Metadata sync",
        schedule="Every 8h",
        status=BackgroundJobStatus.IDLE,
    )

    repository.add(job)
    repository.commit()

    now = datetime.now(timezone.utc)

    for index in range(5):
        repository.add_run(
            BackgroundJobRun(
                job_id=job.id,
                status=BackgroundJobStatus.SUCCESS,
                started_at=now + timedelta(minutes=index),
            )
        )

    repository.commit()

    result = repository.list_runs(
        job_id=job.id,
        limit=2,
    )

    assert len(result) == 2


