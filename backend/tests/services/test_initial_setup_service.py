import pytest
from sqlalchemy.orm import Session

from app.core.security.passwords import verify_password
from app.models.user import User
from app.repositories.user import UserRepository
from app.services.initial_setup import (
    InitialSetupAlreadyCompletedError,
    InitialSetupService,
)


def test_creates_first_user_as_administrator(
    db_session: Session,
) -> None:
    repository = UserRepository(db_session)

    service = InitialSetupService(
        session=db_session,
        user_repository=repository,
    )

    user = service.create_first_admin(
        username="  SouOCare  ",
        display_name="  Gonçalo  ",
        password="correct-password",
    )

    assert user.username == "souocare"
    assert user.display_name == "Gonçalo"
    assert user.email is None

    assert user.is_active is True
    assert user.is_admin is True

    assert user.password_hash is not None
    assert verify_password(
        "correct-password",
        user.password_hash,
    )


def test_normalizes_optional_email(
    db_session: Session,
) -> None:
    repository = UserRepository(db_session)

    service = InitialSetupService(
        session=db_session,
        user_repository=repository,
    )

    user = service.create_first_admin(
        username="souocare",
        display_name="Gonçalo",
        password="correct-password",
        email="  Goncalo@Example.COM  ",
    )

    assert user.email == "goncalo@example.com"


def test_rejects_setup_when_user_already_exists(
    db_session: Session,
) -> None:
    existing_user = User(
        username="existing",
        display_name="Existing User",
    )

    db_session.add(existing_user)
    db_session.commit()

    service = InitialSetupService(
        session=db_session,
        user_repository=UserRepository(db_session),
    )

    with pytest.raises(InitialSetupAlreadyCompletedError):
        service.create_first_admin(
            username="souocare",
            display_name="Gonçalo",
            password="correct-password",
        )

    users = db_session.query(User).all()

    assert len(users) == 1
    assert users[0].username == "existing"
