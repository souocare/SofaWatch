from datetime import UTC, datetime, timedelta
from types import SimpleNamespace
from unittest.mock import Mock
from uuid import uuid4

import pytest
from fastapi.security import HTTPAuthorizationCredentials

from app.api.dependencies import get_current_user, require_admin
from app.core.exceptions import APIError
from app.core.security.tokens import AccessTokenService


_TEST_SECRET = "test-secret-key-that-is-at-least-32-characters-long"


def make_user(
    *,
    is_admin: bool = False,
    is_active: bool = True,
) -> SimpleNamespace:
    """Create a lightweight current-user object for dependency tests."""

    return SimpleNamespace(
        id=uuid4(),
        username="testuser",
        display_name="Test User",
        is_active=is_active,
        is_local=False,
        is_admin=is_admin,
    )


def make_access_token_service(
    *,
    expire_minutes: int = 15,
) -> AccessTokenService:
    """Create an access token service for dependency tests."""

    return AccessTokenService(
        secret_key=_TEST_SECRET,
        expire_minutes=expire_minutes,
    )


def bearer_credentials(
    token: str,
) -> HTTPAuthorizationCredentials:
    """Create Bearer credentials for a test request."""

    return HTTPAuthorizationCredentials(
        scheme="Bearer",
        credentials=token,
    )


def test_get_current_user_returns_authenticated_user() -> None:
    """Resolve the user represented by a valid access token."""

    user = make_user()

    user_service = Mock()
    user_service.get_by_id.return_value = user

    token_service = make_access_token_service()

    token = token_service.create(
        user_id=user.id,
    )

    result = get_current_user(
        user_service=user_service,
        access_token_service=token_service,
        credentials=bearer_credentials(token),
    )

    assert result is user

    user_service.get_by_id.assert_called_once_with(
        user.id,
    )


def test_get_current_user_requires_authentication() -> None:
    """Reject requests that do not contain Bearer credentials."""

    user_service = Mock()

    token_service = make_access_token_service()

    with pytest.raises(APIError) as exc_info:
        get_current_user(
            user_service=user_service,
            access_token_service=token_service,
            credentials=None,
        )

    error = exc_info.value

    assert error.status_code == 401
    assert error.code == "authentication_required"
    assert error.message == "Authentication is required."

    user_service.get_by_id.assert_not_called()


def test_get_current_user_rejects_invalid_access_token() -> None:
    """Reject malformed or incorrectly signed access tokens."""

    user_service = Mock()

    token_service = make_access_token_service()

    with pytest.raises(APIError) as exc_info:
        get_current_user(
            user_service=user_service,
            access_token_service=token_service,
            credentials=bearer_credentials(
                "not-a-valid-access-token",
            ),
        )

    error = exc_info.value

    assert error.status_code == 401
    assert error.code == "invalid_access_token"
    assert error.message == "The access token is invalid or expired."

    user_service.get_by_id.assert_not_called()


def test_get_current_user_rejects_expired_access_token() -> None:
    """Reject expired access tokens."""

    user = make_user()

    user_service = Mock()

    token_service = make_access_token_service(
        expire_minutes=1,
    )

    token = token_service.create(
        user_id=user.id,
        now=datetime.now(UTC) - timedelta(minutes=5),
    )

    with pytest.raises(APIError) as exc_info:
        get_current_user(
            user_service=user_service,
            access_token_service=token_service,
            credentials=bearer_credentials(token),
        )

    error = exc_info.value

    assert error.status_code == 401
    assert error.code == "invalid_access_token"
    assert error.message == "The access token is invalid or expired."

    user_service.get_by_id.assert_not_called()


def test_get_current_user_rejects_unknown_user() -> None:
    """Reject a valid token whose user no longer exists."""

    user_id = uuid4()

    user_service = Mock()
    user_service.get_by_id.return_value = None

    token_service = make_access_token_service()

    token = token_service.create(
        user_id=user_id,
    )

    with pytest.raises(APIError) as exc_info:
        get_current_user(
            user_service=user_service,
            access_token_service=token_service,
            credentials=bearer_credentials(token),
        )

    error = exc_info.value

    assert error.status_code == 401
    assert error.code == "invalid_access_token"
    assert error.message == "The access token is invalid or expired."

    user_service.get_by_id.assert_called_once_with(
        user_id,
    )


def test_get_current_user_rejects_inactive_user() -> None:
    """Reject tokens belonging to inactive users."""

    user = make_user(
        is_active=False,
    )

    user_service = Mock()
    user_service.get_by_id.return_value = user

    token_service = make_access_token_service()

    token = token_service.create(
        user_id=user.id,
    )

    with pytest.raises(APIError) as exc_info:
        get_current_user(
            user_service=user_service,
            access_token_service=token_service,
            credentials=bearer_credentials(token),
        )

    error = exc_info.value

    assert error.status_code == 401
    assert error.code == "invalid_access_token"
    assert error.message == "The access token is invalid or expired."

    user_service.get_by_id.assert_called_once_with(
        user.id,
    )


def test_get_admin_user_returns_admin_user() -> None:
    """Allow administrators to access admin-only dependencies."""

    user = make_user(
        is_admin=True,
    )

    result = require_admin(
        current_user=user,
    )

    assert result is user


def test_get_admin_user_rejects_non_admin_user() -> None:
    """Reject non-administrators from admin-only dependencies."""

    user = make_user(
        is_admin=False,
    )

    with pytest.raises(APIError) as exc_info:
        require_admin(
            current_user=user,
        )

    error = exc_info.value

    assert error.status_code == 403
    assert error.code == "admin_required"
    assert error.message == "Administrator access is required."