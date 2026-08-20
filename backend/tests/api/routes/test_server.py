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
    ServerHealthResponse,
    ServerTMDBHealthResponse,
)


def test_get_server_health_requires_admin(
    client: TestClient,
    db_session: Session,
) -> None:
    """Reject Server diagnostics for non-administrator users."""

    user = User(
        display_name="Regular User",
        is_local=True,
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
        is_local=True,
        is_admin=True,
    )

    db_session.add(user)
    db_session.commit()

    service = Mock()

    service.get_health.return_value = (
        ServerHealthResponse(
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
            database=ServerDatabaseHealthResponse(
                status="healthy",
                latency_ms=1.25,
            ),
            tmdb=ServerTMDBHealthResponse(
                status="healthy",
                configured=True,
                latency_ms=212.4,
            ),
        )
    )

    app.dependency_overrides[
        get_server_health_service
    ] = lambda: service

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
        "latency_ms": 1.25,
    }

    assert payload["tmdb"] == {
        "status": "healthy",
        "configured": True,
        "latency_ms": 212.4,
    }

    service.get_health.assert_called_once_with()