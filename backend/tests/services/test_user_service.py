from types import SimpleNamespace
from unittest.mock import Mock
from uuid import UUID, uuid4

import pytest

from app.repositories.user import UserRepository
from app.services.user import UserService
from app.models.user import User


@pytest.fixture
def user_repository() -> Mock:
    """Provide a mocked user repository."""

    return Mock(spec=UserRepository)


@pytest.fixture
def user_service(
    user_repository: Mock,
) -> UserService:
    """Provide a user service using a mocked repository."""

    return UserService(
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


def test_get_local_returns_local_user(
    user_service: UserService,
    user_repository: Mock,
) -> None:
    """Return the local SofaWatch user."""

    user = make_user(
        user_id=uuid4(),
    )

    user_repository.get_local.return_value = user

    result = user_service.get_local()

    assert result is user
    assert result.is_local is True

    user_repository.get_local.assert_called_once_with()


def test_get_local_returns_none_when_missing(
    user_service: UserService,
    user_repository: Mock,
) -> None:
    """Return None when no local user exists."""

    user_repository.get_local.return_value = None

    result = user_service.get_local()

    assert result is None

    user_repository.get_local.assert_called_once_with()

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