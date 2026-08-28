from datetime import timedelta
from unittest.mock import Mock

import pytest
from sqlalchemy.orm import Session

from app.jobs.executor import BackgroundJobExecutor
from app.jobs.registry import BackgroundJobDefinition
from app.models.background_job import BackgroundJob
from app.models.enums import BackgroundJobStatus
from app.repositories.background_job import BackgroundJobRepository


@pytest.fixture
def repository(
    db_session: Session,
) -> BackgroundJobRepository:
    """Provide a background job repository using the test database."""

    return BackgroundJobRepository(
        db_session,
    )


@pytest.fixture
def executor(
    db_session: Session,
    repository: BackgroundJobRepository,
) -> BackgroundJobExecutor:
    """Provide a background job executor using the test database."""

    return BackgroundJobExecutor(
        session=db_session,
        repository=repository,
    )


def create_definition(
    *,
    handler,
    force_handler=None,
    key: str = "test_job",
    name: str = "Test job",
    schedule_label: str = "Every 8h",
    interval: timedelta = timedelta(hours=8),
) -> BackgroundJobDefinition:
    """Create a background job definition for executor tests."""

    return BackgroundJobDefinition(
        key=key,
        name=name,
        schedule_label=schedule_label,
        interval=interval,
        handler=handler,
        force_handler=force_handler,
    )


def test_execute_creates_job_when_missing(
    executor: BackgroundJobExecutor,
    repository: BackgroundJobRepository,
) -> None:
    """Create persisted job state when executing a new job."""

    handler = Mock(
        return_value=None,
    )

    definition = create_definition(
        handler=handler,
    )

    run = executor.execute(
        definition,
    )

    job = repository.get_by_key(
        definition.key,
    )

    assert job is not None

    assert job.key == "test_job"
    assert job.name == "Test job"
    assert job.schedule == "Every 8h"
    assert job.status == BackgroundJobStatus.SUCCESS

    assert run.job_id == job.id
    assert run.status == BackgroundJobStatus.SUCCESS

    handler.assert_called_once_with()


def test_execute_reuses_existing_job(
    db_session: Session,
    executor: BackgroundJobExecutor,
    repository: BackgroundJobRepository,
) -> None:
    """Reuse persisted job state instead of creating another job."""

    existing_job = BackgroundJob(
        key="test_job",
        name="Old name",
        schedule="Old schedule",
        status=BackgroundJobStatus.IDLE,
    )

    repository.add(existing_job)
    repository.commit()

    original_job_id = existing_job.id

    definition = create_definition(
        handler=Mock(return_value=None),
        name="Updated name",
        schedule_label="Every 8h",
    )

    executor.execute(
        definition,
    )

    db_session.expire_all()

    job = repository.get_by_key(
        "test_job",
    )

    assert job is not None
    assert job.id == original_job_id
    assert job.name == "Updated name"
    assert job.schedule == "Every 8h"

    jobs = repository.list_all()

    assert len(jobs) == 1


def test_execute_records_successful_run(
    executor: BackgroundJobExecutor,
    repository: BackgroundJobRepository,
) -> None:
    """Persist successful execution state and history."""

    handler = Mock(
        return_value=None,
    )

    definition = create_definition(
        handler=handler,
    )

    run = executor.execute(
        definition,
    )

    job = repository.get_by_key(
        definition.key,
    )

    assert job is not None

    assert run.status == BackgroundJobStatus.SUCCESS
    assert run.started_at is not None
    assert run.finished_at is not None
    assert run.duration_ms is not None
    assert run.duration_ms >= 0
    assert run.error is None

    assert job.status == BackgroundJobStatus.SUCCESS
    assert job.last_started_at is not None
    assert job.last_finished_at is not None
    assert job.last_duration_ms is not None
    assert job.last_duration_ms >= 0
    assert job.last_error is None
    assert job.next_run_at is not None


def test_execute_schedules_next_run_from_start_time(
    executor: BackgroundJobExecutor,
    repository: BackgroundJobRepository,
) -> None:
    """Schedule the next execution relative to the current run start."""

    definition = create_definition(
        handler=Mock(return_value=None),
        interval=timedelta(hours=8),
    )

    run = executor.execute(
        definition,
    )

    job = repository.get_by_key(
        definition.key,
    )

    assert job is not None
    assert job.next_run_at is not None

    expected_next_run = run.started_at.replace(tzinfo=None) + timedelta(hours=8)

    assert (
        job.next_run_at.replace(
            tzinfo=None,
        )
        == expected_next_run
    )


def test_execute_records_failed_run(
    executor: BackgroundJobExecutor,
    repository: BackgroundJobRepository,
) -> None:
    """Persist failure state when the job handler raises an exception."""

    handler = Mock(side_effect=RuntimeError("Something went wrong."))

    definition = create_definition(
        handler=handler,
    )

    run = executor.execute(
        definition,
    )

    job = repository.get_by_key(
        definition.key,
    )

    assert job is not None

    assert run.status == BackgroundJobStatus.FAILED
    assert run.started_at is not None
    assert run.finished_at is not None
    assert run.duration_ms is not None
    assert run.duration_ms >= 0
    assert run.error == "Something went wrong."

    assert job.status == BackgroundJobStatus.FAILED
    assert job.last_started_at is not None
    assert job.last_finished_at is not None
    assert job.last_duration_ms is not None
    assert job.last_error == "Something went wrong."
    assert job.next_run_at is not None

    handler.assert_called_once_with()


def test_execute_does_not_raise_handler_exception(
    executor: BackgroundJobExecutor,
) -> None:
    """Convert handler failures into failed job runs."""

    handler = Mock(side_effect=ValueError("Expected test failure."))

    definition = create_definition(
        handler=handler,
    )

    run = executor.execute(
        definition,
    )

    assert run.status == BackgroundJobStatus.FAILED
    assert run.error == "Expected test failure."


def test_execute_creates_run_for_each_execution(
    executor: BackgroundJobExecutor,
    repository: BackgroundJobRepository,
) -> None:
    """Create a separate history entry for every execution."""

    definition = create_definition(
        handler=Mock(return_value=None),
    )

    first_run = executor.execute(
        definition,
    )

    second_run = executor.execute(
        definition,
    )

    job = repository.get_by_key(
        definition.key,
    )

    assert job is not None

    runs = repository.list_runs(
        job_id=job.id,
    )

    assert len(runs) == 2

    assert {run.id for run in runs} == {
        first_run.id,
        second_run.id,
    }


def test_successful_execution_clears_previous_error(
    executor: BackgroundJobExecutor,
    repository: BackgroundJobRepository,
) -> None:
    """Clear the previous job error after a successful execution."""

    failing_definition = create_definition(
        handler=Mock(side_effect=RuntimeError("Temporary failure.")),
    )

    executor.execute(
        failing_definition,
    )

    failed_job = repository.get_by_key(
        "test_job",
    )

    assert failed_job is not None
    assert failed_job.status == BackgroundJobStatus.FAILED
    assert failed_job.last_error == "Temporary failure."

    successful_definition = create_definition(
        handler=Mock(return_value=None),
    )

    executor.execute(
        successful_definition,
    )

    job = repository.get_by_key(
        "test_job",
    )

    assert job is not None
    assert job.status == BackgroundJobStatus.SUCCESS
    assert job.last_error is None


def test_execute_persists_handler_result(
    executor: BackgroundJobExecutor,
) -> None:
    """Persist structured data returned by the job handler."""

    handler = Mock(
        return_value={
            "checked": 10,
            "refreshed": 4,
            "skipped": 6,
            "failed": 0,
        }
    )

    definition = create_definition(
        handler=handler,
    )

    run = executor.execute(
        definition,
    )

    assert run.status == BackgroundJobStatus.SUCCESS
    assert run.result == {
        "checked": 10,
        "refreshed": 4,
        "skipped": 6,
        "failed": 0,
    }


def test_execute_preserves_result_from_failed_handler(
    executor: BackgroundJobExecutor,
) -> None:
    """Persist structured result data exposed by a failed job."""

    class TestJobError(RuntimeError):
        def __init__(self) -> None:
            super().__init__("Partial failure.")
            self.result = {
                "checked": 10,
                "refreshed": 4,
                "skipped": 5,
                "failed": 1,
            }

    definition = create_definition(
        handler=Mock(
            side_effect=TestJobError(),
        ),
    )

    run = executor.execute(
        definition,
    )

    assert run.status == BackgroundJobStatus.FAILED
    assert run.error == "Partial failure."
    assert run.result == {
        "checked": 10,
        "refreshed": 4,
        "skipped": 5,
        "failed": 1,
    }

def test_execute_uses_force_handler_when_forced(
    executor: BackgroundJobExecutor,
) -> None:
    """Use the dedicated force handler for forced executions."""

    handler = Mock(
        return_value=None,
    )
    force_handler = Mock(
        return_value=None,
    )

    definition = create_definition(
        handler=handler,
        force_handler=force_handler,
    )

    run = executor.execute(
        definition,
        force=True,
    )

    assert run.status == BackgroundJobStatus.SUCCESS

    handler.assert_not_called()
    force_handler.assert_called_once_with()