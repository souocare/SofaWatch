from unittest.mock import Mock
from datetime import UTC, datetime

from sqlalchemy.orm import Session, sessionmaker

from app.jobs.data_import_processor import DataImportProcessor
from app.models.data_import_run import DataImportRun
from app.models.enums import DataImportRunStatus
from app.models.user import User
from app.schemas.data_import import (
    DataImportHistoryMediaSummaryResponse,
    DataImportHistoryResultResponse,
    DataImportLibraryResultResponse,
    DataImportMediaSummaryResponse,
    DataImportResultResponse,
)


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


def _export_payload() -> dict[str, object]:
    return {
        "format": "sofawatch-export",
        "version": 1,
        "exported_at": "2026-09-08T04:00:00Z",
        "user": {
            "display_name": "Import User",
        },
        "library": {
            "shows": [],
            "movies": [],
        },
        "history": {
            "episodes": [],
            "movies": [],
        },
    }


def _result() -> DataImportResultResponse:
    return DataImportResultResponse(
        library=DataImportLibraryResultResponse(
            shows=DataImportMediaSummaryResponse(
                created=0,
                updated=0,
                unchanged=0,
                failed=0,
            ),
            movies=DataImportMediaSummaryResponse(
                created=0,
                updated=0,
                unchanged=0,
                failed=0,
            ),
        ),
        history=DataImportHistoryResultResponse(
            episodes=DataImportHistoryMediaSummaryResponse(
                created=0,
                skipped=0,
                failed=0,
            ),
            movies=DataImportHistoryMediaSummaryResponse(
                created=0,
                skipped=0,
                failed=0,
            ),
        ),
    )


def test_run_once_returns_false_without_queued_import(
    db_session_factory: sessionmaker[Session],
) -> None:
    service_factory = Mock()

    processor = DataImportProcessor(
        session_factory=db_session_factory,
        service_factory=service_factory,
    )

    assert processor.run_once() is False
    service_factory.assert_not_called()


def test_run_once_executes_and_completes_queued_import(
    db_session: Session,
    db_session_factory: sessionmaker[Session],
) -> None:
    user = _create_user(
        db_session,
        username="processor-success",
    )

    run = DataImportRun(
        user_id=user.id,
        payload=_export_payload(),
    )

    db_session.add(run)
    db_session.commit()
    db_session.refresh(run)

    import_service = Mock()
    import_service.import_user_data.return_value = _result()

    service_factory = Mock(
        return_value=import_service,
    )

    processor = DataImportProcessor(
        session_factory=db_session_factory,
        service_factory=service_factory,
    )

    assert processor.run_once() is True

    db_session.expire_all()

    stored = db_session.get(
        DataImportRun,
        run.id,
    )

    assert stored is not None
    assert stored.status == DataImportRunStatus.COMPLETED
    assert stored.payload is None
    assert stored.result is not None
    assert stored.error_code is None
    assert stored.finished_at is not None

    import_service.import_user_data.assert_called_once()

    call_kwargs = import_service.import_user_data.call_args.kwargs

    assert call_kwargs["user_id"] == user.id
    assert call_kwargs["progress_callback"] is not None


def test_run_once_marks_import_failed_when_execution_raises(
    db_session: Session,
    db_session_factory: sessionmaker[Session],
) -> None:
    user = _create_user(
        db_session,
        username="processor-failure",
    )

    run = DataImportRun(
        user_id=user.id,
        payload=_export_payload(),
    )

    db_session.add(run)
    db_session.commit()
    db_session.refresh(run)

    import_service = Mock()
    import_service.import_user_data.side_effect = RuntimeError(
        "technical detail that must not reach the user"
    )

    processor = DataImportProcessor(
        session_factory=db_session_factory,
        service_factory=Mock(
            return_value=import_service,
        ),
    )

    assert processor.run_once() is True

    db_session.expire_all()

    stored = db_session.get(
        DataImportRun,
        run.id,
    )

    assert stored is not None
    assert stored.status == DataImportRunStatus.FAILED
    assert stored.payload is None
    assert stored.result is None
    assert stored.error_code == "data_import_failed"
    assert stored.error_message == "The data import could not be completed."
    assert stored.finished_at is not None


def test_run_once_marks_import_failed_for_invalid_persisted_payload(
    db_session: Session,
    db_session_factory: sessionmaker[Session],
) -> None:
    user = _create_user(
        db_session,
        username="processor-invalid",
    )

    run = DataImportRun(
        user_id=user.id,
        payload={
            "invalid": True,
        },
    )

    db_session.add(run)
    db_session.commit()
    db_session.refresh(run)

    service_factory = Mock()

    processor = DataImportProcessor(
        session_factory=db_session_factory,
        service_factory=service_factory,
    )

    assert processor.run_once() is True

    db_session.expire_all()

    stored = db_session.get(
        DataImportRun,
        run.id,
    )

    assert stored is not None
    assert stored.status == DataImportRunStatus.FAILED
    assert stored.payload is None
    assert stored.error_code == "data_import_failed"

    service_factory.assert_not_called()


def test_run_once_marks_stale_running_import_failed_before_claiming(
    db_session: Session,
    db_session_factory: sessionmaker[Session],
) -> None:
    user = _create_user(
        db_session,
        username="processor-stale",
    )

    run = DataImportRun(
        user_id=user.id,
        status=DataImportRunStatus.RUNNING,
        heartbeat_at=datetime(
            2020,
            1,
            1,
            tzinfo=UTC,
        ),
        payload=_export_payload(),
    )

    db_session.add(run)
    db_session.commit()
    db_session.refresh(run)

    service_factory = Mock()

    processor = DataImportProcessor(
        session_factory=db_session_factory,
        service_factory=service_factory,
    )

    assert processor.run_once() is False

    db_session.expire_all()

    stored = db_session.get(
        DataImportRun,
        run.id,
    )

    assert stored is not None
    assert stored.status == DataImportRunStatus.FAILED
    assert stored.error_code == "data_import_interrupted"
    assert stored.payload is None

    service_factory.assert_not_called()
