from datetime import UTC, datetime
from unittest.mock import Mock

from fastapi.testclient import TestClient
from sqlalchemy.orm import Session
from app.core.security.passwords import hash_password, verify_password

from app.api.dependencies import get_data_export_service
from app.main import app
from app.models.enums import LibraryStatus
from app.models.user import User
from app.schemas.data_export import (
    ExportEpisodeWatchEventResponse,
    ExportLibraryMovieResponse,
    ExportLibraryResponse,
    ExportLibraryShowResponse,
    ExportMovieWatchEventResponse,
    ExportUserResponse,
    ExportWatchHistoryResponse,
    SofaWatchExportResponse,
)
from app.core.security.session_credentials import (
    hash_session_credential,
)
from app.models.password_reset_token import PasswordResetToken


def test_get_current_user_returns_local_user(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return the current local SofaWatch user."""

    user = User(
        display_name="Local User",
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
        "username": None,
        "email": None,
        "display_name": "Local User",
        "is_active": True,
        "is_admin": False,
    }

def test_get_current_user_ignores_non_local_users(
    client: TestClient,
    db_session: Session,
) -> None:
    """Resolve the current user from the local-user marker."""

    local_user = User(
        display_name="Gonçalo",
    )

    other_user = User(
        display_name="Other User",
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
    assert payload["is_admin"] is False



def test_export_current_user_data_downloads_portable_export(
    client: TestClient,
    db_session: Session,
) -> None:
    """Download the current user's portable SofaWatch export."""

    user = User(
        display_name="Gonçalo",
        is_admin=False,
    )

    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)

    service = Mock()

    service.export_user_data.return_value = SofaWatchExportResponse(
        exported_at=datetime(
            2026,
            8,
            20,
            15,
            30,
            45,
            tzinfo=UTC,
        ),
        user=ExportUserResponse(
            display_name="Gonçalo",
        ),
        library=ExportLibraryResponse(
            shows=[
                ExportLibraryShowResponse(
                    tmdb_id=95396,
                    status=LibraryStatus.WATCHING,
                    started_at=datetime(
                        2026,
                        7,
                        1,
                        20,
                        0,
                        tzinfo=UTC,
                    ),
                ),
            ],
            movies=[
                ExportLibraryMovieResponse(
                    tmdb_id=438631,
                    status=LibraryStatus.COMPLETED,
                    completed_at=datetime(
                        2026,
                        8,
                        1,
                        22,
                        30,
                        tzinfo=UTC,
                    ),
                ),
            ],
        ),
        history=ExportWatchHistoryResponse(
            episodes=[
                ExportEpisodeWatchEventResponse(
                    show_tmdb_id=95396,
                    season_number=1,
                    episode_number=1,
                    episode_tmdb_id=2101,
                    watched_at=datetime(
                        2026,
                        8,
                        10,
                        20,
                        0,
                        tzinfo=UTC,
                    ),
                ),
            ],
            movies=[
                ExportMovieWatchEventResponse(
                    movie_tmdb_id=438631,
                    watched_at=datetime(
                        2026,
                        8,
                        1,
                        20,
                        0,
                        tzinfo=UTC,
                    ),
                ),
            ],
        ),
    )

    app.dependency_overrides[
        get_data_export_service
    ] = lambda: service

    try:
        response = client.get(
            "/api/v1/users/me/export",
        )
    finally:
        app.dependency_overrides.pop(
            get_data_export_service,
            None,
        )

    assert response.status_code == 200

    assert response.headers["content-type"].startswith(
        "application/json",
    )

    assert response.headers["content-disposition"] == (
        'attachment; filename="'
        'sofawatch-export-2026-08-20-153045.json"'
    )

    payload = response.json()

    assert payload["format"] == "sofawatch-export"
    assert payload["version"] == 1

    assert payload["user"] == {
        "display_name": "Gonçalo",
    }

    assert payload["library"]["shows"][0]["tmdb_id"] == 95396
    assert payload["library"]["shows"][0]["status"] == "watching"

    assert payload["library"]["movies"][0]["tmdb_id"] == 438631
    assert payload["library"]["movies"][0]["status"] == "completed"

    assert payload["history"]["episodes"][0] == {
        "show_tmdb_id": 95396,
        "season_number": 1,
        "episode_number": 1,
        "episode_tmdb_id": 2101,
        "watched_at": "2026-08-10T20:00:00Z",
    }

    assert payload["history"]["movies"][0] == {
        "movie_tmdb_id": 438631,
        "watched_at": "2026-08-01T20:00:00Z",
    }

    service.export_user_data.assert_called_once_with(
        user=user,
    )


def test_export_current_user_data_does_not_require_admin(
    client: TestClient,
    db_session: Session,
) -> None:
    """Allow the current regular user to export their own data."""

    user = User(
        display_name="Regular User",
        is_admin=False,
    )

    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)

    service = Mock()

    service.export_user_data.return_value = SofaWatchExportResponse(
        exported_at=datetime(
            2026,
            8,
            20,
            15,
            30,
            tzinfo=UTC,
        ),
        user=ExportUserResponse(
            display_name="Regular User",
        ),
        library=ExportLibraryResponse(
            shows=[],
            movies=[],
        ),
        history=ExportWatchHistoryResponse(
            episodes=[],
            movies=[],
        ),
    )

    app.dependency_overrides[
        get_data_export_service
    ] = lambda: service

    try:
        response = client.get(
            "/api/v1/users/me/export",
        )
    finally:
        app.dependency_overrides.pop(
            get_data_export_service,
            None,
        )

    assert response.status_code == 200


def test_preview_current_user_data_import_returns_summary(
    client: TestClient,
    db_session: Session,
) -> None:
    """Validate and summarize a SofaWatch import without modifying data."""

    user = User(
        display_name="Gonçalo",
        is_admin=False,
    )

    db_session.add(user)
    db_session.commit()

    response = client.post(
        "/api/v1/users/me/import/preview",
        json={
            "format": "sofawatch-export",
            "version": 1,
            "exported_at": "2026-08-20T15:30:00Z",
            "user": {
                "display_name": "Gonçalo",
            },
            "library": {
                "shows": [
                    {
                        "tmdb_id": 95396,
                        "status": "watching",
                        "started_at": None,
                        "completed_at": None,
                    },
                ],
                "movies": [
                    {
                        "tmdb_id": 438631,
                        "status": "completed",
                        "started_at": None,
                        "completed_at": "2026-08-01T22:00:00Z",
                    },
                ],
            },
            "history": {
                "episodes": [
                    {
                        "show_tmdb_id": 95396,
                        "season_number": 1,
                        "episode_number": 1,
                        "episode_tmdb_id": 2101,
                        "watched_at": "2026-08-01T20:00:00Z",
                    },
                    {
                        "show_tmdb_id": 95396,
                        "season_number": 1,
                        "episode_number": 1,
                        "episode_tmdb_id": 2101,
                        "watched_at": "2026-08-10T20:00:00Z",
                    },
                ],
                "movies": [
                    {
                        "movie_tmdb_id": 438631,
                        "watched_at": "2026-08-01T22:00:00Z",
                    },
                ],
            },
        },
    )

    assert response.status_code == 200

    assert response.json() == {
        "format": "sofawatch-export",
        "version": 1,
        "user_display_name": "Gonçalo",
        "summary": {
            "library_shows": 1,
            "library_movies": 1,
            "episode_watch_events": 2,
            "movie_watch_events": 1,
        },
    }

def test_preview_current_user_data_import_rejects_unknown_format(
    client: TestClient,
    db_session: Session,
) -> None:
    """Reject files that are not SofaWatch exports."""

    db_session.add(
        User(
            display_name="Gonçalo",
            is_admin=False,
        )
    )
    db_session.commit()

    response = client.post(
        "/api/v1/users/me/import/preview",
        json={
            "format": "other-export",
            "version": 1,
            "exported_at": "2026-08-20T15:30:00Z",
            "user": {
                "display_name": "Gonçalo",
            },
            "library": {
                "shows": [],
                "movies": [],
            },
            "history": {
                "episodes": [],
                "movies": [],
            },
        },
    )

    assert response.status_code == 422
    assert response.json()["error"]["code"] == "validation_error"


def test_preview_current_user_data_import_rejects_unsupported_version(
    client: TestClient,
    db_session: Session,
) -> None:
    """Reject unsupported SofaWatch export versions."""

    db_session.add(
        User(
            display_name="Gonçalo",
            is_admin=False,
        )
    )
    db_session.commit()

    response = client.post(
        "/api/v1/users/me/import/preview",
        json={
            "format": "sofawatch-export",
            "version": 2,
            "exported_at": "2026-08-20T15:30:00Z",
            "user": {
                "display_name": "Gonçalo",
            },
            "library": {
                "shows": [],
                "movies": [],
            },
            "history": {
                "episodes": [],
                "movies": [],
            },
        },
    )

    assert response.status_code == 422
    assert response.json()["error"]["code"] == "validation_error"

def test_import_current_user_data_returns_import_summary(
    client: TestClient,
    db_session: Session,
) -> None:
    """Import portable SofaWatch data for the current user."""

    user = User(
        display_name="Local User",
    )

    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)

    payload = {
        "format": "sofawatch-export",
        "version": 1,
        "exported_at": "2026-08-20T15:30:00Z",
        "user": {
            "display_name": "Local User",
        },
        "library": {
            "shows": [],
            "movies": [],
        },
        "history": {
            "episodes": [],
            "movies": [],
        },
    }

    response = client.post(
        "/api/v1/users/me/import",
        json=payload,
    )

    assert response.status_code == 200

    assert response.json() == {
        "library": {
            "shows": {
                "created": 0,
                "updated": 0,
                "unchanged": 0,
                "failed": 0,
            },
            "movies": {
                "created": 0,
                "updated": 0,
                "unchanged": 0,
                "failed": 0,
            },
        },
        "history": {
            "episodes": {
                "created": 0,
                "skipped": 0,
                "failed": 0,
            },
            "movies": {
                "created": 0,
                "skipped": 0,
                "failed": 0,
            },
        },
    }


def test_import_current_user_data_rejects_invalid_export_version(
    client: TestClient,
    db_session: Session,
) -> None:
    """Reject unsupported SofaWatch export versions."""

    user = User(
        display_name="Local User",
    )

    db_session.add(user)
    db_session.commit()

    payload = {
        "format": "sofawatch-export",
        "version": 2,
        "exported_at": "2026-08-20T15:30:00Z",
        "user": {
            "display_name": "Local User",
        },
        "library": {
            "shows": [],
            "movies": [],
        },
        "history": {
            "episodes": [],
            "movies": [],
        },
    }

    response = client.post(
        "/api/v1/users/me/import",
        json=payload,
    )

    assert response.status_code == 422

def test_current_user_can_update_display_name(
    client: TestClient,
    db_session: Session,
) -> None:
    """Allow a user to update their own display name."""

    user = User(
        username="souocare",
        display_name="Old Display Name",
        is_admin=False,
    )

    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)

    response = client.patch(
        "/api/v1/users/me",
        json={
            "display_name": "Gonçalo",
        },
    )

    assert response.status_code == 200

    assert response.json() == {
        "id": str(user.id),
        "username": "souocare",
        "email": None,
        "display_name": "Gonçalo",
        "is_active": True,
        "is_admin": False,
    }

    db_session.refresh(user)

    assert user.display_name == "Gonçalo"


def test_update_current_user_display_name_trims_whitespace(
    client: TestClient,
    db_session: Session,
) -> None:
    """Normalize surrounding whitespace in the display name."""

    user = User(
        display_name="Old Name",
        is_admin=False,
    )

    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)

    response = client.patch(
        "/api/v1/users/me",
        json={
            "display_name": "   Gonçalo Fonseca   ",
        },
    )

    assert response.status_code == 200

    assert response.json()["display_name"] == "Gonçalo Fonseca"

    db_session.refresh(user)

    assert user.display_name == "Gonçalo Fonseca"


def test_update_current_user_rejects_blank_display_name(
    client: TestClient,
    db_session: Session,
) -> None:
    """Reject a blank display name without changing the user."""

    user = User(
        display_name="Existing Name",
        is_admin=False,
    )

    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)

    response = client.patch(
        "/api/v1/users/me",
        json={
            "display_name": "   ",
        },
    )

    assert response.status_code == 422
    assert response.json()["error"]["code"] == "validation_error"

    db_session.refresh(user)

    assert user.display_name == "Existing Name"



def test_change_current_user_password(
    client: TestClient,
    db_session: Session,
) -> None:
    user = User(
        username="souocare",
        display_name="Gonçalo",
        password_hash=hash_password("current-password"),
    )

    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)

    response = client.put(
        "/api/v1/users/me/password",
        json={
            "current_password": "current-password",
            "new_password": "new-password",
        },
    )

    assert response.status_code == 204
    assert response.content == b""

    db_session.refresh(user)

    assert verify_password(
        "new-password",
        user.password_hash,
    )

    assert not verify_password(
        "current-password",
        user.password_hash,
    )



def test_change_current_user_password_rejects_wrong_current_password(
    client: TestClient,
    db_session: Session,
) -> None:
    user = User(
        username="souocare",
        display_name="Gonçalo",
        password_hash=hash_password("current-password"),
    )

    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)

    response = client.put(
        "/api/v1/users/me/password",
        json={
            "current_password": "wrong-password",
            "new_password": "new-password",
        },
    )

    assert response.status_code == 400

    assert response.json() == {
        "error": {
            "code": "current_password_invalid",
            "message": "The current password is incorrect.",
        }
    }

    db_session.refresh(user)

    assert verify_password(
        "current-password",
        user.password_hash,
    )


def test_change_current_user_password_rejects_short_new_password(
    client: TestClient,
    db_session: Session,
) -> None:
    user = User(
        username="souocare",
        display_name="Gonçalo",
        password_hash=hash_password("current-password"),
    )

    db_session.add(user)
    db_session.commit()

    response = client.put(
        "/api/v1/users/me/password",
        json={
            "current_password": "current-password",
            "new_password": "short",
        },
    )

    assert response.status_code == 422
    assert response.json()["error"]["code"] == "validation_error"



def test_admin_can_start_regular_user_password_recovery(
    client: TestClient,
    db_session: Session,
) -> None:
    admin = User(
        username="administrator",
        display_name="Administrator",
        is_active=True,
        is_admin=True,
    )

    user = User(
        username="regular-user",
        display_name="Regular User",
        is_active=True,
        is_admin=False,
    )

    db_session.add_all([admin, user])
    db_session.commit()
    db_session.refresh(user)

    response = client.post(
        f"/api/v1/users/{user.id}/password-recovery",
    )

    assert response.status_code == 200

    payload = response.json()

    assert payload["token"]
    assert payload["expires_at"]

    reset_token = db_session.query(
        PasswordResetToken,
    ).one()

    assert reset_token.user_id == user.id

    assert reset_token.credential_hash == hash_session_credential(
        payload["token"],
    )

    assert reset_token.credential_hash != payload["token"]


def test_regular_user_cannot_start_password_recovery(
    client: TestClient,
    db_session: Session,
) -> None:
    regular_user = User(
        username="requesting-user",
        display_name="Requesting User",
        is_active=True,
        is_admin=False,
    )

    target = User(
        username="target-user",
        display_name="Target User",
        is_active=True,
        is_admin=False,
    )

    db_session.add_all([regular_user, target])
    db_session.commit()
    db_session.refresh(target)

    response = client.post(
        f"/api/v1/users/{target.id}/password-recovery",
    )

    assert response.status_code == 403

    assert response.json()["error"]["code"] == "admin_required"


def test_admin_password_recovery_rejects_missing_user(
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
    db_session.commit()

    response = client.post(
        "/api/v1/users/"
        "11111111-2222-3333-4444-555555555555"
        "/password-recovery",
    )

    assert response.status_code == 404

    assert response.json()["error"]["code"] == "user_not_found"


def test_admin_cannot_start_web_password_recovery_for_administrator(
    client: TestClient,
    db_session: Session,
) -> None:
    admin = User(
        username="administrator",
        display_name="Administrator",
        is_active=True,
        is_admin=True,
    )

    second_admin = User(
        username="second-admin",
        display_name="Second Administrator",
        is_active=True,
        is_admin=True,
    )

    db_session.add_all([admin, second_admin])
    db_session.commit()
    db_session.refresh(second_admin)

    response = client.post(
        f"/api/v1/users/{second_admin.id}/password-recovery",
    )

    assert response.status_code == 400

    assert response.json()["error"]["code"] == (
        "administrator_password_recovery_unavailable"
    )


def test_admin_cannot_start_password_recovery_for_inactive_user(
    client: TestClient,
    db_session: Session,
) -> None:
    admin = User(
        username="administrator",
        display_name="Administrator",
        is_active=True,
        is_admin=True,
    )

    user = User(
        username="inactive-user",
        display_name="Inactive User",
        is_active=False,
        is_admin=False,
    )

    db_session.add_all([admin, user])
    db_session.commit()
    db_session.refresh(user)

    response = client.post(
        f"/api/v1/users/{user.id}/password-recovery",
    )

    assert response.status_code == 400

    assert response.json()["error"]["code"] == (
        "inactive_user_password_recovery_unavailable"
    )

def test_admin_can_list_users(
    client: TestClient,
    db_session: Session,
) -> None:
    admin = User(
        username="administrator",
        email="admin@example.com",
        display_name="Administrator",
        is_active=True,
        is_admin=True,
    )

    regular_user = User(
        username="regular-user",
        email="regular@example.com",
        display_name="Regular User",
        is_active=True,
        is_admin=False,
    )

    inactive_user = User(
        username="inactive-user",
        email=None,
        display_name="Inactive User",
        is_active=False,
        is_admin=False,
    )

    db_session.add_all(
        [
            admin,
            regular_user,
            inactive_user,
        ]
    )
    db_session.commit()

    response = client.get(
        "/api/v1/users",
    )

    assert response.status_code == 200

    payload = response.json()

    assert payload == [
        {
            "id": str(admin.id),
            "username": "administrator",
            "email": "admin@example.com",
            "display_name": "Administrator",
            "is_active": True,
            "is_admin": True,
        },
        {
            "id": str(inactive_user.id),
            "username": "inactive-user",
            "email": None,
            "display_name": "Inactive User",
            "is_active": False,
            "is_admin": False,
        },
        {
            "id": str(regular_user.id),
            "username": "regular-user",
            "email": "regular@example.com",
            "display_name": "Regular User",
            "is_active": True,
            "is_admin": False,
        },
    ]


def test_regular_user_cannot_list_users(
    client: TestClient,
    db_session: Session,
) -> None:
    user = User(
        username="regular-user",
        display_name="Regular User",
        is_active=True,
        is_admin=False,
    )

    db_session.add(user)
    db_session.commit()

    response = client.get(
        "/api/v1/users",
    )

    assert response.status_code == 403

    assert response.json()["error"]["code"] == "admin_required"

def test_admin_user_list_does_not_expose_sensitive_fields(
    client: TestClient,
    db_session: Session,
) -> None:
    admin = User(
        username="administrator",
        display_name="Administrator",
        password_hash="sensitive-password-hash",
        is_active=True,
        is_admin=True,
    )

    db_session.add(admin)
    db_session.commit()

    response = client.get(
        "/api/v1/users",
    )

    assert response.status_code == 200

    payload = response.json()

    assert len(payload) == 1

    assert "password_hash" not in payload[0]
    assert "auth_sessions" not in payload[0]