import logging
import time
from datetime import datetime, timezone

from app.db.session import SessionLocal
from app.jobs.executor import BackgroundJobExecutor
from app.jobs.registry import BACKGROUND_JOBS
from app.models.background_job import BackgroundJob
from app.models.enums import BackgroundJobStatus
from app.repositories.background_job import BackgroundJobRepository
from app.jobs.registry import (
    BACKGROUND_JOBS,
    BackgroundJobDefinition,
)
from datetime import datetime, timedelta, timezone


logger = logging.getLogger(__name__)

POLL_INTERVAL_SECONDS = 60
STALE_RUNNING_AFTER = timedelta(hours=2)


class BackgroundJobScheduler:
    """Schedule and execute registered background jobs."""
    
    def __init__(
        self,
        *,
        session_factory=SessionLocal,
    ) -> None:
        self._session_factory = session_factory

    def run_forever(
        self,
    ) -> None:
        """Continuously execute background jobs when they become due."""

        logger.info("Background job scheduler started.")

        while True:
            try:
                self.run_due_jobs()
            except Exception:
                logger.exception(
                    "Unexpected error while checking background jobs."
                )

            time.sleep(POLL_INTERVAL_SECONDS)

    def run_due_jobs(
        self,
    ) -> None:
        """Execute every registered job that is currently due."""

        now = datetime.now(timezone.utc)

        for definition in BACKGROUND_JOBS.values():
            try:
                self._run_if_due(
                    definition=definition,
                    now=now,
                )
            except Exception:
                logger.exception(
                    "Failed while scheduling background job '%s'.",
                    definition.key,
                )

    def _run_if_due(
        self,
        *,
        definition: BackgroundJobDefinition,
        now: datetime,
    ) -> None:
        """Run a background job when its next execution is due."""

        with self._session_factory() as session:
            repository = BackgroundJobRepository(
                session,
            )

            job = repository.get_by_key(
                definition.key,
            )

            if job is None:
                job = BackgroundJob(
                    key=definition.key,
                    name=definition.name,
                    schedule=definition.schedule_label,
                    status=BackgroundJobStatus.IDLE,
                    next_run_at=now,
                )

                repository.add(job)

                session.commit()
                session.refresh(job)

            if job.status == BackgroundJobStatus.RUNNING:
                if not self._is_stale_running_job(
                    job=job,
                    now=now,
                ):
                    logger.debug(
                        "Background job '%s' is already running.",
                        definition.key,
                    )
                    return

                logger.warning(
                    "Background job '%s' appears to be stale and will be retried.",
                    definition.key,
                )

            if not self._is_due(
                job=job,
                now=now,
            ):
                return

            logger.info(
                "Background job '%s' is due.",
                definition.key,
            )

            executor = BackgroundJobExecutor(
                session=session,
                repository=repository,
            )

            executor.execute(
                definition,
            )

    @staticmethod
    def _is_due(
        *,
        job: BackgroundJob,
        now: datetime,
    ) -> bool:
        """Return whether a background job should run now."""

        if job.next_run_at is None:
            return True

        next_run_at = job.next_run_at

        if next_run_at.tzinfo is None:
            next_run_at = next_run_at.replace(
                tzinfo=timezone.utc,
            )

        return next_run_at <= now
    
    @staticmethod
    def _is_stale_running_job(
        *,
        job: BackgroundJob,
        now: datetime,
    ) -> bool:
        """Return whether a running job appears to have been abandoned."""

        if job.last_started_at is None:
            return True

        last_started_at = job.last_started_at

        if last_started_at.tzinfo is None:
            last_started_at = last_started_at.replace(
                tzinfo=timezone.utc,
            )

        return (
            now - last_started_at
            >= STALE_RUNNING_AFTER
        )