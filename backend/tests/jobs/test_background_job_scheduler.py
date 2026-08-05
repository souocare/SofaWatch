from collections.abc import Iterator
from contextlib import contextmanager
from datetime import UTC, datetime, timedelta
from unittest.mock import Mock

import pytest
from sqlalchemy.orm import Session

from app.jobs.registry import BackgroundJobDefinition
from app.jobs.scheduler import BackgroundJobScheduler
from app.models.background_job import BackgroundJob
from app.models.enums import BackgroundJobStatus
from app.repositories.background_job import BackgroundJobRepository


@pytest.fixture
def scheduler() -> BackgroundJobScheduler:
    """Provide a background job scheduler."""

    return BackgroundJobScheduler()


@pytest.fixture
def repository(
    db_session: Session,
) -> BackgroundJobRepository:
    """Provide a background job repository using the test database."""

    return BackgroundJobRepository(
        db_session,
    )


def create_definition(
    *,
    handler=None,
) -> BackgroundJobDefinition:
    """Create a background job definition for scheduler tests."""

    return BackgroundJobDefinition(
        key="test_job",
        name="Test job",
        schedule_label="Every 8h",
        interval=timedelta(hours=8),
        handler=handler if handler is not None else Mock(return_value=None),
    )


def test_is_due_when_next_run_is_missing(
    scheduler: BackgroundJobScheduler,
) -> None:
    """Treat a job without a next execution date as due."""

    job = BackgroundJob(
        key="test_job",
        name="Test job",
        schedule="Every 8h",
        status=BackgroundJobStatus.IDLE,
        next_run_at=None,
    )

    now = datetime.now(UTC)

    assert scheduler._is_due(
        job=job,
        now=now,
    )


def test_is_due_when_next_run_is_in_the_past(
    scheduler: BackgroundJobScheduler,
) -> None:
    """Treat a job with an expired next run date as due."""

    now = datetime.now(UTC)

    job = BackgroundJob(
        key="test_job",
        name="Test job",
        schedule="Every 8h",
        status=BackgroundJobStatus.SUCCESS,
        next_run_at=now - timedelta(minutes=1),
    )

    assert scheduler._is_due(
        job=job,
        now=now,
    )


def test_is_due_when_next_run_equals_now(
    scheduler: BackgroundJobScheduler,
) -> None:
    """Treat a job scheduled for now as due."""

    now = datetime.now(UTC)

    job = BackgroundJob(
        key="test_job",
        name="Test job",
        schedule="Every 8h",
        status=BackgroundJobStatus.SUCCESS,
        next_run_at=now,
    )

    assert scheduler._is_due(
        job=job,
        now=now,
    )


def test_is_not_due_when_next_run_is_in_the_future(
    scheduler: BackgroundJobScheduler,
) -> None:
    """Do not run a job before its next execution date."""

    now = datetime.now(UTC)

    job = BackgroundJob(
        key="test_job",
        name="Test job",
        schedule="Every 8h",
        status=BackgroundJobStatus.SUCCESS,
        next_run_at=now + timedelta(hours=1),
    )

    assert not scheduler._is_due(
        job=job,
        now=now,
    )


def test_is_due_supports_naive_sqlite_datetime(
    scheduler: BackgroundJobScheduler,
) -> None:
    """Interpret a timezone-naive persisted next run date as UTC."""

    now = datetime.now(UTC)

    job = BackgroundJob(
        key="test_job",
        name="Test job",
        schedule="Every 8h",
        status=BackgroundJobStatus.SUCCESS,
        next_run_at=(now - timedelta(minutes=1)).replace(tzinfo=None),
    )

    assert scheduler._is_due(
        job=job,
        now=now,
    )


def test_running_job_is_not_stale_when_recent(
    scheduler: BackgroundJobScheduler,
) -> None:
    """Keep a recently started running job active."""

    now = datetime.now(UTC)

    job = BackgroundJob(
        key="test_job",
        name="Test job",
        schedule="Every 8h",
        status=BackgroundJobStatus.RUNNING,
        last_started_at=now - timedelta(minutes=30),
    )

    assert not scheduler._is_stale_running_job(
        job=job,
        now=now,
    )


def test_running_job_is_stale_after_timeout(
    scheduler: BackgroundJobScheduler,
) -> None:
    """Treat a long-running job as stale after the configured timeout."""

    now = datetime.now(UTC)

    job = BackgroundJob(
        key="test_job",
        name="Test job",
        schedule="Every 8h",
        status=BackgroundJobStatus.RUNNING,
        last_started_at=now
        - timedelta(
            hours=3,
        ),
    )

    assert scheduler._is_stale_running_job(
        job=job,
        now=now,
    )


def test_running_job_without_start_date_is_stale(
    scheduler: BackgroundJobScheduler,
) -> None:
    """Treat a running job without a start date as stale."""

    now = datetime.now(UTC)

    job = BackgroundJob(
        key="test_job",
        name="Test job",
        schedule="Every 8h",
        status=BackgroundJobStatus.RUNNING,
        last_started_at=None,
    )

    assert scheduler._is_stale_running_job(
        job=job,
        now=now,
    )


@pytest.fixture
def scheduler_with_db(
    db_session: Session,
) -> BackgroundJobScheduler:
    """Provide a scheduler using the test database session."""

    @contextmanager
    def session_factory() -> Iterator[Session]:
        yield db_session

    return BackgroundJobScheduler(
        session_factory=session_factory,
    )


def test_run_if_due_does_not_execute_future_job(
    db_session: Session,
    scheduler_with_db: BackgroundJobScheduler,
    repository: BackgroundJobRepository,
) -> None:
    """Do not execute a job that is not due yet."""

    handler = Mock(
        return_value=None,
    )

    definition = create_definition(
        handler=handler,
    )

    now = datetime.now(UTC)

    repository.add(
        BackgroundJob(
            key=definition.key,
            name=definition.name,
            schedule=definition.schedule_label,
            status=BackgroundJobStatus.SUCCESS,
            next_run_at=now + timedelta(hours=1),
        )
    )
    repository.commit()

    scheduler_with_db._run_if_due(
        definition=definition,
        now=now,
    )

    handler.assert_not_called()


def test_run_if_due_executes_due_job(
    scheduler_with_db: BackgroundJobScheduler,
    repository: BackgroundJobRepository,
) -> None:
    """Execute a background job when its next run is due."""

    handler = Mock(
        return_value=None,
    )

    definition = create_definition(
        handler=handler,
    )

    now = datetime.now(UTC)

    repository.add(
        BackgroundJob(
            key=definition.key,
            name=definition.name,
            schedule=definition.schedule_label,
            status=BackgroundJobStatus.SUCCESS,
            next_run_at=now - timedelta(minutes=1),
        )
    )
    repository.commit()

    scheduler_with_db._run_if_due(
        definition=definition,
        now=now,
    )

    handler.assert_called_once_with()

    job = repository.get_by_key(
        definition.key,
    )

    assert job is not None
    assert job.status == BackgroundJobStatus.SUCCESS
    assert job.next_run_at is not None


def test_run_if_due_skips_running_job(
    scheduler_with_db: BackgroundJobScheduler,
    repository: BackgroundJobRepository,
) -> None:
    """Do not execute a job that is already running."""

    handler = Mock(
        return_value=None,
    )

    definition = create_definition(
        handler=handler,
    )

    now = datetime.now(UTC)

    repository.add(
        BackgroundJob(
            key=definition.key,
            name=definition.name,
            schedule=definition.schedule_label,
            status=BackgroundJobStatus.RUNNING,
            last_started_at=now - timedelta(minutes=10),
            next_run_at=now - timedelta(minutes=1),
        )
    )
    repository.commit()

    scheduler_with_db._run_if_due(
        definition=definition,
        now=now,
    )

    handler.assert_not_called()


def test_run_if_due_retries_stale_running_job(
    scheduler_with_db: BackgroundJobScheduler,
    repository: BackgroundJobRepository,
) -> None:
    """Retry a running job that appears to have been abandoned."""

    handler = Mock(
        return_value=None,
    )

    definition = create_definition(
        handler=handler,
    )

    now = datetime.now(UTC)

    repository.add(
        BackgroundJob(
            key=definition.key,
            name=definition.name,
            schedule=definition.schedule_label,
            status=BackgroundJobStatus.RUNNING,
            last_started_at=now - timedelta(hours=3),
            next_run_at=now - timedelta(hours=2),
        )
    )
    repository.commit()

    scheduler_with_db._run_if_due(
        definition=definition,
        now=now,
    )

    handler.assert_called_once_with()

    job = repository.get_by_key(
        definition.key,
    )

    assert job is not None
    assert job.status == BackgroundJobStatus.SUCCESS


def test_run_if_due_creates_and_executes_missing_job(
    scheduler_with_db: BackgroundJobScheduler,
    repository: BackgroundJobRepository,
) -> None:
    """Create and immediately execute a registered job missing from the database."""

    handler = Mock(
        return_value=None,
    )

    definition = create_definition(
        handler=handler,
    )

    assert (
        repository.get_by_key(
            definition.key,
        )
        is None
    )

    scheduler_with_db._run_if_due(
        definition=definition,
        now=datetime.now(UTC),
    )

    handler.assert_called_once_with()

    job = repository.get_by_key(
        definition.key,
    )

    assert job is not None
    assert job.status == BackgroundJobStatus.SUCCESS
    assert job.next_run_at is not None
