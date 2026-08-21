from datetime import UTC, datetime

from fastapi.testclient import TestClient
from sqlalchemy import select

from sqlalchemy.orm import Session

from app.core.security.passwords import hash_password
from app.core.security.tokens import AccessTokenService
from app.core.config import get_settings
from app.models.user import User


def _create_user(
    db_session: Session,
    *,
    username: str = "souocare",
    password: str = "correct-password",
    is_active: bool = True,
) -> User:
    user = User(
        username=username,
        display_name="Gonçalo",
        password_hash=hash_password(password),
        is_active=is_active,
        is_local=False,
    )

    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)

    return user


def test_login_returns_access_token_for_valid_credentials(
    client: TestClient,
    db_session: Session,
) -> None:
    user = _create_user(
        db_session,
    )

    response = client.post(
        "/api/v1/auth/login",
        json={
            "username": "souocare",
            "password": "correct-password",
        },
    )

    assert response.status_code == 200

    payload = response.json()

    assert payload["token_type"] == "bearer"
    assert payload["expires_in"] == 15 * 60
    assert isinstance(payload["access_token"], str)
    assert payload["access_token"]


def test_login_access_token_identifies_authenticated_user(
    client: TestClient,
    db_session: Session,
) -> None:
    user = _create_user(
        db_session,
    )

    response = client.post(
        "/api/v1/auth/login",
        json={
            "username": "  SOUOCARE  ",
            "password": "correct-password",
        },
    )

    assert response.status_code == 200

    settings = get_settings()

    token_service = AccessTokenService(
        secret_key=settings.secret_key.get_secret_value(),
        expire_minutes=settings.access_token_expire_minutes,
    )

    claims = token_service.validate(
        response.json()["access_token"],
    )

    assert claims.user_id == user.id
    assert claims.expires_at > datetime.now(UTC)


def test_login_rejects_wrong_password(
    client: TestClient,
    db_session: Session,
) -> None:
    _create_user(
        db_session,
    )

    response = client.post(
        "/api/v1/auth/login",
        json={
            "username": "souocare",
            "password": "wrong-password",
        },
    )

    assert response.status_code == 401

    assert response.json() == {
        "error": {
            "code": "invalid_credentials",
            "message": "The username or password is incorrect.",
        }
    }


def test_login_rejects_unknown_username(
    client: TestClient,
) -> None:
    response = client.post(
        "/api/v1/auth/login",
        json={
            "username": "missing-user",
            "password": "some-password",
        },
    )

    assert response.status_code == 401

    assert response.json() == {
        "error": {
            "code": "invalid_credentials",
            "message": "The username or password is incorrect.",
        }
    }


def test_login_rejects_inactive_user_without_disclosing_status(
    client: TestClient,
    db_session: Session,
) -> None:
    _create_user(
        db_session,
        is_active=False,
    )

    response = client.post(
        "/api/v1/auth/login",
        json={
            "username": "souocare",
            "password": "correct-password",
        },
    )

    assert response.status_code == 401

    assert response.json() == {
        "error": {
            "code": "invalid_credentials",
            "message": "The username or password is incorrect.",
        }
    }

def test_setup_status_reports_existing_installation(
    client: TestClient,
    db_session: Session,
) -> None:
    user = User(
        username="souocare",
        display_name="Gonçalo",
        password_hash=hash_password("correct-password"),
        is_active=True,
        is_local=False,
        is_admin=True,
    )

    db_session.add(user)
    db_session.commit()

    response = client.get(
        "/api/v1/auth/setup",
    )

    assert response.status_code == 200

    assert response.json() == {
        "setup_required": False,
    }

def test_setup_status_reports_setup_required_when_no_users_exist(
    client: TestClient,
) -> None:
    response = client.get(
        "/api/v1/auth/setup",
    )

    assert response.status_code == 200

    assert response.json() == {
        "setup_required": True,
    }

def test_initial_setup_creates_first_administrator(
    client: TestClient,
    db_session: Session,
) -> None:
    response = client.post(
        "/api/v1/auth/setup",
        json={
            "username": "SouOCare",
            "display_name": "Gonçalo",
            "password": "correct-password",
        },
    )

    assert response.status_code == 201

    payload = response.json()

    assert payload["token_type"] == "bearer"
    assert payload["access_token"]
    assert payload["expires_in"] > 0

    user = db_session.scalar(
        select(User).where(
            User.username == "souocare",
        )
    )

    assert user is not None
    assert user.display_name == "Gonçalo"
    assert user.is_admin is True
    assert user.is_active is True
    assert user.is_local is False
    assert user.password_hash is not None

def test_initial_setup_is_closed_after_first_user(
    client: TestClient,
    db_session: Session,
) -> None:
    existing_user = User(
        username="existing",
        display_name="Existing User",
        is_local=False,
    )

    db_session.add(existing_user)
    db_session.commit()

    response = client.post(
        "/api/v1/auth/setup",
        json={
            "username": "souocare",
            "display_name": "Gonçalo",
            "password": "correct-password",
        },
    )

    assert response.status_code == 409

    assert response.json() == {
        "error": {
            "code": "initial_setup_completed",
            "message": "Initial SofaWatch setup has already been completed.",
        }
    }