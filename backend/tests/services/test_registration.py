import pytest
from sqlalchemy.orm import Session

from app.models.authentication_settings import AuthenticationSettings
from app.models.user import User
from app.repositories.authentication_settings import (
    AuthenticationSettingsRepository,
)
from app.repositories.user import UserRepository
from app.services.authentication_settings import AuthenticationSettingsService
from app.services.registration import (
    EmailAlreadyExistsError,
    RegistrationClosedError,
    RegistrationService,
    UsernameAlreadyExistsError,
)


def _create_service(
    db_session: Session,
) -> RegistrationService:
    authentication_settings_service = AuthenticationSettingsService(
        session=db_session,
        repository=AuthenticationSettingsRepository(db_session),
    )

    return RegistrationService(
        session=db_session,
        user_repository=UserRepository(db_session),
        authentication_settings_service=authentication_settings_service,
    )


def test_registration_is_closed_by_default(
    db_session: Session,
) -> None:
    service = _create_service(db_session)

    with pytest.raises(RegistrationClosedError):
        service.register(
            username="new-user",
            display_name="New User",
            password="correct-password",
        )

    assert db_session.query(User).count() == 0


def test_registers_regular_user_when_registration_is_open(
    db_session: Session,
) -> None:
    db_session.add(
        AuthenticationSettings(
            open_registration=True,
        )
    )
    db_session.commit()

    service = _create_service(db_session)

    user = service.register(
        username="New.User",
        display_name="  New User  ",
        password="correct-password",
        email=" NEW@EXAMPLE.COM ",
    )

    assert user.username == "new.user"
    assert user.display_name == "New User"
    assert user.email == "new@example.com"

    assert user.is_active is True
    assert user.is_admin is False

    assert user.password_hash is not None
    assert user.password_hash != "correct-password"


def test_rejects_duplicate_username(
    db_session: Session,
) -> None:
    db_session.add(
        AuthenticationSettings(
            open_registration=True,
        )
    )

    db_session.add(
        User(
            username="existing",
            display_name="Existing User",
            is_active=True,
            is_admin=False,
        )
    )

    db_session.commit()

    service = _create_service(db_session)

    with pytest.raises(UsernameAlreadyExistsError):
        service.register(
            username="Existing",
            display_name="Another User",
            password="correct-password",
        )


def test_rejects_duplicate_email(
    db_session: Session,
) -> None:
    db_session.add(
        AuthenticationSettings(
            open_registration=True,
        )
    )

    db_session.add(
        User(
            username="existing",
            email="existing@example.com",
            display_name="Existing User",
            is_active=True,
            is_admin=False,
        )
    )

    db_session.commit()

    service = _create_service(db_session)

    with pytest.raises(EmailAlreadyExistsError):
        service.register(
            username="another-user",
            display_name="Another User",
            password="correct-password",
            email=" EXISTING@EXAMPLE.COM ",
        )