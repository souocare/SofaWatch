from datetime import UTC, datetime
from unittest.mock import Mock

from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

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
        "username": None,
        "email": None,
        "display_name": "Local User",
        "is_active": True,
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

def test_export_current_user_data_downloads_portable_export(
    client: TestClient,
    db_session: Session,
) -> None:
    """Download the current user's portable SofaWatch export."""

    user = User(
        display_name="Gonçalo",
        is_local=True,
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
        is_local=True,
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
        is_local=True,
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
            is_local=True,
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
            is_local=True,
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
        is_local=True,
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
        is_local=True,
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