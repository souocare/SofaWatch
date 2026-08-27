from sqlalchemy.orm import Session

from app.models.authentication_settings import AuthenticationSettings
from app.repositories.authentication_settings import (
    AuthenticationSettingsRepository,
)
from app.services.authentication_settings import AuthenticationSettingsService


def _create_service(
    db_session: Session,
) -> AuthenticationSettingsService:
    return AuthenticationSettingsService(
        session=db_session,
        repository=AuthenticationSettingsRepository(db_session),
    )


def test_get_creates_settings_with_registration_closed_by_default(
    db_session: Session,
) -> None:
    service = _create_service(db_session)

    settings = service.get()

    assert settings.open_registration is False

    stored_settings = AuthenticationSettingsRepository(db_session).get()

    assert stored_settings is not None
    assert stored_settings.id == settings.id
    assert stored_settings.open_registration is False


def test_get_reuses_existing_settings(
    db_session: Session,
) -> None:
    existing = AuthenticationSettings(
        open_registration=True,
    )

    db_session.add(existing)
    db_session.commit()
    db_session.refresh(existing)

    service = _create_service(db_session)

    result = service.get()

    assert result.id == existing.id
    assert result.open_registration is True


def test_set_open_registration_enables_registration(
    db_session: Session,
) -> None:
    service = _create_service(db_session)

    result = service.set_open_registration(
        enabled=True,
    )

    assert result.open_registration is True

    stored_settings = AuthenticationSettingsRepository(db_session).get()

    assert stored_settings is not None
    assert stored_settings.open_registration is True


def test_set_open_registration_disables_registration(
    db_session: Session,
) -> None:
    service = _create_service(db_session)

    service.set_open_registration(
        enabled=True,
    )

    result = service.set_open_registration(
        enabled=False,
    )

    assert result.open_registration is False

    stored_settings = AuthenticationSettingsRepository(db_session).get()

    assert stored_settings is not None
    assert stored_settings.open_registration is False
