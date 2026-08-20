from datetime import UTC, datetime, timedelta
from unittest.mock import Mock, patch

import pytest
from pydantic import SecretStr
from sqlalchemy.orm import Session

from app.core.config import Settings
from app.providers.tmdb.exceptions import (
    TMDBRequestError,
)
from app.services.server_health import ServerHealthService


@pytest.fixture
def server_settings() -> Settings:
    """Provide settings suitable for Server health tests."""

    return Settings.model_construct(
        app_name="SofaWatch Test",
        environment="test",
        debug=False,
        api_host="127.0.0.1",
        api_port=8000,
        database_url="sqlite://",
        image_storage_path="./data/images",
        secret_key=SecretStr("test-secret-key"),
        default_language="en-US",
        supported_languages="en-US,pt-PT",
        tmdb_api_token=SecretStr("test-tmdb-token"),
        tmdb_base_url="https://api.themoviedb.org/3",
        tmdb_image_base_url="https://image.tmdb.org/t/p",
        tmdb_timeout_seconds=10.0,
        tvdb_api_key=None,
        tvdb_pin=None,
        tvdb_base_url="https://api4.thetvdb.com/v4",
        metadata_refresh_days=7,
        cors_origins="",
    )


def test_get_health_returns_healthy_when_dependencies_are_available(
    db_session: Session,
    server_settings: Settings,
) -> None:
    """Return healthy when Database and TMDB checks succeed."""

    started_at = datetime.now(UTC) - timedelta(
        minutes=5,
    )

    service = ServerHealthService(
        session=db_session,
        settings=server_settings,
        started_at=started_at,
    )

    with patch(
        "app.services.server_health.TMDBClient",
    ) as tmdb_client_class:
        tmdb_client = Mock()

        tmdb_client_class.return_value.__enter__.return_value = (
            tmdb_client
        )

        result = service.get_health()

    assert result.status == "healthy"

    assert result.database.status == "healthy"
    assert result.database.latency_ms is not None
    assert result.database.latency_ms >= 0

    assert result.tmdb.status == "healthy"
    assert result.tmdb.configured is True
    assert result.tmdb.latency_ms is not None
    assert result.tmdb.latency_ms >= 0

    assert result.uptime_seconds >= 299
    assert result.uptime_seconds <= 301

    assert result.checked_at.tzinfo is not None

    tmdb_client.check_health.assert_called_once_with()


def test_get_health_reports_unconfigured_tmdb(
    db_session: Session,
    server_settings: Settings,
) -> None:
    """Report TMDB unavailable when no API token is configured."""

    settings = server_settings.model_copy(
        update={
            "tmdb_api_token": None,
        },
    )

    service = ServerHealthService(
        session=db_session,
        settings=settings,
        started_at=datetime.now(UTC),
    )

    result = service.get_health()

    assert result.status == "degraded"

    assert result.database.status == "healthy"

    assert result.tmdb.status == "unavailable"
    assert result.tmdb.configured is False
    assert result.tmdb.latency_ms is None


def test_get_health_reports_tmdb_connectivity_failure(
    db_session: Session,
    server_settings: Settings,
) -> None:
    """Report a reachable Server with unavailable TMDB."""

    service = ServerHealthService(
        session=db_session,
        settings=server_settings,
        started_at=datetime.now(UTC),
    )

    with patch(
        "app.services.server_health.TMDBClient",
    ) as tmdb_client_class:
        tmdb_client = Mock()

        tmdb_client.check_health.side_effect = TMDBRequestError(
            "TMDB could not be reached.",
        )

        tmdb_client_class.return_value.__enter__.return_value = (
            tmdb_client
        )

        result = service.get_health()

    assert result.status == "degraded"

    assert result.database.status == "healthy"

    assert result.tmdb.status == "unavailable"
    assert result.tmdb.configured is True
    assert result.tmdb.latency_ms is None


def test_get_health_reports_database_failure(
    db_session: Session,
    server_settings: Settings,
) -> None:
    """Report degraded health when the Database check fails."""

    session = Mock(spec=Session)

    session.execute.side_effect = RuntimeError(
        "Database unavailable.",
    )

    service = ServerHealthService(
        session=session,
        settings=server_settings,
        started_at=datetime.now(UTC),
    )

    with patch(
        "app.services.server_health.TMDBClient",
    ) as tmdb_client_class:
        tmdb_client = Mock()

        tmdb_client_class.return_value.__enter__.return_value = (
            tmdb_client
        )

        result = service.get_health()

    assert result.status == "degraded"

    assert result.database.status == "unavailable"
    assert result.database.latency_ms is None

    assert result.tmdb.status == "healthy"


def test_get_health_supports_naive_start_timestamp(
    db_session: Session,
    server_settings: Settings,
) -> None:
    """Normalize a naive application start timestamp to UTC."""

    started_at = datetime.now(UTC).replace(
        tzinfo=None,
    ) - timedelta(
        seconds=30,
    )

    service = ServerHealthService(
        session=db_session,
        settings=server_settings,
        started_at=started_at,
    )

    with patch(
        "app.services.server_health.TMDBClient",
    ) as tmdb_client_class:
        tmdb_client_class.return_value.__enter__.return_value = (
            Mock()
        )

        result = service.get_health()

    assert result.uptime_seconds >= 29
    assert result.uptime_seconds <= 31