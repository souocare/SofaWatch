from datetime import UTC, datetime
from typing import Annotated

from fastapi import APIRouter, BackgroundTasks, Path, Query, status

from app.api.dependencies import (
    AdminUserDependency,
    BackgroundJobRepositoryDependency,
)
from app.core.exceptions import APIError
from app.jobs.manual_runner import run_background_job_manually
from app.jobs.registry import BACKGROUND_JOBS, get_background_job
from app.models.background_job import BackgroundJob
from app.models.background_job_run import BackgroundJobRun
from app.models.enums import BackgroundJobStatus
from app.schemas.background_job import (
    BackgroundJobResponse,
    BackgroundJobResultSummaryResponse,
    BackgroundJobRunNowResponse,
    BackgroundJobRunResponse,
)

router = APIRouter(
    prefix="/background-jobs",
    tags=["Background jobs"],
)


def _background_job_response(
    *,
    job: BackgroundJob,
    latest_run: BackgroundJobRun | None,
) -> BackgroundJobResponse:
    """Build the API representation of a background job."""

    return BackgroundJobResponse(
        id=job.id,
        key=job.key,
        name=job.name,
        schedule=job.schedule,
        status=job.status,
        last_started_at=job.last_started_at,
        last_finished_at=job.last_finished_at,
        last_duration_ms=job.last_duration_ms,
        last_error=job.last_error,
        next_run_at=job.next_run_at,
        last_result=_background_job_result_summary(
            latest_run.result if latest_run is not None else None,
        ),
    )


def _background_job_result_summary(
    result: dict[str, object] | None,
) -> BackgroundJobResultSummaryResponse | None:
    """Return supported summary metrics from a background job result."""

    if result is None:
        return None

    checked = result.get("checked")
    refreshed = result.get("refreshed")
    skipped = result.get("skipped")
    failed = result.get("failed")

    if not all(
        isinstance(value, int) and value >= 0
        for value in (
            checked,
            refreshed,
            skipped,
            failed,
        )
    ):
        return None

    return BackgroundJobResultSummaryResponse(
        checked=checked,
        refreshed=refreshed,
        skipped=skipped,
        failed=failed,
    )


@router.get(
    "",
    response_model=list[BackgroundJobResponse],
    summary="List background jobs",
    description="Return the current state of all registered background jobs.",
)
def list_background_jobs(
    admin_user: AdminUserDependency,
    repository: BackgroundJobRepositoryDependency,
) -> list[BackgroundJobResponse]:
    """Return all registered background jobs."""

    del admin_user

    jobs_by_key = {job.key: job for job in repository.list_all()}

    jobs: list[BackgroundJob] = []

    for definition in BACKGROUND_JOBS.values():
        job = jobs_by_key.get(
            definition.key,
        )

        if job is None:
            job = BackgroundJob(
                key=definition.key,
                name=definition.name,
                schedule=definition.schedule_label,
                status=BackgroundJobStatus.IDLE,
            )

            repository.add(job)
        else:
            job.name = definition.name
            job.schedule = definition.schedule_label

        jobs.append(job)

    repository.commit()

    return [
        _background_job_response(
            job=job,
            latest_run=repository.get_latest_run(
                job_id=job.id,
            ),
        )
        for job in jobs
    ]


@router.get(
    "/{job_key}/runs",
    response_model=list[BackgroundJobRunResponse],
    summary="List background job runs",
    description="Return recent execution history for a background job.",
)
def list_background_job_runs(
    admin_user: AdminUserDependency,
    job_key: Annotated[
        str,
        Path(
            min_length=1,
            max_length=100,
            description="Registered background job key.",
        ),
    ],
    repository: BackgroundJobRepositoryDependency,
    limit: Annotated[
        int,
        Query(
            ge=1,
            le=100,
        ),
    ] = 20,
) -> list[BackgroundJobRunResponse]:
    """Return recent executions of a background job."""

    del admin_user

    if get_background_job(job_key) is None:
        raise APIError(
            status_code=status.HTTP_404_NOT_FOUND,
            code="background_job_not_found",
            message="Background job not found.",
        )

    job = repository.get_by_key(
        job_key,
    )

    if job is None:
        return []

    return repository.list_runs(
        job_id=job.id,
        limit=limit,
    )


@router.post(
    "/{job_key}/run",
    response_model=BackgroundJobRunNowResponse,
    status_code=status.HTTP_202_ACCEPTED,
    summary="Run background job now",
    description="Schedule a registered background job for immediate execution.",
)
def run_background_job_now(
    admin_user: AdminUserDependency,
    background_tasks: BackgroundTasks,
    job_key: Annotated[
        str,
        Path(
            min_length=1,
            max_length=100,
            description="Registered background job key.",
        ),
    ],
    repository: BackgroundJobRepositoryDependency,
    force: Annotated[
        bool,
        Query(
            description=(
                "Run the job using its forced execution mode, "
                "when supported."
            ),
        ),
    ] = False,
) -> BackgroundJobRunNowResponse:
    """Schedule a registered background job for immediate execution."""

    del admin_user

    definition = get_background_job(
        job_key,
    )

    if definition is None:
        raise APIError(
            status_code=status.HTTP_404_NOT_FOUND,
            code="background_job_not_found",
            message="Background job not found.",
        )

    if force and definition.force_handler is None:
        raise APIError(
            status_code=status.HTTP_400_BAD_REQUEST,
            code="background_job_force_not_supported",
            message="This background job does not support forced execution.",
        )

    job = repository.get_by_key(
        job_key,
    )

    if job is None:
        job = BackgroundJob(
            key=definition.key,
            name=definition.name,
            schedule=definition.schedule_label,
            status=BackgroundJobStatus.IDLE,
        )

        repository.add(job)

    if job.status == BackgroundJobStatus.RUNNING:
        raise APIError(
            status_code=status.HTTP_409_CONFLICT,
            code="background_job_already_running",
            message="Background job is already running.",
        )

    job.name = definition.name
    job.schedule = definition.schedule_label
    job.status = BackgroundJobStatus.RUNNING
    job.last_started_at = datetime.now(UTC)
    job.last_error = None

    repository.commit()
    repository.refresh(job)

    latest_run = repository.get_latest_run(
        job_id=job.id,
    )

    background_tasks.add_task(
        run_background_job_manually,
        job_key,
        force=force,
    )

    return BackgroundJobRunNowResponse(
        job=_background_job_response(
            job=job,
            latest_run=latest_run,
        ),
    )
