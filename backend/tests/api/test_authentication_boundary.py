
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.core.security.passwords import hash_password
from app.models.user import User
from app.models.auth_session import AuthSessionType
from app.repositories.auth_session import AuthSessionRepository
from app.services.auth_session import AuthSessionService


def test_auth_setup_is_public(
    client: TestClient,
) -> None:
    response = client.get(
        "/api/v1/auth/setup",
    )

    assert response.status_code == 200


def test_login_endpoint_is_public(
    client: TestClient,
) -> None:
    response = client.post(
        "/api/v1/auth/login",
        json={
            "username": "missing-user",
            "password": "invalid-password",
        },
    )

    # The request reached the authentication endpoint.
    # Invalid credentials are different from missing authentication.
    assert response.status_code == 401
    assert response.json()["error"]["code"] == "invalid_credentials"


def test_genres_require_authentication(
    unauthenticated_client: TestClient,
) -> None:
    response = unauthenticated_client.get(
        "/api/v1/genres/",
    )

    assert response.status_code == 401
    assert response.json()["error"]["code"] == "authentication_required"


def test_movie_details_require_authentication(
    unauthenticated_client: TestClient,
) -> None:
    response = unauthenticated_client.get(
        "/api/v1/movies/tmdb/438631",
    )

    assert response.status_code == 401
    assert response.json()["error"]["code"] == "authentication_required"


def test_cached_images_require_authentication(
    unauthenticated_client: TestClient,
) -> None:
    response = unauthenticated_client.get(
        "/api/v1/images/shows/00000000-0000-0000-0000-000000000001/poster",
    )

    assert response.status_code == 401
    assert response.json()["error"]["code"] == "authentication_required"

def test_private_endpoint_with_explicit_current_user_still_requires_authentication(
    unauthenticated_client: TestClient,
) -> None:
    response = unauthenticated_client.get(
        "/api/v1/statistics/summary",
    )

    assert response.status_code == 401
    assert response.json()["error"]["code"] == "authentication_required"

def test_private_endpoint_accepts_web_session_cookie(
    unauthenticated_client: TestClient,
    db_session: Session,
) -> None:
    """Authenticate private endpoints using the persistent Web session."""

    user = User(
        username="web-user",
        display_name="Web User",
        password_hash=hash_password(
            "correct-password",
        ),
        is_active=True,
        is_local=False,
    )

    db_session.add(user)
    db_session.commit()

    login_response = unauthenticated_client.post(
        "/api/v1/auth/login",
        json={
            "username": "web-user",
            "password": "correct-password",
        },
    )

    assert login_response.status_code == 200

    response = unauthenticated_client.get(
        "/api/v1/statistics/summary",
    )

    assert response.status_code == 200


def test_private_endpoint_rejects_invalid_web_session_cookie(
    unauthenticated_client: TestClient,
) -> None:
    """Reject an invalid persistent Web authentication session."""

    unauthenticated_client.cookies.set(
        "sofawatch_session",
        "invalid-session",
    )

    response = unauthenticated_client.get(
        "/api/v1/statistics/summary",
    )

    assert response.status_code == 401

    assert response.json() == {
        "error": {
            "code": "invalid_session",
            "message": "The authentication session is invalid or expired.",
        }
    }


def test_bearer_authentication_takes_precedence_over_web_session(
    unauthenticated_client: TestClient,
    db_session: Session,
) -> None:
    """Do not hide an invalid Bearer token behind a valid Web session."""

    user = User(
        username="web-user",
        display_name="Web User",
        password_hash=hash_password(
            "correct-password",
        ),
        is_active=True,
        is_local=False,
    )

    db_session.add(user)
    db_session.commit()

    login_response = unauthenticated_client.post(
        "/api/v1/auth/login",
        json={
            "username": "web-user",
            "password": "correct-password",
        },
    )

    assert login_response.status_code == 200

    response = unauthenticated_client.get(
        "/api/v1/statistics/summary",
        headers={
            "Authorization": "Bearer invalid-access-token",
        },
    )

    assert response.status_code == 401

    assert response.json() == {
        "error": {
            "code": "invalid_access_token",
            "message": "The access token is invalid or expired.",
        }
    }

def test_mobile_session_credential_is_not_accepted_as_web_cookie(
    unauthenticated_client: TestClient,
    db_session: Session,
) -> None:
    """Do not authenticate a Web request using a Mobile session credential."""

    user = User(
        username="mobile-user",
        display_name="Mobile User",
        is_active=True,
        is_local=False,
    )

    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)

    session_service = AuthSessionService(
        session=db_session,
        repository=AuthSessionRepository(
            db_session,
        ),
        idle_expire_days=180,
    )

    mobile_session = session_service.create(
        user_id=user.id,
        session_type=AuthSessionType.MOBILE,
    )

    unauthenticated_client.cookies.set(
        "sofawatch_session",
        mobile_session.credential,
    )

    response = unauthenticated_client.get(
        "/api/v1/statistics/summary",
    )

    assert response.status_code == 401

    assert response.json()["error"]["code"] == "invalid_session"

