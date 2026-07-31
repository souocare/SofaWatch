from typing import Annotated

from fastapi import APIRouter, Path, Query, status
from app.core.exceptions import APIError

from app.api.dependencies import (
    BackgroundJobExecutorDependency,
    BackgroundJobRepositoryDependency,
)
from app.jobs.registry import BACKGROUND_JOBS, get_background_job
from app.models.background_job import BackgroundJob
from app.models.enums import BackgroundJobStatus
from app.schemas.background_job import (
    BackgroundJobResponse,
    BackgroundJobRunNowResponse,
    BackgroundJobRunResponse,
)

router = APIRouter(
    prefix="/background-jobs",
    tags=["Background jobs"],
)


@router.get(
    "",
    response_model=list[BackgroundJobResponse],
    summary="List background jobs",
    description="Return the current state of all registered background jobs.",
)
def list_background_jobs(
    repository: BackgroundJobRepositoryDependency,
) -> list[BackgroundJobResponse]:
    """Return all registered background jobs."""

    jobs_by_key = {job.key: job for job in repository.list_all()}

    result: list[BackgroundJob] = []

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

        result.append(job)

    repository.commit()

    return result


@router.get(
    "/{job_key}/runs",
    response_model=list[BackgroundJobRunResponse],
    summary="List background job runs",
    description="Return recent execution history for a background job.",
)
def list_background_job_runs(
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
    summary="Run background job now",
    description="Execute a registered background job immediately.",
)
def run_background_job_now(
    job_key: Annotated[
        str,
        Path(
            min_length=1,
            max_length=100,
            description="Registered background job key.",
        ),
    ],
    repository: BackgroundJobRepositoryDependency,
    executor: BackgroundJobExecutorDependency,
) -> BackgroundJobRunNowResponse:
    """Run a registered background job immediately."""

    definition = get_background_job(
        job_key,
    )

    if definition is None:
        raise APIError(
            status_code=status.HTTP_404_NOT_FOUND,
            code="background_job_not_found",
            message="Background job not found.",
        )

    existing_job = repository.get_by_key(
        job_key,
    )

    if existing_job is not None and existing_job.status == BackgroundJobStatus.RUNNING:
        raise APIError(
            status_code=status.HTTP_409_CONFLICT,
            code="background_job_already_running",
            message="Background job is already running.",
        )

    run = executor.execute(
        definition,
    )

    job = repository.get_by_key(
        job_key,
    )

    if job is None:
        raise RuntimeError("Background job state was not persisted.")

    return BackgroundJobRunNowResponse(
        job=job,
        run=run,
    )
