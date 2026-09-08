from datetime import UTC, datetime, timedelta

from sqlalchemy.orm import Session

from app.models.data_import_run import DataImportRun
from app.models.enums import DataImportPhase, DataImportRunStatus
from app.models.user import User
from app.repositories.data_import_run import DataImportRunRepository


def _create_user(
    db_session: Session,
    *,
    username: str,
) -> User:
    user = User(
        username=username,
        display_name=username,
    )

    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)

    return user


def test_add_and_get_for_user(
    db_session: Session,
) -> None:
    """Persist and retrieve an import execution owned by the user."""

    user = _create_user(
        db_session,
        username="import-user",
    )

    repository = DataImportRunRepository(
        db_session,
    )

    run = DataImportRun(
        user_id=user.id,
        status=DataImportRunStatus.QUEUED,
        phase=DataImportPhase.QUEUED,
        payload={
            "format": "sofawatch",
            "version": 1,
        },
    )

    repository.add(run)
    repository.commit()
    repository.refresh(run)

    result = repository.get_for_user(
        run_id=run.id,
        user_id=user.id,
    )

    assert result is not None
    assert result.id == run.id
    assert result.user_id == user.id
    assert result.status == DataImportRunStatus.QUEUED
    assert result.phase == DataImportPhase.QUEUED
    assert result.progress_current == 0
    assert result.progress_total == 0
    assert result.payload == {
        "format": "sofawatch",
        "version": 1,
    }


def test_get_for_user_does_not_return_another_users_import(
    db_session: Session,
) -> None:
    """Do not expose an import execution belonging to another user."""

    owner = _create_user(
        db_session,
        username="owner",
    )
    other_user = _create_user(
        db_session,
        username="other-user",
    )

    repository = DataImportRunRepository(
        db_session,
    )

    run = DataImportRun(
        user_id=owner.id,
    )

    repository.add(run)
    repository.commit()
    repository.refresh(run)

    result = repository.get_for_user(
        run_id=run.id,
        user_id=other_user.id,
    )

    assert result is None


def test_get_active_for_user_returns_queued_import(
    db_session: Session,
) -> None:
    """Return a queued import as active."""

    user = _create_user(
        db_session,
        username="queued-user",
    )

    repository = DataImportRunRepository(
        db_session,
    )

    run = DataImportRun(
        user_id=user.id,
        status=DataImportRunStatus.QUEUED,
    )

    repository.add(run)
    repository.commit()
    repository.refresh(run)

    result = repository.get_active_for_user(
        user_id=user.id,
    )

    assert result is not None
    assert result.id == run.id


def test_get_active_for_user_returns_running_import(
    db_session: Session,
) -> None:
    """Return a running import as active."""

    user = _create_user(
        db_session,
        username="running-user",
    )

    repository = DataImportRunRepository(
        db_session,
    )

    run = DataImportRun(
        user_id=user.id,
        status=DataImportRunStatus.RUNNING,
        phase=DataImportPhase.HISTORY_EPISODES,
        progress_current=100,
        progress_total=500,
    )

    repository.add(run)
    repository.commit()
    repository.refresh(run)

    result = repository.get_active_for_user(
        user_id=user.id,
    )

    assert result is not None
    assert result.id == run.id
    assert result.progress_current == 100
    assert result.progress_total == 500


def test_get_active_for_user_ignores_terminal_imports(
    db_session: Session,
) -> None:
    """Completed and failed imports are not considered active."""

    user = _create_user(
        db_session,
        username="terminal-user",
    )

    repository = DataImportRunRepository(
        db_session,
    )

    repository.add(
        DataImportRun(
            user_id=user.id,
            status=DataImportRunStatus.COMPLETED,
        )
    )
    repository.add(
        DataImportRun(
            user_id=user.id,
            status=DataImportRunStatus.FAILED,
        )
    )

    repository.commit()

    result = repository.get_active_for_user(
        user_id=user.id,
    )

    assert result is None


def test_get_active_for_user_does_not_return_another_users_import(
    db_session: Session,
) -> None:
    """Only consider active imports belonging to the requested user."""

    owner = _create_user(
        db_session,
        username="active-owner",
    )
    other_user = _create_user(
        db_session,
        username="active-other",
    )

    repository = DataImportRunRepository(
        db_session,
    )

    repository.add(
        DataImportRun(
            user_id=owner.id,
            status=DataImportRunStatus.RUNNING,
        )
    )
    repository.commit()

    result = repository.get_active_for_user(
        user_id=other_user.id,
    )

    assert result is None


def test_import_run_persists_progress_result_and_failure_metadata(
    db_session: Session,
) -> None:
    """Persist the operational state required by asynchronous execution."""

    user = _create_user(
        db_session,
        username="progress-user",
    )

    repository = DataImportRunRepository(
        db_session,
    )

    started_at = datetime.now(UTC)

    run = DataImportRun(
        user_id=user.id,
        status=DataImportRunStatus.RUNNING,
        phase=DataImportPhase.LIBRARY_SHOWS,
        progress_current=12,
        progress_total=30,
        started_at=started_at,
        heartbeat_at=started_at + timedelta(seconds=5),
        result={
            "partial": True,
        },
        error_code="example_failure",
        error_message="Safe failure message.",
    )

    repository.add(run)
    repository.commit()
    repository.refresh(run)

    result = repository.get_for_user(
        run_id=run.id,
        user_id=user.id,
    )

    assert result is not None
    assert result.phase == DataImportPhase.LIBRARY_SHOWS
    assert result.progress_current == 12
    assert result.progress_total == 30
    assert result.started_at == started_at.replace(tzinfo=None)
    assert result.heartbeat_at == (
        started_at + timedelta(seconds=5)
    ).replace(tzinfo=None)
    assert result.result == {
        "partial": True,
    }
    assert result.error_code == "example_failure"
    assert result.error_message == "Safe failure message."


def test_import_payload_can_be_removed_after_processing(
    db_session: Session,
) -> None:
    """Allow temporary personal import payloads to be cleaned up."""

    user = _create_user(
        db_session,
        username="cleanup-user",
    )

    repository = DataImportRunRepository(
        db_session,
    )

    run = DataImportRun(
        user_id=user.id,
        payload={
            "format": "sofawatch",
            "version": 1,
        },
    )

    repository.add(run)
    repository.commit()
    repository.refresh(run)

    run.payload = None

    repository.commit()
    repository.refresh(run)

    assert run.payload is None


def test_deleting_user_cascades_data_import_runs(
    db_session: Session,
) -> None:
    """Delete persisted import state when its owning user is deleted."""

    user = _create_user(
        db_session,
        username="deleted-user",
    )

    repository = DataImportRunRepository(
        db_session,
    )

    run = DataImportRun(
        user_id=user.id,
    )

    repository.add(run)
    repository.commit()
    repository.refresh(run)

    run_id = run.id
    user_id = user.id

    db_session.delete(user)
    db_session.commit()

    result = repository.get_for_user(
        run_id=run_id,
        user_id=user_id,
    )

    assert result is None


def test_claim_next_queued_claims_oldest_import(
    db_session: Session,
) -> None:
    first_user = _create_user(
        db_session,
        username="claim-first",
    )
    second_user = _create_user(
        db_session,
        username="claim-second",
    )

    repository = DataImportRunRepository(
        db_session,
    )

    first = DataImportRun(
        user_id=first_user.id,
        created_at=datetime(
            2026,
            9,
            8,
            3,
            0,
            tzinfo=UTC,
        ),
    )
    second = DataImportRun(
        user_id=second_user.id,
        created_at=datetime(
            2026,
            9,
            8,
            3,
            1,
            tzinfo=UTC,
        ),
    )

    repository.add(first)
    repository.commit()
    repository.refresh(first)

    repository.add(second)
    repository.commit()
    repository.refresh(second)

    claimed_at = datetime.now(UTC)

    claimed = repository.claim_next_queued(
        now=claimed_at,
    )

    assert claimed is not None
    assert claimed.id == first.id
    assert claimed.status == DataImportRunStatus.RUNNING
    assert claimed.started_at is not None
    assert claimed.heartbeat_at is not None
    assert claimed.started_at.replace(tzinfo=None) == claimed_at.replace(
        tzinfo=None,
    )
    assert claimed.heartbeat_at.replace(tzinfo=None) == claimed_at.replace(
        tzinfo=None,
    )


def test_claim_next_queued_does_not_claim_same_import_twice(
    db_session: Session,
) -> None:
    user = _create_user(
        db_session,
        username="claim-once",
    )

    repository = DataImportRunRepository(
        db_session,
    )

    repository.add(
        DataImportRun(
            user_id=user.id,
        )
    )
    repository.commit()

    first = repository.claim_next_queued(
        now=datetime.now(UTC),
    )

    second = repository.claim_next_queued(
        now=datetime.now(UTC),
    )

    assert first is not None
    assert second is None


def test_claim_next_queued_ignores_terminal_imports(
    db_session: Session,
) -> None:
    first_user = _create_user(
        db_session,
        username="claim-completed",
    )
    second_user = _create_user(
        db_session,
        username="claim-failed",
    )

    repository = DataImportRunRepository(
        db_session,
    )

    repository.add(
        DataImportRun(
            user_id=first_user.id,
            status=DataImportRunStatus.COMPLETED,
        )
    )
    repository.add(
        DataImportRun(
            user_id=second_user.id,
            status=DataImportRunStatus.FAILED,
        )
    )
    repository.commit()

    assert (
        repository.claim_next_queued(
            now=datetime.now(UTC),
        )
        is None
    )


def test_mark_completed_persists_result_and_cleans_payload(
    db_session: Session,
) -> None:
    user = _create_user(
        db_session,
        username="complete-run",
    )

    repository = DataImportRunRepository(
        db_session,
    )

    run = DataImportRun(
        user_id=user.id,
        status=DataImportRunStatus.RUNNING,
        payload={
            "private": "import-data",
        },
    )

    repository.add(run)
    repository.commit()
    repository.refresh(run)

    finished_at = datetime.now(UTC)

    repository.mark_completed(
        run=run,
        result={
            "library": {
                "shows": {
                    "created": 1,
                },
            },
        },
        finished_at=finished_at,
    )

    repository.refresh(run)

    assert run.status == DataImportRunStatus.COMPLETED
    assert run.phase == DataImportPhase.FINALIZING
    assert run.payload is None
    assert run.result == {
        "library": {
            "shows": {
                "created": 1,
            },
        },
    }
    assert run.error_code is None
    assert run.error_message is None
    assert run.finished_at == finished_at.replace(tzinfo=None)


def test_mark_failed_persists_safe_error_and_cleans_payload(
    db_session: Session,
) -> None:
    user = _create_user(
        db_session,
        username="fail-run",
    )

    repository = DataImportRunRepository(
        db_session,
    )

    run = DataImportRun(
        user_id=user.id,
        status=DataImportRunStatus.RUNNING,
        payload={
            "private": "import-data",
        },
    )

    repository.add(run)
    repository.commit()
    repository.refresh(run)

    finished_at = datetime.now(UTC)

    repository.mark_failed(
        run=run,
        error_code="data_import_failed",
        error_message="The data import could not be completed.",
        finished_at=finished_at,
    )

    repository.refresh(run)

    assert run.status == DataImportRunStatus.FAILED
    assert run.payload is None
    assert run.error_code == "data_import_failed"
    assert (
        run.error_message
        == "The data import could not be completed."
    )
    assert run.finished_at == finished_at.replace(tzinfo=None)

def test_update_progress_persists_phase_counts_and_heartbeat(
    db_session: Session,
) -> None:
    user = _create_user(
        db_session,
        username="progress-update",
    )

    repository = DataImportRunRepository(
        db_session,
    )

    run = DataImportRun(
        user_id=user.id,
        status=DataImportRunStatus.RUNNING,
    )

    repository.add(run)
    repository.commit()
    repository.refresh(run)

    heartbeat_at = datetime.now(UTC)

    repository.update_progress(
        run=run,
        phase=DataImportPhase.HISTORY_EPISODES,
        current=142,
        total=5503,
        heartbeat_at=heartbeat_at,
    )

    db_session.expire_all()

    stored = repository.get_by_id(
        run_id=run.id,
    )

    assert stored is not None
    assert stored.phase == DataImportPhase.HISTORY_EPISODES
    assert stored.progress_current == 142
    assert stored.progress_total == 5503
    assert stored.heartbeat_at is not None
    assert stored.heartbeat_at.replace(
        tzinfo=None,
    ) == heartbeat_at.replace(
        tzinfo=None,
    )


def test_fail_stale_running_marks_interrupted_and_cleans_payload(
    db_session: Session,
) -> None:
    user = _create_user(
        db_session,
        username="stale-import",
    )

    repository = DataImportRunRepository(
        db_session,
    )

    heartbeat_at = datetime(
        2026,
        9,
        8,
        3,
        0,
        tzinfo=UTC,
    )

    run = DataImportRun(
        user_id=user.id,
        status=DataImportRunStatus.RUNNING,
        started_at=heartbeat_at,
        heartbeat_at=heartbeat_at,
        payload={
            "private": "data",
        },
    )

    repository.add(run)
    repository.commit()
    repository.refresh(run)

    finished_at = datetime(
        2026,
        9,
        8,
        4,
        0,
        tzinfo=UTC,
    )

    count = repository.fail_stale_running(
        stale_before=datetime(
            2026,
            9,
            8,
            3,
            30,
            tzinfo=UTC,
        ),
        finished_at=finished_at,
    )

    assert count == 1

    db_session.expire_all()

    stored = repository.get_by_id(
        run_id=run.id,
    )

    assert stored is not None
    assert stored.status == DataImportRunStatus.FAILED
    assert stored.payload is None
    assert stored.error_code == "data_import_interrupted"
    assert stored.error_message == (
        "The data import was interrupted before it could complete."
    )
    assert stored.finished_at is not None


def test_fail_stale_running_does_not_fail_recent_heartbeat(
    db_session: Session,
) -> None:
    user = _create_user(
        db_session,
        username="healthy-import",
    )

    repository = DataImportRunRepository(
        db_session,
    )

    run = DataImportRun(
        user_id=user.id,
        status=DataImportRunStatus.RUNNING,
        heartbeat_at=datetime(
            2026,
            9,
            8,
            3,
            55,
            tzinfo=UTC,
        ),
    )

    repository.add(run)
    repository.commit()

    count = repository.fail_stale_running(
        stale_before=datetime(
            2026,
            9,
            8,
            3,
            30,
            tzinfo=UTC,
        ),
        finished_at=datetime(
            2026,
            9,
            8,
            4,
            0,
            tzinfo=UTC,
        ),
    )

    assert count == 0

    db_session.expire_all()

    stored = repository.get_by_id(
        run_id=run.id,
    )

    assert stored is not None
    assert stored.status == DataImportRunStatus.RUNNING

