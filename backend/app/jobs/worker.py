from app.core.logging_config import configure_logging
from app.jobs.data_import_processor import DataImportProcessor
from app.jobs.data_import_service_factory import (
    WorkerDataImportServiceFactory,
)
from app.jobs.scheduler import BackgroundJobScheduler
from app.jobs.worker_runtime import WorkerRuntime


def main() -> None:
    """Run the SofaWatch background worker."""

    configure_logging(
        component="worker",
    )

    service_factory = WorkerDataImportServiceFactory()

    processor = DataImportProcessor(
        service_factory=service_factory,
    )

    runtime = WorkerRuntime(
        data_import_processor=processor,
        background_job_scheduler=BackgroundJobScheduler(),
    )

    try:
        runtime.run_forever()
    finally:
        service_factory.close()


if __name__ == "__main__":
    main()
