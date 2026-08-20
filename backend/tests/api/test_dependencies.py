from types import SimpleNamespace
from uuid import uuid4

import pytest

from app.api.dependencies import require_admin
from app.core.exceptions import APIError


def make_user(
    *,
    is_admin: bool,
) -> SimpleNamespace:
    """Create a lightweight current-user object for dependency tests."""

    return SimpleNamespace(
        id=uuid4(),
        display_name="Test User",
        is_local=True,
        is_admin=is_admin,
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