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


def test_authenticate_returns_user_for_valid_username_credentials(
    authentication_service: AuthenticationService,
    user_repository: Mock,
) -> None:
    """Return the user when username and password are valid."""

    user = User(
        username="souocare",
        email="goncalo@example.com",
        display_name="Gonçalo",
        password_hash=hash_password("correct-password"),
        is_active=True,
        is_local=False,
    )

    user_repository.get_by_username.return_value = user

    result = authentication_service.authenticate(
        identifier="souocare",
        password="correct-password",
    )

    assert result is user

    user_repository.get_by_username.assert_called_once_with(
        "souocare",
    )

    user_repository.get_by_email.assert_not_called()


def test_authenticate_returns_user_for_valid_email_credentials(
    authentication_service: AuthenticationService,
    user_repository: Mock,
) -> None:
    """Return the user when email and password are valid."""

    user = User(
        username="souocare",
        email="goncalo@example.com",
        display_name="Gonçalo",
        password_hash=hash_password("correct-password"),
        is_active=True,
        is_local=False,
    )

    user_repository.get_by_username.return_value = None
    user_repository.get_by_email.return_value = user

    result = authentication_service.authenticate(
        identifier="goncalo@example.com",
        password="correct-password",
    )

    assert result is user

    user_repository.get_by_username.assert_called_once_with(
        "goncalo@example.com",
    )

    user_repository.get_by_email.assert_called_once_with(
        "goncalo@example.com",
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
        identifier="  SouOCare  ",
        password="correct-password",
    )

    assert result is user

    user_repository.get_by_username.assert_called_once_with(
        "souocare",
    )

    user_repository.get_by_email.assert_not_called()


def test_authenticate_normalizes_email(
    authentication_service: AuthenticationService,
    user_repository: Mock,
) -> None:
    """Normalize email before querying the repository."""

    user = User(
        username="souocare",
        email="goncalo@example.com",
        display_name="Gonçalo",
        password_hash=hash_password("correct-password"),
        is_active=True,
        is_local=False,
    )

    user_repository.get_by_username.return_value = None
    user_repository.get_by_email.return_value = user

    result = authentication_service.authenticate(
        identifier="  Goncalo@Example.COM  ",
        password="correct-password",
    )

    assert result is user

    user_repository.get_by_username.assert_called_once_with(
        "goncalo@example.com",
    )

    user_repository.get_by_email.assert_called_once_with(
        "goncalo@example.com",
    )


def test_authenticate_prefers_username_over_email(
    authentication_service: AuthenticationService,
    user_repository: Mock,
) -> None:
    """Prefer an exact username match before considering email."""

    user = User(
        username="souocare",
        email="another@example.com",
        display_name="Gonçalo",
        password_hash=hash_password("correct-password"),
        is_active=True,
        is_local=False,
    )

    user_repository.get_by_username.return_value = user

    result = authentication_service.authenticate(
        identifier="souocare",
        password="correct-password",
    )

    assert result is user

    user_repository.get_by_username.assert_called_once_with(
        "souocare",
    )

    user_repository.get_by_email.assert_not_called()


def test_authenticate_returns_none_for_unknown_identifier(
    authentication_service: AuthenticationService,
    user_repository: Mock,
) -> None:
    """Reject credentials when neither username nor email exists."""

    user_repository.get_by_username.return_value = None
    user_repository.get_by_email.return_value = None

    result = authentication_service.authenticate(
        identifier="missing@example.com",
        password="password",
    )

    assert result is None

    user_repository.get_by_username.assert_called_once_with(
        "missing@example.com",
    )

    user_repository.get_by_email.assert_called_once_with(
        "missing@example.com",
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
        identifier="souocare",
        password="wrong-password",
    )

    assert result is None

    user_repository.get_by_username.assert_called_once_with(
        "souocare",
    )

    user_repository.get_by_email.assert_not_called()


def test_authenticate_returns_none_for_user_without_password(
    authentication_service: AuthenticationService,
    user_repository: Mock,
) -> None:
    """Reject users that do not have authentication credentials."""

    user = User(
        username="souocare",
        display_name="Gonçalo",
        password_hash=None,
        is_active=True,
        is_local=True,
    )

    user_repository.get_by_username.return_value = user

    result = authentication_service.authenticate(
        identifier="souocare",
        password="password",
    )

    assert result is None

    user_repository.get_by_username.assert_called_once_with(
        "souocare",
    )

    user_repository.get_by_email.assert_not_called()


def test_authenticate_rejects_inactive_user(
    authentication_service: AuthenticationService,
    user_repository: Mock,
) -> None:
    """Reject inactive users even when their credentials are valid."""

    user = User(
        username="souocare",
        email="goncalo@example.com",
        display_name="Gonçalo",
        password_hash=hash_password("correct-password"),
        is_active=False,
        is_local=False,
    )

    user_repository.get_by_username.return_value = user

    result = authentication_service.authenticate(
        identifier="souocare",
        password="correct-password",
    )

    assert result is None

    user_repository.get_by_username.assert_called_once_with(
        "souocare",
    )

    user_repository.get_by_email.assert_not_called()


def test_authenticate_rejects_inactive_user_authenticated_by_email(
    authentication_service: AuthenticationService,
    user_repository: Mock,
) -> None:
    """Reject inactive users without distinguishing email authentication."""

    user = User(
        username="souocare",
        email="goncalo@example.com",
        display_name="Gonçalo",
        password_hash=hash_password("correct-password"),
        is_active=False,
        is_local=False,
    )

    user_repository.get_by_username.return_value = None
    user_repository.get_by_email.return_value = user

    result = authentication_service.authenticate(
        identifier="goncalo@example.com",
        password="correct-password",
    )

    assert result is None

    user_repository.get_by_username.assert_called_once_with(
        "goncalo@example.com",
    )

    user_repository.get_by_email.assert_called_once_with(
        "goncalo@example.com",
    )


@pytest.mark.parametrize(
    ("identifier", "password"),
    [
        ("", "password"),
        ("   ", "password"),
        ("souocare", ""),
        ("goncalo@example.com", ""),
    ],
)
def test_authenticate_rejects_empty_credentials(
    authentication_service: AuthenticationService,
    user_repository: Mock,
    identifier: str,
    password: str,
) -> None:
    """Reject incomplete credentials without querying the repository."""

    result = authentication_service.authenticate(
        identifier=identifier,
        password=password,
    )

    assert result is None

    user_repository.get_by_username.assert_not_called()
    user_repository.get_by_email.assert_not_called()