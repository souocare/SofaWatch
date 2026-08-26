from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.models.authentication_settings import AuthenticationSettings
from app.models.user import User


def test_admin_can_get_security_settings(
    client: TestClient,
    db_session: Session,
) -> None:
    user = User(
        display_name="Administrator",
        is_active=True,
        is_admin=True,
    )

    db_session.add(user)
    db_session.commit()

    response = client.get(
        "/api/v1/security",
    )

    assert response.status_code == 200

    assert response.json() == {
        "open_registration": False,
    }


def test_admin_can_enable_open_registration(
    client: TestClient,
    db_session: Session,
) -> None:
    user = User(
        display_name="Administrator",
        is_active=True,
        is_admin=True,
    )

    db_session.add(user)
    db_session.commit()

    response = client.patch(
        "/api/v1/security",
        json={
            "open_registration": True,
        },
    )

    assert response.status_code == 200

    assert response.json() == {
        "open_registration": True,
    }

    settings = db_session.query(AuthenticationSettings).one()

    assert settings.open_registration is True


def test_admin_can_disable_open_registration(
    client: TestClient,
    db_session: Session,
) -> None:
    user = User(
        display_name="Administrator",
        is_active=True,
        is_admin=True,
    )

    db_session.add(user)

    db_session.add(
        AuthenticationSettings(
            open_registration=True,
        ),
    )

    db_session.commit()

    response = client.patch(
        "/api/v1/security",
        json={
            "open_registration": False,
        },
    )

    assert response.status_code == 200

    assert response.json() == {
        "open_registration": False,
    }

    settings = db_session.query(AuthenticationSettings).one()

    assert settings.open_registration is False


def test_regular_user_cannot_access_security_settings(
    client: TestClient,
) -> None:
    response = client.get(
        "/api/v1/security",
    )

    assert response.status_code == 403

    assert response.json() == {
        "error": {
            "code": "admin_required",
            "message": "Administrator access is required.",
        }
    }

def test_regular_user_cannot_change_security_settings(
    client: TestClient,
) -> None:
    response = client.patch(
        "/api/v1/security",
        json={
            "open_registration": True,
        },
    )

    assert response.status_code == 403

    assert response.json() == {
        "error": {
            "code": "admin_required",
            "message": "Administrator access is required.",
        }
    }

def test_disabling_open_registration_blocks_new_registrations(
    client: TestClient,
    db_session: Session,
) -> None:
    admin = User(
        username="administrator",
        display_name="Administrator",
        is_active=True,
        is_admin=True,
    )

    db_session.add(admin)

    db_session.add(
        AuthenticationSettings(
            open_registration=True,
        )
    )

    db_session.commit()

    response = client.patch(
        "/api/v1/security",
        json={
            "open_registration": False,
        },
    )

    assert response.status_code == 200
    assert response.json() == {
        "open_registration": False,
    }

    response = client.post(
        "/api/v1/auth/register",
        json={
            "username": "new-user",
            "display_name": "New User",
            "password": "correct-password",
        },
    )

    assert response.status_code == 403
    assert response.json() == {
        "error": {
            "code": "registration_closed",
            "message": "Account registration is currently closed.",
        }
    }