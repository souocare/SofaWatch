import sys

from app.db.session import SessionLocal
from app.jobs.executor import BackgroundJobExecutor
from app.jobs.registry import get_background_job
from app.repositories.background_job import BackgroundJobRepository


def main() -> None:
    """Run a registered background job manually."""

    if len(sys.argv) != 2:
        raise SystemExit("Usage: python -m app.jobs.run <job_key>")

    job_key = sys.argv[1]

    definition = get_background_job(
        job_key,
    )

    if definition is None:
        raise SystemExit(f"Unknown background job: {job_key}")

    with SessionLocal() as session:
        executor = BackgroundJobExecutor(
            session=session,
            repository=BackgroundJobRepository(session),
        )

        run = executor.execute(
            definition,
        )

        print(f"{definition.key}: {run.status.value}")


if __name__ == "__main__":
    main()
