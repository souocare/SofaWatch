from types import SimpleNamespace
from unittest.mock import Mock
from uuid import UUID, uuid4

import pytest

from app.repositories.user import UserRepository
from app.services.user import UserService
from app.models.user import User
from unittest.mock import Mock

import pytest
from sqlalchemy.orm import Session
from app.core.security.passwords import hash_password, verify_password
from app.services.user import (
    CurrentPasswordInvalidError,
    PasswordUnavailableError,
    UserService,
)


@pytest.fixture
def user_repository() -> Mock:
    """Provide a mocked user repository."""

    return Mock(spec=UserRepository)


@pytest.fixture
def db_session() -> Mock:
    """Provide a mocked database session."""

    return Mock(spec=Session)


@pytest.fixture
def user_service(
    db_session: Mock,
    user_repository: Mock,
) -> UserService:
    """Provide a user service using mocked dependencies."""

    return UserService(
        session=db_session,
        user_repository=user_repository,
    )


def make_user(
    *,
    user_id: UUID,
    display_name: str = "Local User",
    is_local: bool = True,
) -> SimpleNamespace:
    """Create a lightweight user object for service tests."""

    return SimpleNamespace(
        id=user_id,
        display_name=display_name,
        is_local=is_local,
    )


def test_get_by_id_returns_user(
    user_service: UserService,
    user_repository: Mock,
) -> None:
    """Return a user by its internal identifier."""

    user_id = uuid4()

    user = make_user(
        user_id=user_id,
    )

    user_repository.get_by_id.return_value = user

    result = user_service.get_by_id(user_id)

    assert result is user

    user_repository.get_by_id.assert_called_once_with(
        user_id,
    )


def test_get_by_id_returns_none_when_missing(
    user_service: UserService,
    user_repository: Mock,
) -> None:
    """Return None when the requested user does not exist."""

    user_id = uuid4()

    user_repository.get_by_id.return_value = None

    result = user_service.get_by_id(user_id)

    assert result is None

    user_repository.get_by_id.assert_called_once_with(
        user_id,
    )




def test_get_by_username_normalizes_username(
    user_service,
    user_repository,
) -> None:
    user = User(
        username="souocare",
        display_name="Gonçalo",
        is_local=False,
    )

    user_repository.get_by_username.return_value = user

    result = user_service.get_by_username("  SouOCare  ")

    assert result is user

    user_repository.get_by_username.assert_called_once_with(
        "souocare",
    )


def test_get_by_username_rejects_empty_username(
    user_service,
    user_repository,
) -> None:
    result = user_service.get_by_username("   ")

    assert result is None

    user_repository.get_by_username.assert_not_called()


def test_get_by_email_normalizes_email(
    user_service,
    user_repository,
) -> None:
    user = User(
        email="goncalo@example.com",
        display_name="Gonçalo",
        is_local=False,
    )

    user_repository.get_by_email.return_value = user

    result = user_service.get_by_email("  Goncalo@Example.COM  ")

    assert result is user

    user_repository.get_by_email.assert_called_once_with(
        "goncalo@example.com",
    )


def test_get_by_email_rejects_empty_email(
    user_service,
    user_repository,
) -> None:
    result = user_service.get_by_email("   ")

    assert result is None

    user_repository.get_by_email.assert_not_called()

def test_requires_initial_setup_when_no_user_exists(
    user_service: UserService,
    user_repository: Mock,
) -> None:
    user_repository.exists_any.return_value = False

    result = user_service.requires_initial_setup()

    assert result is True

    user_repository.exists_any.assert_called_once_with()


def test_does_not_require_initial_setup_when_user_exists(
    user_service: UserService,
    user_repository: Mock,
) -> None:
    user_repository.exists_any.return_value = True

    result = user_service.requires_initial_setup()

    assert result is False

    user_repository.exists_any.assert_called_once_with()


def test_requires_initial_setup_when_no_user_exists(
    user_service: UserService,
    user_repository: Mock,
) -> None:
    user_repository.exists_any.return_value = False

    result = user_service.requires_initial_setup()

    assert result is True

    user_repository.exists_any.assert_called_once_with()


def test_does_not_require_initial_setup_when_user_exists(
    user_service: UserService,
    user_repository: Mock,
) -> None:
    user_repository.exists_any.return_value = True

    result = user_service.requires_initial_setup()

    assert result is False

    user_repository.exists_any.assert_called_once_with()


def test_update_display_name_updates_and_persists_user(
    user_service: UserService,
    db_session: Mock,
) -> None:
    """Update and persist a normalized display name."""

    user = User(
        display_name="Old Name",
        is_local=False,
    )

    db_session.refresh.side_effect = lambda _: None

    result = user_service.update_display_name(
        user=user,
        display_name="  Gonçalo Fonseca  ",
    )

    assert result is user
    assert user.display_name == "Gonçalo Fonseca"

    db_session.commit.assert_called_once_with()
    db_session.refresh.assert_called_once_with(user)

def test_update_display_name_rejects_blank_value(
    user_service: UserService,
    db_session: Mock,
) -> None:
    """Reject blank display names without persisting changes."""

    user = User(
        display_name="Existing Name",
        is_local=False,
    )

    with pytest.raises(
        ValueError,
        match="Display name must not be blank",
    ):
        user_service.update_display_name(
            user=user,
            display_name="   ",
        )

    assert user.display_name == "Existing Name"

    db_session.commit.assert_not_called()
    db_session.refresh.assert_not_called()

def test_update_password_changes_password(
    user_service: UserService,
    db_session: Session,
) -> None:
    user = User(
        username="souocare",
        display_name="Gonçalo",
        password_hash=hash_password("old-password"),
    )

    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)

    updated_user = user_service.update_password(
        user=user,
        current_password="old-password",
        new_password="new-password",
    )

    assert updated_user is user

    assert verify_password(
        "new-password",
        user.password_hash,
    )

    assert not verify_password(
        "old-password",
        user.password_hash,
    )



def test_update_password_rejects_incorrect_current_password(
    user_service: UserService,
) -> None:
    user = User(
        username="souocare",
        display_name="Gonçalo",
        password_hash=hash_password("correct-password"),
    )

    with pytest.raises(CurrentPasswordInvalidError):
        user_service.update_password(
            user=user,
            current_password="wrong-password",
            new_password="new-password",
        )

    assert verify_password(
        "correct-password",
        user.password_hash,
    )


def test_update_password_rejects_account_without_password(
    user_service: UserService,
) -> None:
    user = User(
        display_name="Local User",
        password_hash=None,
    )

    with pytest.raises(PasswordUnavailableError):
        user_service.update_password(
            user=user,
            current_password="anything",
            new_password="new-password",
        )



