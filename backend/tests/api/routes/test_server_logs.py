from datetime import UTC, datetime
from unittest.mock import Mock

import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.api.dependencies import (
    get_server_logs_service,
)
from app.main import app
from app.models.user import User
from app.schemas.server import (
    ServerLogEntryResponse,
    ServerLogsResponse,
)


def create_local_user(
    db_session: Session,
    *,
    is_admin: bool,
) -> User:
    """Create the local user used by Server Logs authorization tests."""

    user = User(
        display_name=("Administrator" if is_admin else "Regular User"),
        is_admin=is_admin,
    )

    db_session.add(
        user,
    )
    db_session.commit()
    db_session.refresh(
        user,
    )

    return user


def test_get_server_logs_requires_admin(
    client: TestClient,
    db_session: Session,
) -> None:
    """Reject Server Logs access for non-administrator users."""

    create_local_user(
        db_session,
        is_admin=False,
    )

    response = client.get(
        "/api/v1/server/logs",
    )

    assert response.status_code == 403

    assert response.json() == {
        "error": {
            "code": "admin_required",
            "message": "Administrator access is required.",
        }
    }


def test_get_server_logs_returns_paginated_logs(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return recent safe Server logs to an administrator."""

    create_local_user(
        db_session,
        is_admin=True,
    )

    service = Mock()

    service.list_logs.return_value = ServerLogsResponse(
        items=[
            ServerLogEntryResponse(
                timestamp=datetime(
                    2026,
                    8,
                    20,
                    15,
                    30,
                    tzinfo=UTC,
                ),
                level="ERROR",
                logger="app.jobs.executor",
                message="Metadata sync failed.",
                component="worker",
            ),
            ServerLogEntryResponse(
                timestamp=datetime(
                    2026,
                    8,
                    20,
                    15,
                    0,
                    tzinfo=UTC,
                ),
                level="INFO",
                logger="app.main",
                message="SofaWatch API starting",
                component="api",
            ),
        ],
        offset=0,
        limit=50,
        total=2,
        has_next=False,
    )

    app.dependency_overrides[get_server_logs_service] = lambda: service

    try:
        response = client.get(
            "/api/v1/server/logs",
        )
    finally:
        app.dependency_overrides.pop(
            get_server_logs_service,
            None,
        )

    assert response.status_code == 200

    payload = response.json()

    assert payload == {
        "items": [
            {
                "timestamp": "2026-08-20T15:30:00Z",
                "level": "ERROR",
                "logger": "app.jobs.executor",
                "message": "Metadata sync failed.",
                "component": "worker",
            },
            {
                "timestamp": "2026-08-20T15:00:00Z",
                "level": "INFO",
                "logger": "app.main",
                "message": "SofaWatch API starting",
                "component": "api",
            },
        ],
        "offset": 0,
        "limit": 50,
        "total": 2,
        "has_next": False,
    }

    service.list_logs.assert_called_once_with(
        level=None,
        offset=0,
        limit=50,
    )


def test_get_server_logs_passes_level_and_pagination(
    client: TestClient,
    db_session: Session,
) -> None:
    """Pass log filters and pagination parameters to the service."""

    create_local_user(
        db_session,
        is_admin=True,
    )

    service = Mock()

    service.list_logs.return_value = ServerLogsResponse(
        items=[],
        offset=25,
        limit=25,
        total=100,
        has_next=True,
    )

    app.dependency_overrides[get_server_logs_service] = lambda: service

    try:
        response = client.get(
            "/api/v1/server/logs",
            params={
                "level": "WARNING",
                "offset": 25,
                "limit": 25,
            },
        )
    finally:
        app.dependency_overrides.pop(
            get_server_logs_service,
            None,
        )

    assert response.status_code == 200

    assert response.json() == {
        "items": [],
        "offset": 25,
        "limit": 25,
        "total": 100,
        "has_next": True,
    }

    service.list_logs.assert_called_once_with(
        level="WARNING",
        offset=25,
        limit=25,
    )


@pytest.mark.parametrize(
    (
        "params",
        "expected_location",
    ),
    [
        (
            {
                "level": "BROKEN",
            },
            "level",
        ),
        (
            {
                "offset": -1,
            },
            "offset",
        ),
        (
            {
                "limit": 0,
            },
            "limit",
        ),
        (
            {
                "limit": 201,
            },
            "limit",
        ),
    ],
)
def test_get_server_logs_rejects_invalid_query_parameters(
    client: TestClient,
    db_session: Session,
    params: dict[str, str | int],
    expected_location: str,
) -> None:
    """Reject unsupported Server Logs query parameters."""

    create_local_user(
        db_session,
        is_admin=True,
    )

    response = client.get(
        "/api/v1/server/logs",
        params=params,
    )

    assert response.status_code == 422

    payload = response.json()

    assert payload["error"]["code"] == "validation_error"
    assert payload["error"]["message"] == "The request contains invalid data."

    errors = payload["error"]["details"]

    assert any(detail["field"] == expected_location for detail in errors)
