from datetime import UTC, datetime
from unittest.mock import Mock

from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.api.dependencies import (
    get_server_health_service,
)
from app.main import app
from app.models.user import User
from app.schemas.server import (
    ServerDatabaseHealthResponse,
    ServerDatabaseMigrationResponse,
    ServerEnvironmentResponse,
    ServerHealthResponse,
    ServerImageCacheBreakdownResponse,
    ServerImageCacheCategoryResponse,
    ServerImageCacheResponse,
    ServerRuntimeResponse,
    ServerStorageResponse,
    ServerTMDBHealthResponse,
)


def test_get_server_health_requires_admin(
    client: TestClient,
    db_session: Session,
) -> None:
    """Reject Server diagnostics for non-administrator users."""

    user = User(
        display_name="Regular User",
        is_admin=False,
    )

    db_session.add(user)
    db_session.commit()

    response = client.get(
        "/api/v1/server/health",
    )

    assert response.status_code == 403

    payload = response.json()

    assert payload["error"]["code"] == "admin_required"


def test_get_server_health_returns_admin_health_summary(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return detailed Server health to an administrator."""

    user = User(
        display_name="Administrator",
        is_admin=True,
    )

    db_session.add(user)
    db_session.commit()

    service = Mock()

    service.get_health.return_value = ServerHealthResponse(
        status="healthy",
        checked_at=datetime(
            2026,
            8,
            20,
            12,
            0,
            tzinfo=UTC,
        ),
        uptime_seconds=3600,
        environment=ServerEnvironmentResponse(
            app_name="SofaWatch",
            environment="production",
            debug=False,
            api_host="0.0.0.0",
            api_port=8000,
            default_language="en-US",
            supported_languages=[
                "en-US",
                "pt-PT",
            ],
            metadata_refresh_days=7,
        ),
        storage=ServerStorageResponse(
            data_directory="./data",
            writable=True,
            total_space_bytes=1_000_000,
            used_space_bytes=400_000,
            free_space_bytes=600_000,
            usage_percentage=40.0,
            image_cache=ServerImageCacheResponse(
                total_size_bytes=375,
                total_files=4,
                breakdown=ServerImageCacheBreakdownResponse(
                    shows=ServerImageCacheCategoryResponse(
                        size_bytes=300,
                        files=2,
                    ),
                    seasons=ServerImageCacheCategoryResponse(
                        size_bytes=50,
                        files=1,
                    ),
                    episodes=ServerImageCacheCategoryResponse(
                        size_bytes=25,
                        files=1,
                    ),
                ),
            ),
        ),
        runtime=ServerRuntimeResponse(
            python_version="3.12.11",
            platform="Linux",
            started_at=datetime(
                2026,
                8,
                20,
                11,
                0,
                tzinfo=UTC,
            ),
        ),
        database=ServerDatabaseHealthResponse(
            status="healthy",
            engine="sqlite",
            latency_ms=1.25,
            size_bytes=1_048_576,
            wal_size_bytes=8_192,
            integrity_check="ok",
            foreign_key_check="ok",
            migration=ServerDatabaseMigrationResponse(
                revision="bb784a0a2cdc",
                message="add admin flag to users",
            ),
        ),
        tmdb=ServerTMDBHealthResponse(
            status="healthy",
            configured=True,
            latency_ms=212.4,
        ),
    )

    app.dependency_overrides[get_server_health_service] = lambda: service

    try:
        response = client.get(
            "/api/v1/server/health",
        )
    finally:
        app.dependency_overrides.pop(
            get_server_health_service,
            None,
        )

    assert response.status_code == 200

    payload = response.json()

    assert payload["status"] == "healthy"

    assert payload["uptime_seconds"] == 3600

    assert payload["database"] == {
        "status": "healthy",
        "engine": "sqlite",
        "latency_ms": 1.25,
        "size_bytes": 1_048_576,
        "wal_size_bytes": 8_192,
        "integrity_check": "ok",
        "foreign_key_check": "ok",
        "migration": {
            "revision": "bb784a0a2cdc",
            "message": "add admin flag to users",
        },
    }

    assert payload["tmdb"] == {
        "status": "healthy",
        "configured": True,
        "latency_ms": 212.4,
    }

    assert payload["environment"] == {
        "app_name": "SofaWatch",
        "environment": "production",
        "debug": False,
        "api_host": "0.0.0.0",
        "api_port": 8000,
        "default_language": "en-US",
        "supported_languages": [
            "en-US",
            "pt-PT",
        ],
        "metadata_refresh_days": 7,
    }

    assert payload["storage"]["data_directory"] == "./data"
    assert payload["storage"]["writable"] is True

    assert payload["storage"]["total_space_bytes"] == 1_000_000
    assert payload["storage"]["used_space_bytes"] == 400_000
    assert payload["storage"]["free_space_bytes"] == 600_000
    assert payload["storage"]["usage_percentage"] == 40.0

    assert payload["storage"]["image_cache"]["total_size_bytes"] == 375
    assert payload["storage"]["image_cache"]["total_files"] == 4

    assert payload["storage"]["image_cache"]["breakdown"]["shows"]["files"] == 2

    assert payload["runtime"]["python_version"] == "3.12.11"
    assert payload["runtime"]["platform"] == "Linux"
    assert payload["runtime"]["started_at"] == "2026-08-20T11:00:00Z"

    assert datetime.fromisoformat(
        payload["runtime"]["started_at"].replace(
            "Z",
            "+00:00",
        )
    ) == datetime(
        2026,
        8,
        20,
        11,
        0,
        tzinfo=UTC,
    )

    service.get_health.assert_called_once_with()
