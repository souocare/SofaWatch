from datetime import UTC, datetime

from fastapi.testclient import TestClient
from sqlalchemy import select

from sqlalchemy.orm import Session

from app.core.security.passwords import hash_password
from app.core.security.tokens import AccessTokenService
from app.core.config import get_settings
from app.models.user import User
from app.core.security.session_credentials import hash_session_credential
from app.models.auth_session import AuthSession, AuthSessionType
from app.repositories.auth_session import AuthSessionRepository
from app.services.auth_session import AuthSessionService


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

def test_login_creates_persistent_web_session(
    client: TestClient,
    db_session: Session,
) -> None:
    """Create a persistent Web session after successful authentication."""

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

    credential = response.cookies.get(
        "sofawatch_session",
    )

    assert credential is not None
    assert credential

    auth_session = db_session.scalar(
        select(AuthSession).where(
            AuthSession.user_id == user.id,
        )
    )

    assert auth_session is not None
    assert auth_session.session_type == AuthSessionType.WEB
    assert auth_session.revoked_at is None

    assert auth_session.credential_hash == (
        hash_session_credential(credential)
    )


def test_login_session_cookie_is_http_only(
    client: TestClient,
    db_session: Session,
) -> None:
    """Protect the persistent Web credential using cookie security attributes."""

    _create_user(
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

    set_cookie = response.headers["set-cookie"]

    assert "sofawatch_session=" in set_cookie
    assert "HttpOnly" in set_cookie
    assert "SameSite=lax" in set_cookie
    assert "Path=/" in set_cookie


def test_login_does_not_expose_persistent_session_credential(
    client: TestClient,
    db_session: Session,
) -> None:
    """Never expose the persistent Web session credential in the API body."""

    _create_user(
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

    assert set(payload) == {
        "access_token",
        "token_type",
        "expires_in",
    }

    cookie_credential = response.cookies.get(
        "sofawatch_session",
    )

    assert cookie_credential is not None
    assert cookie_credential not in response.text


def test_initial_setup_creates_persistent_web_session(
    client: TestClient,
    db_session: Session,
) -> None:
    """Persist the first administrator's Web authentication session."""

    response = client.post(
        "/api/v1/auth/setup",
        json={
            "username": "SouOCare",
            "display_name": "Gonçalo",
            "password": "correct-password",
        },
    )

    assert response.status_code == 201

    credential = response.cookies.get(
        "sofawatch_session",
    )

    assert credential is not None

    auth_session = db_session.scalar(
        select(AuthSession)
    )

    assert auth_session is not None
    assert auth_session.session_type == AuthSessionType.WEB
    assert auth_session.credential_hash == (
        hash_session_credential(credential)
    )


def test_restore_web_session_returns_new_access_token(
    client: TestClient,
    db_session: Session,
) -> None:
    """Restore a valid persistent Web session."""

    user = _create_user(
        db_session,
    )

    login_response = client.post(
        "/api/v1/auth/login",
        json={
            "username": "souocare",
            "password": "correct-password",
        },
    )

    assert login_response.status_code == 200

    response = client.post(
        "/api/v1/auth/session",
    )

    assert response.status_code == 200

    payload = response.json()

    assert payload["token_type"] == "bearer"
    assert payload["access_token"]
    assert payload["expires_in"] == 15 * 60

    settings = get_settings()

    token_service = AccessTokenService(
        secret_key=settings.secret_key.get_secret_value(),
        expire_minutes=settings.access_token_expire_minutes,
    )

    claims = token_service.validate(
        payload["access_token"],
    )

    assert claims.user_id == user.id


def test_restore_web_session_requires_session_cookie(
    unauthenticated_client: TestClient,
) -> None:
    """Reject session restoration without a persistent Web session."""

    response = unauthenticated_client.post(
        "/api/v1/auth/session",
    )

    assert response.status_code == 401

    assert response.json() == {
        "error": {
            "code": "session_required",
            "message": "An authenticated session is required.",
        }
    }

def test_restore_web_session_rejects_invalid_cookie(
    unauthenticated_client: TestClient,
) -> None:
    """Reject an unknown persistent session credential."""

    unauthenticated_client.cookies.set(
        "sofawatch_session",
        "invalid-session-credential",
    )

    response = unauthenticated_client.post(
        "/api/v1/auth/session",
    )

    assert response.status_code == 401

    assert response.json() == {
        "error": {
            "code": "invalid_session",
            "message": "The authentication session is invalid or expired.",
        }
    }


def test_restore_web_session_rejects_revoked_session(
    client: TestClient,
    db_session: Session,
) -> None:
    """Reject a persistent session after it has been revoked."""

    user = _create_user(
        db_session,
    )

    login_response = client.post(
        "/api/v1/auth/login",
        json={
            "username": "souocare",
            "password": "correct-password",
        },
    )

    assert login_response.status_code == 200

    auth_session = db_session.scalar(
        select(AuthSession).where(
            AuthSession.user_id == user.id,
        )
    )

    assert auth_session is not None

    auth_session.revoked_at = datetime.now(UTC)

    db_session.commit()

    response = client.post(
        "/api/v1/auth/session",
    )

    assert response.status_code == 401

    assert response.json() == {
        "error": {
            "code": "invalid_session",
            "message": "The authentication session is invalid or expired.",
        }
    }

def test_restore_web_session_rejects_inactive_user(
    client: TestClient,
    db_session: Session,
) -> None:
    """Reject persistent sessions belonging to inactive users."""

    user = _create_user(
        db_session,
    )

    login_response = client.post(
        "/api/v1/auth/login",
        json={
            "username": "souocare",
            "password": "correct-password",
        },
    )

    assert login_response.status_code == 200

    user.is_active = False

    db_session.commit()

    response = client.post(
        "/api/v1/auth/session",
    )

    assert response.status_code == 401

    assert response.json() == {
        "error": {
            "code": "invalid_session",
            "message": "The authentication session is invalid or expired.",
        }
    }

def test_restore_web_session_rejects_expired_session(
    client: TestClient,
    db_session: Session,
) -> None:
    """Reject an expired persistent Web session."""

    user = _create_user(
        db_session,
    )

    login_response = client.post(
        "/api/v1/auth/login",
        json={
            "username": "souocare",
            "password": "correct-password",
        },
    )

    assert login_response.status_code == 200

    auth_session = db_session.scalar(
        select(AuthSession).where(
            AuthSession.user_id == user.id,
        )
    )

    assert auth_session is not None

    auth_session.expires_at = datetime(
        2020,
        1,
        1,
        tzinfo=UTC,
    )

    db_session.commit()

    response = client.post(
        "/api/v1/auth/session",
    )

    assert response.status_code == 401

    assert response.json()["error"]["code"] == "invalid_session"

def test_restore_web_session_reuses_existing_auth_session(
    client: TestClient,
    db_session: Session,
) -> None:
    """Restore authentication without creating duplicate persistent sessions."""

    user = _create_user(
        db_session,
    )

    login_response = client.post(
        "/api/v1/auth/login",
        json={
            "username": "souocare",
            "password": "correct-password",
        },
    )

    assert login_response.status_code == 200

    sessions_before = list(
        db_session.scalars(
            select(AuthSession).where(
                AuthSession.user_id == user.id,
            )
        ).all()
    )

    assert len(sessions_before) == 1

    response = client.post(
        "/api/v1/auth/session",
    )

    assert response.status_code == 200

    sessions_after = list(
        db_session.scalars(
            select(AuthSession).where(
                AuthSession.user_id == user.id,
            )
        ).all()
    )

    assert len(sessions_after) == 1
    assert sessions_after[0].id == sessions_before[0].id

def test_logout_revokes_current_web_session(
    client: TestClient,
    db_session: Session,
) -> None:
    """Revoke the persistent Web session during logout."""

    user = _create_user(
        db_session,
    )

    login_response = client.post(
        "/api/v1/auth/login",
        json={
            "username": "souocare",
            "password": "correct-password",
        },
    )

    assert login_response.status_code == 200

    auth_session = db_session.scalar(
        select(AuthSession).where(
            AuthSession.user_id == user.id,
        )
    )

    assert auth_session is not None
    assert auth_session.revoked_at is None

    response = client.post(
        "/api/v1/auth/logout",
    )

    assert response.status_code == 204

    db_session.refresh(
        auth_session,
    )

    assert auth_session.revoked_at is not None


def test_logout_clears_web_session_cookie(
    client: TestClient,
    db_session: Session,
) -> None:
    """Remove the persistent Web session cookie during logout."""

    _create_user(
        db_session,
    )

    login_response = client.post(
        "/api/v1/auth/login",
        json={
            "username": "souocare",
            "password": "correct-password",
        },
    )

    assert login_response.status_code == 200

    assert client.cookies.get(
        "sofawatch_session",
    ) is not None

    response = client.post(
        "/api/v1/auth/logout",
    )

    assert response.status_code == 204

    assert client.cookies.get(
        "sofawatch_session",
    ) is None


def test_logged_out_web_session_cannot_be_restored(
    client: TestClient,
    db_session: Session,
) -> None:
    """Prevent restoring authentication after logout."""

    _create_user(
        db_session,
    )

    login_response = client.post(
        "/api/v1/auth/login",
        json={
            "username": "souocare",
            "password": "correct-password",
        },
    )

    assert login_response.status_code == 200

    credential = login_response.cookies.get(
        "sofawatch_session",
    )

    assert credential is not None

    logout_response = client.post(
        "/api/v1/auth/logout",
    )

    assert logout_response.status_code == 204

    client.cookies.set(
        "sofawatch_session",
        credential,
    )

    restore_response = client.post(
        "/api/v1/auth/session",
    )

    assert restore_response.status_code == 401
    assert restore_response.json()["error"]["code"] == "invalid_session"


def test_logout_is_idempotent_without_session(
    unauthenticated_client: TestClient,
) -> None:
    """Allow logout when no persistent session exists."""

    response = unauthenticated_client.post(
        "/api/v1/auth/logout",
    )

    assert response.status_code == 204


def test_logout_all_revokes_every_user_session(
    client: TestClient,
    db_session: Session,
) -> None:
    """Revoke every persistent authentication session for the current user."""

    user = _create_user(
        db_session,
    )

    service = AuthSessionService(
        session=db_session,
        repository=AuthSessionRepository(
            db_session,
        ),
        idle_expire_days=180,
    )

    web_session = service.create(
        user_id=user.id,
        session_type=AuthSessionType.WEB,
    )

    mobile_session = service.create(
        user_id=user.id,
        session_type=AuthSessionType.MOBILE,
    )

    response = client.post(
        "/api/v1/auth/logout-all",
    )

    assert response.status_code == 204

    db_session.refresh(
        web_session.session,
    )
    db_session.refresh(
        mobile_session.session,
    )

    assert web_session.session.revoked_at is not None
    assert mobile_session.session.revoked_at is not None


def test_logout_all_does_not_revoke_other_users_sessions(
    client: TestClient,
    db_session: Session,
) -> None:
    """Keep authentication sessions belonging to other users active."""

    user = _create_user(
        db_session,
    )

    other_user = User(
        username="other-user",
        display_name="Other User",
        is_active=True,
        is_local=False,
    )

    db_session.add(
        other_user,
    )
    db_session.commit()
    db_session.refresh(
        other_user,
    )

    service = AuthSessionService(
        session=db_session,
        repository=AuthSessionRepository(
            db_session,
        ),
        idle_expire_days=180,
    )

    current_session = service.create(
        user_id=user.id,
        session_type=AuthSessionType.WEB,
    )

    other_session = service.create(
        user_id=other_user.id,
        session_type=AuthSessionType.WEB,
    )

    response = client.post(
        "/api/v1/auth/logout-all",
    )

    assert response.status_code == 204

    db_session.refresh(
        current_session.session,
    )
    db_session.refresh(
        other_session.session,
    )

    assert current_session.session.revoked_at is not None
    assert other_session.session.revoked_at is None

def test_logout_all_clears_current_web_session_cookie(
    client: TestClient,
    db_session: Session,
) -> None:
    """Remove the current browser session cookie when logging out everywhere."""

    _create_user(
        db_session,
    )

    login_response = client.post(
        "/api/v1/auth/login",
        json={
            "username": "souocare",
            "password": "correct-password",
        },
    )

    assert login_response.status_code == 200

    assert client.cookies.get(
        "sofawatch_session",
    ) is not None

    response = client.post(
        "/api/v1/auth/logout-all",
    )

    assert response.status_code == 204

    assert client.cookies.get(
        "sofawatch_session",
    ) is None


def test_logout_all_prevents_restoring_previous_web_session(
    client: TestClient,
    db_session: Session,
) -> None:
    """Prevent restoring a Web session revoked by logout-all."""

    _create_user(
        db_session,
    )

    login_response = client.post(
        "/api/v1/auth/login",
        json={
            "username": "souocare",
            "password": "correct-password",
        },
    )

    assert login_response.status_code == 200

    credential = login_response.cookies.get(
        "sofawatch_session",
    )

    assert credential is not None

    logout_response = client.post(
        "/api/v1/auth/logout-all",
    )

    assert logout_response.status_code == 204

    client.cookies.set(
        "sofawatch_session",
        credential,
    )

    restore_response = client.post(
        "/api/v1/auth/session",
    )

    assert restore_response.status_code == 401
    assert restore_response.json()["error"]["code"] == "invalid_session"






def test_mobile_login_creates_persistent_mobile_session(
    client: TestClient,
    db_session: Session,
) -> None:
    """Create a persistent Mobile session after successful authentication."""

    user = _create_user(
        db_session,
    )

    response = client.post(
        "/api/v1/auth/mobile/login",
        json={
            "username": "souocare",
            "password": "correct-password",
        },
    )

    assert response.status_code == 200

    payload = response.json()

    assert payload["token_type"] == "bearer"
    assert payload["access_token"]
    assert payload["refresh_token"]
    assert payload["expires_in"] == 15 * 60

    auth_session = db_session.scalar(
        select(AuthSession).where(
            AuthSession.user_id == user.id,
        )
    )

    assert auth_session is not None
    assert auth_session.session_type == AuthSessionType.MOBILE
    assert auth_session.revoked_at is None


def test_mobile_login_stores_only_refresh_credential_hash(
    client: TestClient,
    db_session: Session,
) -> None:
    """Persist only the hash of the Mobile refresh credential."""

    user = _create_user(
        db_session,
    )

    response = client.post(
        "/api/v1/auth/mobile/login",
        json={
            "username": "souocare",
            "password": "correct-password",
        },
    )

    assert response.status_code == 200

    refresh_token = response.json()["refresh_token"]

    auth_session = db_session.scalar(
        select(AuthSession).where(
            AuthSession.user_id == user.id,
        )
    )

    assert auth_session is not None

    assert auth_session.credential_hash != refresh_token
    assert auth_session.credential_hash == (
        hash_session_credential(refresh_token)
    )


def test_mobile_login_does_not_create_web_session_cookie(
    client: TestClient,
    db_session: Session,
) -> None:
    """Do not expose Mobile authentication through the Web session cookie."""

    _create_user(
        db_session,
    )

    response = client.post(
        "/api/v1/auth/mobile/login",
        json={
            "username": "souocare",
            "password": "correct-password",
        },
    )

    assert response.status_code == 200

    assert response.cookies.get(
        "sofawatch_session",
    ) is None


def test_mobile_login_rejects_invalid_credentials(
    client: TestClient,
    db_session: Session,
) -> None:
    """Reject invalid Mobile credentials without creating a session."""

    _create_user(
        db_session,
    )

    response = client.post(
        "/api/v1/auth/mobile/login",
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

    sessions = list(
        db_session.scalars(
            select(AuthSession)
        ).all()
    )

    assert sessions == []


def test_mobile_refresh_rotates_refresh_token(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return new Mobile credentials and rotate the refresh token."""

    user = _create_user(
        db_session,
    )

    login_response = client.post(
        "/api/v1/auth/mobile/login",
        json={
            "username": "souocare",
            "password": "correct-password",
        },
    )

    assert login_response.status_code == 200

    original_refresh_token = login_response.json()[
        "refresh_token"
    ]

    response = client.post(
        "/api/v1/auth/refresh",
        json={
            "refresh_token": original_refresh_token,
        },
    )

    assert response.status_code == 200

    payload = response.json()

    assert payload["token_type"] == "bearer"
    assert payload["access_token"]
    assert payload["expires_in"] == 15 * 60

    assert payload["refresh_token"]
    assert payload["refresh_token"] != original_refresh_token

    auth_session = db_session.scalar(
        select(AuthSession).where(
            AuthSession.user_id == user.id,
        )
    )

    assert auth_session is not None

    assert auth_session.credential_hash == (
        hash_session_credential(
            payload["refresh_token"],
        )
    )


def test_mobile_refresh_rejects_reused_previous_refresh_token(
    client: TestClient,
    db_session: Session,
) -> None:
    """Reject a Mobile refresh credential after it has been rotated."""

    _create_user(
        db_session,
    )

    login_response = client.post(
        "/api/v1/auth/mobile/login",
        json={
            "username": "souocare",
            "password": "correct-password",
        },
    )

    original_refresh_token = login_response.json()[
        "refresh_token"
    ]

    first_refresh_response = client.post(
        "/api/v1/auth/refresh",
        json={
            "refresh_token": original_refresh_token,
        },
    )

    assert first_refresh_response.status_code == 200

    reuse_response = client.post(
        "/api/v1/auth/refresh",
        json={
            "refresh_token": original_refresh_token,
        },
    )

    assert reuse_response.status_code == 401

    assert reuse_response.json() == {
        "error": {
            "code": "invalid_refresh_token",
            "message": "The refresh token is invalid or expired.",
        }
    }



def test_mobile_refresh_accepts_rotated_refresh_token(
    client: TestClient,
    db_session: Session,
) -> None:
    """Allow consecutive refreshes using each newly rotated credential."""

    _create_user(
        db_session,
    )

    login_response = client.post(
        "/api/v1/auth/mobile/login",
        json={
            "username": "souocare",
            "password": "correct-password",
        },
    )

    first_refresh = client.post(
        "/api/v1/auth/refresh",
        json={
            "refresh_token": login_response.json()[
                "refresh_token"
            ],
        },
    )

    assert first_refresh.status_code == 200

    second_refresh = client.post(
        "/api/v1/auth/refresh",
        json={
            "refresh_token": first_refresh.json()[
                "refresh_token"
            ],
        },
    )

    assert second_refresh.status_code == 200

    assert second_refresh.json()["refresh_token"] != (
        first_refresh.json()["refresh_token"]
    )

def test_mobile_refresh_rejects_revoked_session(
    client: TestClient,
    db_session: Session,
) -> None:
    """Reject Mobile refresh after its persistent session is revoked."""

    user = _create_user(
        db_session,
    )

    login_response = client.post(
        "/api/v1/auth/mobile/login",
        json={
            "username": "souocare",
            "password": "correct-password",
        },
    )

    refresh_token = login_response.json()[
        "refresh_token"
    ]

    auth_session = db_session.scalar(
        select(AuthSession).where(
            AuthSession.user_id == user.id,
        )
    )

    assert auth_session is not None

    auth_session.revoked_at = datetime.now(UTC)
    db_session.commit()

    response = client.post(
        "/api/v1/auth/refresh",
        json={
            "refresh_token": refresh_token,
        },
    )

    assert response.status_code == 401
    assert response.json()["error"]["code"] == (
        "invalid_refresh_token"
    )


def test_mobile_refresh_rejects_expired_session(
    client: TestClient,
    db_session: Session,
) -> None:
    """Reject a refresh credential belonging to an expired session."""

    user = _create_user(
        db_session,
    )

    login_response = client.post(
        "/api/v1/auth/mobile/login",
        json={
            "username": "souocare",
            "password": "correct-password",
        },
    )

    refresh_token = login_response.json()[
        "refresh_token"
    ]

    auth_session = db_session.scalar(
        select(AuthSession).where(
            AuthSession.user_id == user.id,
        )
    )

    assert auth_session is not None

    auth_session.expires_at = datetime(
        2020,
        1,
        1,
        tzinfo=UTC,
    )

    db_session.commit()

    response = client.post(
        "/api/v1/auth/refresh",
        json={
            "refresh_token": refresh_token,
        },
    )

    assert response.status_code == 401
    assert response.json()["error"]["code"] == (
        "invalid_refresh_token"
    )


def test_mobile_refresh_rejects_inactive_user(
    client: TestClient,
    db_session: Session,
) -> None:
    """Reject refresh when the session owner has been deactivated."""

    user = _create_user(
        db_session,
    )

    login_response = client.post(
        "/api/v1/auth/mobile/login",
        json={
            "username": "souocare",
            "password": "correct-password",
        },
    )

    refresh_token = login_response.json()[
        "refresh_token"
    ]

    user.is_active = False
    db_session.commit()

    response = client.post(
        "/api/v1/auth/refresh",
        json={
            "refresh_token": refresh_token,
        },
    )

    assert response.status_code == 401

    assert response.json() == {
        "error": {
            "code": "invalid_refresh_token",
            "message": "The refresh token is invalid or expired.",
        }
    }

    auth_session = db_session.scalar(
        select(AuthSession).where(
            AuthSession.user_id == user.id,
        )
    )

    assert auth_session is not None
    assert auth_session.revoked_at is not None



def test_mobile_logout_revokes_current_mobile_session(
    client: TestClient,
    db_session: Session,
) -> None:
    """Revoke the Mobile session represented by its refresh token."""

    user = _create_user(
        db_session,
    )

    service = AuthSessionService(
        session=db_session,
        repository=AuthSessionRepository(
            db_session,
        ),
        idle_expire_days=180,
    )

    created_session = service.create(
        user_id=user.id,
        session_type=AuthSessionType.MOBILE,
    )

    response = client.post(
        "/api/v1/auth/mobile/logout",
        json={
            "refresh_token": created_session.credential,
        },
    )

    assert response.status_code == 204

    restored_session = service.resolve(
        created_session.credential,
    )

    assert restored_session is None


def test_mobile_logout_is_idempotent_for_unknown_session(
    client: TestClient,
) -> None:
    """Do not reveal whether a Mobile refresh session exists."""

    response = client.post(
        "/api/v1/auth/mobile/logout",
        json={
            "refresh_token": "unknown-mobile-refresh-token",
        },
    )

    assert response.status_code == 204

def test_create_auth_handoff_requires_authentication(
    unauthenticated_client: TestClient,
) -> None:
    response = unauthenticated_client.post(
        "/api/v1/auth/handoff",
    )

    assert response.status_code == 401

    assert response.json() == {
        "error": {
            "code": "authentication_required",
            "message": "Authentication is required.",
        }
    }

def test_create_auth_handoff_for_authenticated_user(
    client: TestClient,
    db_session: Session,
) -> None:
    _create_user(
        db_session,
    )

    login_response = client.post(
        "/api/v1/auth/mobile/login",
        json={
            "username": "souocare",
            "password": "correct-password",
        },
    )

    assert login_response.status_code == 200

    access_token = login_response.json()["access_token"]

    response = client.post(
        "/api/v1/auth/handoff",
        headers={
            "Authorization": f"Bearer {access_token}",
        },
    )

    assert response.status_code == 200

    payload = response.json()

    assert payload["handoff_token"]
    assert payload["expires_in"] == 2 * 60


def test_create_auth_handoff_does_not_expose_persistent_credentials(
    client: TestClient,
    db_session: Session,
) -> None:
    _create_user(
        db_session,
    )

    login_response = client.post(
        "/api/v1/auth/mobile/login",
        json={
            "username": "souocare",
            "password": "correct-password",
        },
    )

    access_token = login_response.json()["access_token"]

    response = client.post(
        "/api/v1/auth/handoff",
        headers={
            "Authorization": f"Bearer {access_token}",
        },
    )

    payload = response.json()

    assert set(payload) == {
        "handoff_token",
        "expires_in",
    }

    assert "access_token" not in payload
    assert "refresh_token" not in payload


def test_exchange_auth_handoff_creates_web_session(
    client: TestClient,
    db_session: Session,
) -> None:
    _create_user(
        db_session,
    )

    login_response = client.post(
        "/api/v1/auth/mobile/login",
        json={
            "username": "souocare",
            "password": "correct-password",
        },
    )

    access_token = login_response.json()["access_token"]

    handoff_response = client.post(
        "/api/v1/auth/handoff",
        headers={
            "Authorization": f"Bearer {access_token}",
        },
    )

    handoff_token = handoff_response.json()["handoff_token"]

    response = client.post(
        "/api/v1/auth/handoff/exchange",
        json={
            "handoff_token": handoff_token,
        },
    )

    assert response.status_code == 200

    payload = response.json()

    assert payload["token_type"] == "bearer"
    assert payload["expires_in"] == 15 * 60
    assert payload["access_token"]

    assert "sofawatch_session" in response.cookies


def test_auth_handoff_can_only_be_exchanged_once(
    client: TestClient,
    db_session: Session,
) -> None:
    _create_user(
        db_session,
    )

    login_response = client.post(
        "/api/v1/auth/mobile/login",
        json={
            "username": "souocare",
            "password": "correct-password",
        },
    )

    access_token = login_response.json()["access_token"]

    handoff_response = client.post(
        "/api/v1/auth/handoff",
        headers={
            "Authorization": f"Bearer {access_token}",
        },
    )

    handoff_token = handoff_response.json()["handoff_token"]

    first_response = client.post(
        "/api/v1/auth/handoff/exchange",
        json={
            "handoff_token": handoff_token,
        },
    )

    second_response = client.post(
        "/api/v1/auth/handoff/exchange",
        json={
            "handoff_token": handoff_token,
        },
    )

    assert first_response.status_code == 200

    assert second_response.status_code == 401

    assert second_response.json() == {
        "error": {
            "code": "invalid_auth_handoff",
            "message": "The authentication handoff is invalid or expired.",
        }
    }



def test_exchange_rejects_invalid_auth_handoff(
    client: TestClient,
) -> None:
    response = client.post(
        "/api/v1/auth/handoff/exchange",
        json={
            "handoff_token": "invalid-handoff-token",
        },
    )

    assert response.status_code == 401

    assert response.json() == {
        "error": {
            "code": "invalid_auth_handoff",
            "message": "The authentication handoff is invalid or expired.",
        }
    }


