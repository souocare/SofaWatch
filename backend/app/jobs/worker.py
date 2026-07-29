from app.core.logging_config import configure_logging
from app.jobs.scheduler import BackgroundJobScheduler


def main() -> None:
    """Run the SofaWatch background job worker."""

    configure_logging()

    scheduler = BackgroundJobScheduler()

    scheduler.run_forever()


if __name__ == "__main__":
    main()
