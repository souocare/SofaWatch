import logging
from collections.abc import Callable
from datetime import UTC, datetime, timedelta

from sqlalchemy.orm import Session, sessionmaker

from app.db.session import SessionLocal
from app.repositories.data_import_run import DataImportRunRepository
from app.schemas.data_export import SofaWatchExportResponse
from app.services.data_import import DataImportService
from app.jobs.data_import_progress_tracker import (
    DataImportProgressTracker,
)

logger = logging.getLogger(__name__)
STALE_IMPORT_AFTER = timedelta(minutes=30)

DataImportServiceFactory = Callable[
    [Session],
    DataImportService,
]


class DataImportProcessor:
    """Claim and execute persistent user data imports."""

    def __init__(
        self,
        *,
        service_factory: DataImportServiceFactory,
        session_factory: sessionmaker[Session] = SessionLocal,
    ) -> None:
        self._service_factory = service_factory
        self._session_factory = session_factory

    def run_once(self) -> bool:
        """Execute one queued import and return whether work was claimed."""

        with self._session_factory() as session:
            repository = DataImportRunRepository(
                session,
            )

            now = datetime.now(UTC)

            interrupted_count = repository.fail_stale_running(
                stale_before=now - STALE_IMPORT_AFTER,
                finished_at=now,
            )

            if interrupted_count:
                logger.warning(
                    "Marked %s stale data import run(s) as interrupted.",
                    interrupted_count,
                )

            run = repository.claim_next_queued(
                now=now,
            )

            if run is None:
                return False

            run_id = run.id
            user_id = run.user_id

            logger.info(
                "Starting data import run %s for user %s.",
                run_id,
                user_id,
            )

            try:
                if run.payload is None:
                    raise ValueError(
                        "Queued data import has no persisted payload."
                    )

                export = SofaWatchExportResponse.model_validate(
                    run.payload,
                )

                service = self._service_factory(
                    session,
                )

                progress_tracker = DataImportProgressTracker(
                    repository=repository,
                    run=run,
                )

                result = service.import_user_data(
                    user_id=user_id,
                    export=export,
                    progress_callback=progress_tracker,
                )

                run = repository.get_by_id(
                    run_id=run_id,
                )

                if run is None:
                    logger.warning(
                        "Data import run %s disappeared during execution.",
                        run_id,
                    )
                    return True

                repository.mark_completed(
                    run=run,
                    result=result.model_dump(
                        mode="json",
                    ),
                    finished_at=datetime.now(UTC),
                )

                logger.info(
                    "Completed data import run %s for user %s.",
                    run_id,
                    user_id,
                )

            except Exception:
                session.rollback()

                logger.exception(
                    "Data import run %s failed for user %s.",
                    run_id,
                    user_id,
                )

                run = repository.get_by_id(
                    run_id=run_id,
                )

                if run is not None:
                    repository.mark_failed(
                        run=run,
                        error_code="data_import_failed",
                        error_message=(
                            "The data import could not be completed."
                        ),
                        finished_at=datetime.now(UTC),
                    )

            return True