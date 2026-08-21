from unittest.mock import Mock

import pytest

from app.core.security.passwords import hash_password
from app.models.user import User
from app.repositories.user import UserRepository
from app.services.authentication import AuthenticationService


@pytest.fixture
def user_repository() -> Mock:
    """Provide a mocked user repository."""

    return Mock(spec=UserRepository)


@pytest.fixture
def authentication_service(
    user_repository: Mock,
) -> AuthenticationService:
    """Provide an authentication service using a mocked repository."""

    return AuthenticationService(
        user_repository=user_repository,
    )


def test_authenticate_returns_user_for_valid_credentials(
    authentication_service: AuthenticationService,
    user_repository: Mock,
) -> None:
    """Return the user when username and password are valid."""

    user = User(
        username="souocare",
        display_name="Gonçalo",
        password_hash=hash_password("correct-password"),
        is_active=True,
        is_local=False,
    )

    user_repository.get_by_username.return_value = user

    result = authentication_service.authenticate(
        username="souocare",
        password="correct-password",
    )

    assert result is user

    user_repository.get_by_username.assert_called_once_with(
        "souocare",
    )


def test_authenticate_normalizes_username(
    authentication_service: AuthenticationService,
    user_repository: Mock,
) -> None:
    """Normalize username before querying the repository."""

    user = User(
        username="souocare",
        display_name="Gonçalo",
        password_hash=hash_password("correct-password"),
        is_active=True,
        is_local=False,
    )

    user_repository.get_by_username.return_value = user

    result = authentication_service.authenticate(
        username="  SouOCare  ",
        password="correct-password",
    )

    assert result is user

    user_repository.get_by_username.assert_called_once_with(
        "souocare",
    )


def test_authenticate_returns_none_for_unknown_username(
    authentication_service: AuthenticationService,
    user_repository: Mock,
) -> None:
    """Reject credentials when the user does not exist."""

    user_repository.get_by_username.return_value = None

    result = authentication_service.authenticate(
        username="missing",
        password="password",
    )

    assert result is None

    user_repository.get_by_username.assert_called_once_with(
        "missing",
    )


def test_authenticate_returns_none_for_invalid_password(
    authentication_service: AuthenticationService,
    user_repository: Mock,
) -> None:
    """Reject credentials when the password does not match."""

    user = User(
        username="souocare",
        display_name="Gonçalo",
        password_hash=hash_password("correct-password"),
        is_active=True,
        is_local=False,
    )

    user_repository.get_by_username.return_value = user

    result = authentication_service.authenticate(
        username="souocare",
        password="wrong-password",
    )

    assert result is None

    user_repository.get_by_username.assert_called_once_with(
        "souocare",
    )


def test_authenticate_returns_none_for_user_without_password(
    authentication_service: AuthenticationService,
    user_repository: Mock,
) -> None:
    """Reject users that do not yet have authentication credentials."""

    user = User(
        username="souocare",
        display_name="Gonçalo",
        password_hash=None,
        is_active=True,
        is_local=True,
    )

    user_repository.get_by_username.return_value = user

    result = authentication_service.authenticate(
        username="souocare",
        password="password",
    )

    assert result is None

    user_repository.get_by_username.assert_called_once_with(
        "souocare",
    )


def test_authenticate_rejects_inactive_user(
    authentication_service: AuthenticationService,
    user_repository: Mock,
) -> None:
    """Reject a user even when its credentials are otherwise valid."""

    user = User(
        username="souocare",
        display_name="Gonçalo",
        password_hash=hash_password("correct-password"),
        is_active=False,
        is_local=False,
    )

    user_repository.get_by_username.return_value = user

    result = authentication_service.authenticate(
        username="souocare",
        password="correct-password",
    )

    assert result is None

    user_repository.get_by_username.assert_called_once_with(
        "souocare",
    )


@pytest.mark.parametrize(
    ("username", "password"),
    [
        ("", "password"),
        ("   ", "password"),
        ("souocare", ""),
    ],
)
def test_authenticate_rejects_empty_credentials(
    authentication_service: AuthenticationService,
    user_repository: Mock,
    username: str,
    password: str,
) -> None:
    """Reject incomplete credentials without querying the repository."""

    result = authentication_service.authenticate(
        username=username,
        password=password,
    )

    assert result is None

    user_repository.get_by_username.assert_not_called()

