import logging

from app.db.session import SessionLocal
from app.jobs.executor import BackgroundJobExecutor
from app.jobs.registry import get_background_job
from app.repositories.background_job import BackgroundJobRepository

logger = logging.getLogger(__name__)


def run_background_job_manually(
    job_key: str,
) -> None:
    """Execute a registered background job using an independent session."""

    definition = get_background_job(
        job_key,
    )

    if definition is None:
        logger.error(
            "Manual background job '%s' is no longer registered.",
            job_key,
        )
        return

    with SessionLocal() as session:
        repository = BackgroundJobRepository(
            session,
        )

        executor = BackgroundJobExecutor(
            session=session,
            repository=repository,
        )

        executor.execute(
            definition,
        )
