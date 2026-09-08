import logging
import time
from collections.abc import Callable

from app.jobs.data_import_processor import DataImportProcessor
from app.jobs.scheduler import (
    POLL_INTERVAL_SECONDS as BACKGROUND_JOB_POLL_INTERVAL_SECONDS,
    BackgroundJobScheduler,
)

logger = logging.getLogger(__name__)

IMPORT_POLL_INTERVAL_SECONDS = 2.0


class WorkerRuntime:
    """Coordinate global background jobs and user-scoped imports."""

    def __init__(
        self,
        *,
        data_import_processor: DataImportProcessor,
        background_job_scheduler: BackgroundJobScheduler,
        monotonic: Callable[[], float] = time.monotonic,
        sleep: Callable[[float], None] = time.sleep,
    ) -> None:
        self._data_import_processor = data_import_processor
        self._background_job_scheduler = background_job_scheduler
        self._monotonic = monotonic
        self._sleep = sleep

        self._next_background_job_check: float | None = None

    def run_once(self) -> bool:
        """Process import work and run global jobs when their poll is due."""

        import_processed = self._data_import_processor.run_once()

        now = self._monotonic()

        if (
            self._next_background_job_check is None
            or now >= self._next_background_job_check
        ):
            self._background_job_scheduler.run_due_jobs()

            self._next_background_job_check = (
                now + BACKGROUND_JOB_POLL_INTERVAL_SECONDS
            )

        return import_processed

    def run_forever(self) -> None:
        """Continuously process SofaWatch background work."""

        logger.info("SofaWatch worker runtime started.")

        while True:
            try:
                import_processed = self.run_once()
            except Exception:
                logger.exception(
                    "Unexpected error while processing worker tasks."
                )
                import_processed = False

            if not import_processed:
                self._sleep(
                    IMPORT_POLL_INTERVAL_SECONDS,
                )