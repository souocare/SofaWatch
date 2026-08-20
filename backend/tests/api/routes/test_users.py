from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.models.user import User


def test_get_current_user_returns_local_user(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return the current local SofaWatch user."""

    user = User(
        display_name="Local User",
        is_local=True,
    )

    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)

    response = client.get(
        "/api/v1/users/me",
    )

    assert response.status_code == 200

    payload = response.json()

    assert payload == {
        "id": str(user.id),
        "display_name": "Local User",
        "is_local": True,
        "is_admin": False,
    }

def test_get_current_user_ignores_non_local_users(
    client: TestClient,
    db_session: Session,
) -> None:
    """Resolve the current user from the local-user marker."""

    local_user = User(
        display_name="Gonçalo",
        is_local=True,
    )

    other_user = User(
        display_name="Other User",
        is_local=False,
    )

    db_session.add_all(
        [
            local_user,
            other_user,
        ]
    )
    db_session.commit()
    db_session.refresh(local_user)

    response = client.get(
        "/api/v1/users/me",
    )

    assert response.status_code == 200

    payload = response.json()

    assert payload["id"] == str(local_user.id)
    assert payload["display_name"] == "Gonçalo"
    assert payload["is_local"] is True
    assert payload["is_admin"] is False

def test_get_current_user_returns_error_when_local_user_is_missing(
    client: TestClient,
) -> None:
    """Return a safe API error when no local user is configured."""

    response = client.get(
        "/api/v1/users/me",
    )

    assert response.status_code == 500

    payload = response.json()

    assert payload["error"]["code"] == "local_user_not_configured"