from datetime import UTC, datetime, timedelta
from pathlib import Path
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
        data_storage_path="./data",
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

        tmdb_client_class.return_value.__enter__.return_value = tmdb_client

        result = service.get_health()

    assert result.status == "healthy"

    assert result.environment.app_name == "SofaWatch Test"
    assert result.environment.environment == "test"
    assert result.environment.debug is False

    assert result.environment.api_host == "127.0.0.1"
    assert result.environment.api_port == 8000

    assert result.environment.default_language == "en-US"
    assert result.environment.supported_languages == [
        "en-US",
        "pt-PT",
    ]

    assert result.environment.metadata_refresh_days == 7

    assert result.database.status == "healthy"
    assert result.database.engine == "sqlite"
    assert result.database.size_bytes is None
    assert result.database.wal_size_bytes is None
    assert result.database.latency_ms is not None
    assert result.database.latency_ms >= 0

    assert result.storage.data_directory == "./data"

    assert result.storage.total_space_bytes is not None
    assert result.storage.total_space_bytes > 0

    assert result.storage.used_space_bytes is not None
    assert result.storage.free_space_bytes is not None

    assert result.storage.usage_percentage is not None
    assert 0 <= result.storage.usage_percentage <= 100

    assert result.tmdb.status == "healthy"
    assert result.tmdb.configured is True
    assert result.tmdb.latency_ms is not None
    assert result.tmdb.latency_ms >= 0
    assert result.database.integrity_check == "ok"
    assert result.database.foreign_key_check == "ok"

    assert result.runtime.python_version
    assert result.runtime.platform

    assert result.runtime.started_at.tzinfo is not None

    assert abs((result.runtime.started_at - started_at).total_seconds()) < 1

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

        tmdb_client_class.return_value.__enter__.return_value = tmdb_client

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

        tmdb_client_class.return_value.__enter__.return_value = tmdb_client

        result = service.get_health()

    assert result.status == "degraded"

    assert result.database.status == "unavailable"
    assert result.database.engine == "sqlite"
    assert result.database.size_bytes is None
    assert result.database.wal_size_bytes is None
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
        tmdb_client_class.return_value.__enter__.return_value = Mock()

        result = service.get_health()

    assert result.uptime_seconds >= 29
    assert result.uptime_seconds <= 31
    assert result.runtime.started_at.tzinfo is not None
    assert result.runtime.started_at.utcoffset() == timedelta(0)


def test_get_health_reports_sqlite_database_and_wal_sizes(
    db_session: Session,
    server_settings: Settings,
    tmp_path: Path,
) -> None:
    """Report file sizes for a file-backed SQLite database."""

    database_path = tmp_path / "sofawatch.db"
    wal_path = tmp_path / "sofawatch.db-wal"

    database_path.write_bytes(b"d" * 128)
    wal_path.write_bytes(b"w" * 32)

    settings = server_settings.model_copy(
        update={
            "database_url": f"sqlite:///{database_path}",
        },
    )

    service = ServerHealthService(
        session=db_session,
        settings=settings,
        started_at=datetime.now(UTC),
    )

    with patch(
        "app.services.server_health.TMDBClient",
    ) as tmdb_client_class:
        tmdb_client_class.return_value.__enter__.return_value = Mock()

        result = service.get_health()

    assert result.database.status == "healthy"
    assert result.database.engine == "sqlite"
    assert result.database.size_bytes == 128
    assert result.database.wal_size_bytes == 32


def test_get_health_reports_zero_when_sqlite_wal_is_absent(
    db_session: Session,
    server_settings: Settings,
    tmp_path: Path,
) -> None:
    """Report zero WAL bytes when no SQLite WAL file exists."""

    database_path = tmp_path / "sofawatch.db"
    database_path.write_bytes(b"d" * 64)

    settings = server_settings.model_copy(
        update={
            "database_url": f"sqlite:///{database_path}",
        },
    )

    service = ServerHealthService(
        session=db_session,
        settings=settings,
        started_at=datetime.now(UTC),
    )

    with patch(
        "app.services.server_health.TMDBClient",
    ) as tmdb_client_class:
        tmdb_client_class.return_value.__enter__.return_value = Mock()

        result = service.get_health()

    assert result.database.size_bytes == 64
    assert result.database.wal_size_bytes == 0


def test_database_integrity_check_reports_failed_when_sqlite_reports_problem(
    server_settings: Settings,
) -> None:
    """Report a failed integrity check when SQLite finds a problem."""

    session = Mock(spec=Session)
    session.execute.return_value.scalar_one.return_value = "database disk image is malformed"

    service = ServerHealthService(
        session=session,
        settings=server_settings,
        started_at=datetime.now(UTC),
    )

    result = service._check_database_integrity()

    assert result == "failed"


def test_database_integrity_check_reports_unavailable_when_query_fails(
    server_settings: Settings,
) -> None:
    """Report unavailable when the integrity check cannot run."""

    session = Mock(spec=Session)
    session.execute.side_effect = RuntimeError(
        "Integrity check unavailable.",
    )

    service = ServerHealthService(
        session=session,
        settings=server_settings,
        started_at=datetime.now(UTC),
    )

    result = service._check_database_integrity()

    assert result == "unavailable"


def test_database_foreign_key_check_reports_failed_when_violation_exists(
    server_settings: Settings,
) -> None:
    """Report a failed foreign key check when SQLite finds a violation."""

    session = Mock(spec=Session)
    session.execute.return_value.first.return_value = (
        "episodes",
        1,
        "shows",
        0,
    )

    service = ServerHealthService(
        session=session,
        settings=server_settings,
        started_at=datetime.now(UTC),
    )

    result = service._check_database_foreign_keys()

    assert result == "failed"


def test_database_foreign_key_check_reports_unavailable_when_query_fails(
    server_settings: Settings,
) -> None:
    """Report unavailable when the foreign key check cannot run."""

    session = Mock(spec=Session)
    session.execute.side_effect = RuntimeError(
        "Foreign key check unavailable.",
    )

    service = ServerHealthService(
        session=session,
        settings=server_settings,
        started_at=datetime.now(UTC),
    )

    result = service._check_database_foreign_keys()

    assert result == "unavailable"


def test_get_health_is_degraded_when_database_integrity_check_fails(
    db_session: Session,
    server_settings: Settings,
) -> None:
    """Degrade Server health when Database integrity fails."""

    service = ServerHealthService(
        session=db_session,
        settings=server_settings,
        started_at=datetime.now(UTC),
    )

    with (
        patch(
            "app.services.server_health.TMDBClient",
        ) as tmdb_client_class,
        patch.object(
            service,
            "_check_database_integrity",
            return_value="failed",
        ),
    ):
        tmdb_client_class.return_value.__enter__.return_value = Mock()

        result = service.get_health()

    assert result.database.status == "healthy"
    assert result.database.integrity_check == "failed"
    assert result.database.foreign_key_check == "ok"

    assert result.status == "degraded"


def test_database_migration_reports_revision_and_message(
    db_session: Session,
    server_settings: Settings,
) -> None:
    """Report the applied Alembic revision and migration message."""

    service = ServerHealthService(
        session=db_session,
        settings=server_settings,
        started_at=datetime.now(UTC),
    )

    with (
        patch(
            "app.services.server_health.MigrationContext",
        ) as migration_context_class,
        patch(
            "app.services.server_health.ScriptDirectory",
        ) as script_directory_class,
    ):
        migration_context = Mock()
        migration_context.get_current_revision.return_value = "bb784a0a2cdc"
        migration_context_class.configure.return_value = migration_context

        script = Mock()
        script.doc = "add admin flag to users"

        script_directory = Mock()
        script_directory.get_revision.return_value = script
        script_directory_class.from_config.return_value = script_directory

        result = service._database_migration()

    assert result.revision == "bb784a0a2cdc"
    assert result.message == "add admin flag to users"

    script_directory.get_revision.assert_called_once_with(
        "bb784a0a2cdc",
    )


def test_database_migration_reports_empty_state_without_revision(
    db_session: Session,
    server_settings: Settings,
) -> None:
    """Report no migration metadata when the database has no revision."""

    service = ServerHealthService(
        session=db_session,
        settings=server_settings,
        started_at=datetime.now(UTC),
    )

    with patch(
        "app.services.server_health.MigrationContext",
    ) as migration_context_class:
        migration_context = Mock()
        migration_context.get_current_revision.return_value = None
        migration_context_class.configure.return_value = migration_context

        result = service._database_migration()

    assert result.revision is None
    assert result.message is None


def test_database_migration_reports_empty_state_when_lookup_fails(
    db_session: Session,
    server_settings: Settings,
) -> None:
    """Keep Server health safe when migration metadata cannot be read."""

    service = ServerHealthService(
        session=db_session,
        settings=server_settings,
        started_at=datetime.now(UTC),
    )

    with patch(
        "app.services.server_health.MigrationContext.configure",
        side_effect=RuntimeError(
            "Migration metadata unavailable.",
        ),
    ):
        result = service._database_migration()

    assert result.revision is None
    assert result.message is None


def test_get_health_does_not_expose_secrets(
    db_session: Session,
    server_settings: Settings,
) -> None:
    """Never expose application or provider secrets in Server health."""

    settings = server_settings.model_copy(
        update={
            "secret_key": SecretStr(
                "super-secret-application-key",
            ),
            "tmdb_api_token": SecretStr(
                "super-secret-tmdb-token",
            ),
            "tvdb_api_key": SecretStr(
                "super-secret-tvdb-key",
            ),
            "tvdb_pin": SecretStr(
                "super-secret-tvdb-pin",
            ),
        },
    )

    service = ServerHealthService(
        session=db_session,
        settings=settings,
        started_at=datetime.now(UTC),
    )

    with patch(
        "app.services.server_health.TMDBClient",
    ) as tmdb_client_class:
        tmdb_client_class.return_value.__enter__.return_value = Mock()

        result = service.get_health()

    payload = result.model_dump(
        mode="json",
    )

    serialized = str(payload)

    assert "secret_key" not in serialized
    assert "tmdb_api_token" not in serialized
    assert "tvdb_api_key" not in serialized
    assert "tvdb_pin" not in serialized

    assert "super-secret-application-key" not in serialized
    assert "super-secret-tmdb-token" not in serialized
    assert "super-secret-tvdb-key" not in serialized
    assert "super-secret-tvdb-pin" not in serialized


def test_get_health_reports_storage_usage(
    db_session: Session,
    server_settings: Settings,
    tmp_path: Path,
) -> None:
    """Report writable application storage and filesystem usage."""

    settings = server_settings.model_copy(
        update={
            "data_storage_path": str(tmp_path),
            "image_storage_path": str(
                tmp_path / "images",
            ),
        },
    )

    service = ServerHealthService(
        session=db_session,
        settings=settings,
        started_at=datetime.now(UTC),
    )

    with patch(
        "app.services.server_health.TMDBClient",
    ) as tmdb_client_class:
        tmdb_client_class.return_value.__enter__.return_value = Mock()

        result = service.get_health()

    assert result.storage.data_directory == str(tmp_path)
    assert result.storage.writable is True

    assert result.storage.total_space_bytes is not None
    assert result.storage.total_space_bytes > 0

    assert result.storage.used_space_bytes is not None
    assert result.storage.free_space_bytes is not None

    assert result.storage.usage_percentage is not None
    assert 0 <= result.storage.usage_percentage <= 100


def test_get_health_reports_image_cache_usage(
    db_session: Session,
    server_settings: Settings,
    tmp_path: Path,
) -> None:
    """Report image cache totals and category breakdown."""

    image_path = tmp_path / "images"

    show_path = image_path / "shows" / "show-1"
    season_path = image_path / "seasons" / "season-1"
    episode_path = image_path / "episodes" / "episode-1"

    show_path.mkdir(parents=True)
    season_path.mkdir(parents=True)
    episode_path.mkdir(parents=True)

    (show_path / "poster.jpg").write_bytes(
        b"s" * 100,
    )

    (show_path / "backdrop.jpg").write_bytes(
        b"b" * 200,
    )

    (season_path / "poster.jpg").write_bytes(
        b"p" * 50,
    )

    (episode_path / "still.jpg").write_bytes(
        b"e" * 25,
    )

    settings = server_settings.model_copy(
        update={
            "data_storage_path": str(tmp_path),
            "image_storage_path": str(image_path),
        },
    )

    service = ServerHealthService(
        session=db_session,
        settings=settings,
        started_at=datetime.now(UTC),
    )

    with patch(
        "app.services.server_health.TMDBClient",
    ) as tmdb_client_class:
        tmdb_client_class.return_value.__enter__.return_value = Mock()

        result = service.get_health()

    cache = result.storage.image_cache

    assert cache.total_files == 4
    assert cache.total_size_bytes == 375

    assert cache.breakdown.shows.files == 2
    assert cache.breakdown.shows.size_bytes == 300

    assert cache.breakdown.seasons.files == 1
    assert cache.breakdown.seasons.size_bytes == 50

    assert cache.breakdown.episodes.files == 1
    assert cache.breakdown.episodes.size_bytes == 25


def test_get_health_reports_empty_image_cache_without_creating_directory(
    db_session: Session,
    server_settings: Settings,
    tmp_path: Path,
) -> None:
    """Report an empty image cache without modifying storage."""

    image_path = tmp_path / "images"

    settings = server_settings.model_copy(
        update={
            "data_storage_path": str(tmp_path),
            "image_storage_path": str(image_path),
        },
    )

    service = ServerHealthService(
        session=db_session,
        settings=settings,
        started_at=datetime.now(UTC),
    )

    with patch(
        "app.services.server_health.TMDBClient",
    ) as tmdb_client_class:
        tmdb_client_class.return_value.__enter__.return_value = Mock()

        result = service.get_health()

    cache = result.storage.image_cache

    assert cache.total_files == 0
    assert cache.total_size_bytes == 0

    assert cache.breakdown.shows.files == 0
    assert cache.breakdown.seasons.files == 0
    assert cache.breakdown.episodes.files == 0

    assert image_path.exists() is False


def test_get_health_is_degraded_when_data_storage_is_not_writable(
    db_session: Session,
    server_settings: Settings,
    tmp_path: Path,
) -> None:
    """Degrade health when application storage is not writable."""

    settings = server_settings.model_copy(
        update={
            "data_storage_path": str(tmp_path),
            "image_storage_path": str(
                tmp_path / "images",
            ),
        },
    )

    service = ServerHealthService(
        session=db_session,
        settings=settings,
        started_at=datetime.now(UTC),
    )

    with (
        patch(
            "app.services.server_health.TMDBClient",
        ) as tmdb_client_class,
        patch.object(
            service,
            "_storage_path_is_writable",
            return_value=False,
        ),
    ):
        tmdb_client_class.return_value.__enter__.return_value = Mock()

        result = service.get_health()

    assert result.storage.writable is False
    assert result.status == "degraded"
