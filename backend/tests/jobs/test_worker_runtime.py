from unittest.mock import Mock

from app.jobs.scheduler import POLL_INTERVAL_SECONDS
from app.jobs.worker_runtime import WorkerRuntime


def test_run_once_processes_import_and_checks_background_jobs() -> None:
    processor = Mock()
    processor.run_once.return_value = True

    scheduler = Mock()

    runtime = WorkerRuntime(
        data_import_processor=processor,
        background_job_scheduler=scheduler,
        monotonic=Mock(
            return_value=100.0,
        ),
    )

    assert runtime.run_once() is True

    processor.run_once.assert_called_once_with()
    scheduler.run_due_jobs.assert_called_once_with()


def test_run_once_does_not_check_background_jobs_before_interval() -> None:
    processor = Mock()
    processor.run_once.return_value = False

    scheduler = Mock()

    monotonic = Mock(
        side_effect=[
            100.0,
            110.0,
        ]
    )

    runtime = WorkerRuntime(
        data_import_processor=processor,
        background_job_scheduler=scheduler,
        monotonic=monotonic,
    )

    runtime.run_once()
    runtime.run_once()

    assert processor.run_once.call_count == 2
    assert scheduler.run_due_jobs.call_count == 1


def test_run_once_checks_background_jobs_after_interval() -> None:
    processor = Mock()
    processor.run_once.return_value = False

    scheduler = Mock()

    monotonic = Mock(
        side_effect=[
            100.0,
            100.0 + POLL_INTERVAL_SECONDS,
        ]
    )

    runtime = WorkerRuntime(
        data_import_processor=processor,
        background_job_scheduler=scheduler,
        monotonic=monotonic,
    )

    runtime.run_once()
    runtime.run_once()

    assert scheduler.run_due_jobs.call_count == 2


def test_run_forever_sleeps_when_no_import_was_processed() -> None:
    processor = Mock()

    processor.run_once.side_effect = [
        False,
        KeyboardInterrupt,
    ]

    scheduler = Mock()
    sleep = Mock()

    runtime = WorkerRuntime(
        data_import_processor=processor,
        background_job_scheduler=scheduler,
        monotonic=Mock(
            return_value=100.0,
        ),
        sleep=sleep,
    )

    try:
        runtime.run_forever()
    except KeyboardInterrupt:
        pass

    sleep.assert_called_once()
