from datetime import UTC, datetime

import pytest
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.models.data_import_run import DataImportRun
from app.models.enums import DataImportRunStatus
from app.models.user import User
from app.repositories.data_import_run import DataImportRunRepository
from app.schemas.data_export import (
    ExportLibraryResponse,
    ExportUserResponse,
    ExportWatchHistoryResponse,
    SofaWatchExportResponse,
)
from app.services.data_import_run import (
    ActiveDataImportExistsError,
    DataImportRunNotFoundError,
    DataImportRunService,
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


def _create_export() -> SofaWatchExportResponse:
    return SofaWatchExportResponse(
        exported_at=datetime(
            2026,
            9,
            8,
            4,
            0,
            tzinfo=UTC,
        ),
        user=ExportUserResponse(
            display_name="Import User",
        ),
        library=ExportLibraryResponse(
            shows=[],
            movies=[],
        ),
        history=ExportWatchHistoryResponse(
            episodes=[],
            movies=[],
        ),
    )


def test_submit_creates_queued_import_with_json_payload(
    db_session: Session,
) -> None:
    user = _create_user(
        db_session,
        username="submit-user",
    )

    service = DataImportRunService(
        repository=DataImportRunRepository(
            db_session,
        ),
    )

    run = service.submit(
        user_id=user.id,
        export=_create_export(),
    )

    assert run.id is not None
    assert run.user_id == user.id
    assert run.status == DataImportRunStatus.QUEUED
    assert run.payload is not None
    assert run.payload["format"] == "sofawatch-export"
    assert run.payload["version"] == 1
    assert run.payload["exported_at"] == "2026-09-08T04:00:00Z"


def test_submit_rejects_when_user_already_has_queued_import(
    db_session: Session,
) -> None:
    user = _create_user(
        db_session,
        username="queued-user",
    )

    service = DataImportRunService(
        repository=DataImportRunRepository(
            db_session,
        ),
    )

    first = service.submit(
        user_id=user.id,
        export=_create_export(),
    )

    with pytest.raises(
        ActiveDataImportExistsError,
    ) as captured:
        service.submit(
            user_id=user.id,
            export=_create_export(),
        )

    assert captured.value.run.id == first.id


def test_submit_rejects_when_user_already_has_running_import(
    db_session: Session,
) -> None:
    user = _create_user(
        db_session,
        username="running-user",
    )

    repository = DataImportRunRepository(
        db_session,
    )

    running = DataImportRun(
        user_id=user.id,
        status=DataImportRunStatus.RUNNING,
    )

    repository.add(running)
    repository.commit()

    service = DataImportRunService(
        repository=repository,
    )

    with pytest.raises(
        ActiveDataImportExistsError,
    ):
        service.submit(
            user_id=user.id,
            export=_create_export(),
        )


def test_submit_allows_new_import_after_completed_import(
    db_session: Session,
) -> None:
    user = _create_user(
        db_session,
        username="completed-user",
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
    repository.commit()

    service = DataImportRunService(
        repository=repository,
    )

    run = service.submit(
        user_id=user.id,
        export=_create_export(),
    )

    assert run.status == DataImportRunStatus.QUEUED


def test_different_users_can_have_active_imports(
    db_session: Session,
) -> None:
    first_user = _create_user(
        db_session,
        username="first-user",
    )
    second_user = _create_user(
        db_session,
        username="second-user",
    )

    service = DataImportRunService(
        repository=DataImportRunRepository(
            db_session,
        ),
    )

    first = service.submit(
        user_id=first_user.id,
        export=_create_export(),
    )

    second = service.submit(
        user_id=second_user.id,
        export=_create_export(),
    )

    assert first.user_id == first_user.id
    assert second.user_id == second_user.id


def test_get_active_returns_active_import(
    db_session: Session,
) -> None:
    user = _create_user(
        db_session,
        username="active-user",
    )

    service = DataImportRunService(
        repository=DataImportRunRepository(
            db_session,
        ),
    )

    created = service.submit(
        user_id=user.id,
        export=_create_export(),
    )

    result = service.get_active(
        user_id=user.id,
    )

    assert result is not None
    assert result.id == created.id


def test_get_active_returns_none_without_active_import(
    db_session: Session,
) -> None:
    user = _create_user(
        db_session,
        username="inactive-user",
    )

    service = DataImportRunService(
        repository=DataImportRunRepository(
            db_session,
        ),
    )

    assert (
        service.get_active(
            user_id=user.id,
        )
        is None
    )


def test_get_returns_user_owned_import(
    db_session: Session,
) -> None:
    user = _create_user(
        db_session,
        username="get-user",
    )

    service = DataImportRunService(
        repository=DataImportRunRepository(
            db_session,
        ),
    )

    created = service.submit(
        user_id=user.id,
        export=_create_export(),
    )

    result = service.get(
        run_id=created.id,
        user_id=user.id,
    )

    assert result.id == created.id


def test_get_rejects_import_owned_by_another_user(
    db_session: Session,
) -> None:
    owner = _create_user(
        db_session,
        username="owner",
    )
    other = _create_user(
        db_session,
        username="other",
    )

    service = DataImportRunService(
        repository=DataImportRunRepository(
            db_session,
        ),
    )

    created = service.submit(
        user_id=owner.id,
        export=_create_export(),
    )

    with pytest.raises(
        DataImportRunNotFoundError,
    ):
        service.get(
            run_id=created.id,
            user_id=other.id,
        )
