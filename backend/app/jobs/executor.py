import logging
from datetime import UTC, datetime
from time import perf_counter

from sqlalchemy.orm import Session

from app.jobs.registry import BackgroundJobDefinition
from app.models.background_job import BackgroundJob
from app.models.background_job_run import BackgroundJobRun
from app.models.enums import BackgroundJobStatus
from app.repositories.background_job import BackgroundJobRepository

logger = logging.getLogger(__name__)


class BackgroundJobExecutor:
    """Execute background jobs and persist their execution state."""

    def __init__(
        self,
        *,
        session: Session,
        repository: BackgroundJobRepository,
    ) -> None:
        self._session = session
        self._repository = repository

    def execute(
        self,
        definition: BackgroundJobDefinition,
    ) -> BackgroundJobRun:
        """Execute a registered background job."""

        job = self._get_or_create_job(
            definition,
        )

        started_at = datetime.now(UTC)

        run = BackgroundJobRun(
            job_id=job.id,
            status=BackgroundJobStatus.RUNNING,
            started_at=started_at,
        )

        self._repository.add_run(run)

        job.status = BackgroundJobStatus.RUNNING
        job.last_started_at = started_at
        job.last_error = None

        self._session.commit()
        self._session.refresh(job)
        self._session.refresh(run)

        started_timer = perf_counter()

        logger.info(
            "Background job '%s' started.",
            definition.key,
        )

        try:
            definition.handler()

        except Exception as error:
            duration_ms = self._duration_ms(
                started_timer,
            )

            finished_at = datetime.now(UTC)

            run.status = BackgroundJobStatus.FAILED
            run.finished_at = finished_at
            run.duration_ms = duration_ms
            run.error = str(error)

            job.status = BackgroundJobStatus.FAILED
            job.last_finished_at = finished_at
            job.last_duration_ms = duration_ms
            job.last_error = str(error)
            job.next_run_at = started_at + definition.interval

            self._session.commit()
            self._session.refresh(run)
            self._session.refresh(job)

            logger.exception(
                "Background job '%s' failed.",
                definition.key,
            )

            return run

        duration_ms = self._duration_ms(
            started_timer,
        )

        finished_at = datetime.now(UTC)

        run.status = BackgroundJobStatus.SUCCESS
        run.finished_at = finished_at
        run.duration_ms = duration_ms
        run.error = None

        job.status = BackgroundJobStatus.SUCCESS
        job.last_finished_at = finished_at
        job.last_duration_ms = duration_ms
        job.last_error = None
        job.next_run_at = started_at + definition.interval

        self._session.commit()
        self._session.refresh(run)
        self._session.refresh(job)

        logger.info(
            "Background job '%s' completed in %sms.",
            definition.key,
            duration_ms,
        )

        return run

    def _get_or_create_job(
        self,
        definition: BackgroundJobDefinition,
    ) -> BackgroundJob:
        """Return persisted state for a registered job."""

        job = self._repository.get_by_key(
            definition.key,
        )

        if job is not None:
            job.name = definition.name
            job.schedule = definition.schedule_label

            return job

        job = BackgroundJob(
            key=definition.key,
            name=definition.name,
            schedule=definition.schedule_label,
            status=BackgroundJobStatus.IDLE,
        )

        self._repository.add(job)

        self._session.flush()

        return job

    @staticmethod
    def _duration_ms(
        started_timer: float,
    ) -> int:
        """Return elapsed execution time in milliseconds."""

        return round((perf_counter() - started_timer) * 1000)
