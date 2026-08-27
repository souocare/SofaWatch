import os
import platform
import shutil
from datetime import UTC, datetime
from pathlib import Path
from time import perf_counter

from alembic.config import Config
from alembic.migration import MigrationContext
from alembic.script import ScriptDirectory
from sqlalchemy import text
from sqlalchemy.engine import make_url
from sqlalchemy.orm import Session

from app.core.config import BACKEND_DIR, Settings
from app.providers.tmdb.client import TMDBClient
from app.providers.tmdb.exceptions import (
    TMDBConfigurationError,
    TMDBRequestError,
    TMDBResponseError,
)
from app.schemas.server import (
    ServerDatabaseCheckStatus,
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


class ServerHealthService:
    """Build the administrative operational health summary."""

    def __init__(
        self,
        *,
        session: Session,
        settings: Settings,
        started_at: datetime,
    ) -> None:
        self._session = session
        self._settings = settings
        self._started_at = started_at

    def get_health(self) -> ServerHealthResponse:
        """Return the current operational state of SofaWatch dependencies."""

        checked_at = datetime.now(UTC)
        environment = self._environment()
        storage = self._storage()
        runtime = self._runtime()

        database = self._check_database()
        tmdb = self._check_tmdb()

        status = (
            "healthy"
            if (
                database.status == "healthy"
                and database.integrity_check == "ok"
                and database.foreign_key_check == "ok"
                and storage.writable
                and tmdb.status == "healthy"
            )
            else "degraded"
        )

        uptime_seconds = max(
            0,
            int((checked_at - self._normalized_started_at()).total_seconds()),
        )

        return ServerHealthResponse(
            status=status,
            checked_at=checked_at,
            uptime_seconds=uptime_seconds,
            environment=environment,
            storage=storage,
            runtime=runtime,
            database=database,
            tmdb=tmdb,
        )

    def _check_database(
        self,
    ) -> ServerDatabaseHealthResponse:
        engine = self._database_engine()
        size_bytes, wal_size_bytes = self._database_file_sizes()
        migration = self._database_migration()

        started = perf_counter()

        try:
            self._session.execute(
                text("SELECT 1"),
            ).scalar_one()

        except Exception:
            return ServerDatabaseHealthResponse(
                status="unavailable",
                engine=engine,
                latency_ms=None,
                size_bytes=size_bytes,
                wal_size_bytes=wal_size_bytes,
                integrity_check="unavailable",
                foreign_key_check="unavailable",
                migration=migration,
            )

        latency_ms = self._elapsed_milliseconds(started)

        return ServerDatabaseHealthResponse(
            status="healthy",
            engine=engine,
            latency_ms=latency_ms,
            size_bytes=size_bytes,
            wal_size_bytes=wal_size_bytes,
            integrity_check=self._check_database_integrity(),
            foreign_key_check=self._check_database_foreign_keys(),
            migration=migration,
        )

    def _database_engine(self) -> str:
        return make_url(
            self._settings.database_url,
        ).get_backend_name()

    def _database_file_sizes(
        self,
    ) -> tuple[int | None, int | None]:
        database_url = make_url(
            self._settings.database_url,
        )

        if database_url.get_backend_name() != "sqlite":
            return None, None

        database = database_url.database

        if database is None or database == ":memory:":
            return None, None

        database_path = Path(database)

        try:
            size_bytes = database_path.stat().st_size if database_path.is_file() else None

            wal_path = Path(f"{database_path}-wal")

            wal_size_bytes = wal_path.stat().st_size if wal_path.is_file() else 0
        except OSError:
            return None, None

        return size_bytes, wal_size_bytes

    def _check_database_integrity(
        self,
    ) -> ServerDatabaseCheckStatus:
        try:
            result = self._session.execute(
                text("PRAGMA integrity_check"),
            ).scalar_one()

        except Exception:
            return "unavailable"

        return "ok" if result == "ok" else "failed"

    def _check_database_foreign_keys(
        self,
    ) -> ServerDatabaseCheckStatus:
        try:
            violation = self._session.execute(
                text("PRAGMA foreign_key_check"),
            ).first()

        except Exception:
            return "unavailable"

        return "ok" if violation is None else "failed"

    def _check_tmdb(
        self,
    ) -> ServerTMDBHealthResponse:
        if self._settings.tmdb_api_token is None:
            return ServerTMDBHealthResponse(
                status="unavailable",
                configured=False,
                latency_ms=None,
            )

        started = perf_counter()

        try:
            with TMDBClient(
                settings=self._settings,
            ) as client:
                client.check_health()

        except (
            TMDBConfigurationError,
            TMDBRequestError,
            TMDBResponseError,
        ):
            return ServerTMDBHealthResponse(
                status="unavailable",
                configured=True,
                latency_ms=None,
            )

        return ServerTMDBHealthResponse(
            status="healthy",
            configured=True,
            latency_ms=self._elapsed_milliseconds(started),
        )

    def _environment(
        self,
    ) -> ServerEnvironmentResponse:
        return ServerEnvironmentResponse(
            app_name=self._settings.app_name,
            environment=self._settings.environment,
            debug=self._settings.debug,
            api_host=self._settings.api_host,
            api_port=self._settings.api_port,
            default_language=self._settings.default_language,
            supported_languages=self._settings.supported_language_list,
            metadata_refresh_days=self._settings.metadata_refresh_days,
        )

    def _runtime(
        self,
    ) -> ServerRuntimeResponse:
        return ServerRuntimeResponse(
            python_version=platform.python_version(),
            platform=platform.system(),
            started_at=self._normalized_started_at(),
        )

    def _storage(
        self,
    ) -> ServerStorageResponse:
        data_path = Path(
            self._settings.data_storage_path,
        ).resolve()

        writable = self._storage_path_is_writable(
            data_path,
        )

        (
            total_space_bytes,
            used_space_bytes,
            free_space_bytes,
            usage_percentage,
        ) = self._disk_usage(data_path)

        return ServerStorageResponse(
            data_directory=self._settings.data_storage_path,
            writable=writable,
            total_space_bytes=total_space_bytes,
            used_space_bytes=used_space_bytes,
            free_space_bytes=free_space_bytes,
            usage_percentage=usage_percentage,
            image_cache=self._image_cache_usage(),
        )

    def _database_migration(
        self,
    ) -> ServerDatabaseMigrationResponse:
        try:
            connection = self._session.connection()

            migration_context = MigrationContext.configure(
                connection,
            )

            revision = migration_context.get_current_revision()

            if revision is None:
                return ServerDatabaseMigrationResponse()

            alembic_config = Config(
                str(BACKEND_DIR / "alembic.ini"),
            )

            script_directory = ScriptDirectory.from_config(
                alembic_config,
            )

            script = script_directory.get_revision(
                revision,
            )

            return ServerDatabaseMigrationResponse(
                revision=revision,
                message=script.doc,
            )

        except Exception:
            return ServerDatabaseMigrationResponse()

    def _tmdb_client(
        self,
    ) -> "_TMDBClientContext":
        return _TMDBClientContext(
            settings=self._settings,
        )

    def _normalized_started_at(self) -> datetime:
        if self._started_at.tzinfo is None:
            return self._started_at.replace(
                tzinfo=UTC,
            )

        return self._started_at.astimezone(UTC)

    @staticmethod
    def _elapsed_milliseconds(
        started: float,
    ) -> float:
        return round(
            (perf_counter() - started) * 1000,
            2,
        )

    @staticmethod
    def _storage_path_is_writable(
        path: Path,
    ) -> bool:
        probe_path = ServerHealthService._existing_storage_path(
            path,
        )

        return os.access(
            probe_path,
            os.W_OK,
        )

    @staticmethod
    def _existing_storage_path(
        path: Path,
    ) -> Path:
        current = path

        while not current.exists():
            parent = current.parent

            if parent == current:
                return current

            current = parent

        return current

    @staticmethod
    def _disk_usage(
        path: Path,
    ) -> tuple[
        int | None,
        int | None,
        int | None,
        float | None,
    ]:
        probe_path = ServerHealthService._existing_storage_path(
            path,
        )

        try:
            usage = shutil.disk_usage(
                probe_path,
            )
        except OSError:
            return None, None, None, None

        usage_percentage = (
            0.0
            if usage.total == 0
            else round(
                (usage.used / usage.total) * 100,
                2,
            )
        )

        return (
            usage.total,
            usage.used,
            usage.free,
            usage_percentage,
        )

    @staticmethod
    def _image_cache_category_usage(
        path: Path,
    ) -> ServerImageCacheCategoryResponse:
        if not path.is_dir():
            return ServerImageCacheCategoryResponse(
                size_bytes=0,
                files=0,
            )

        size_bytes = 0
        files = 0

        try:
            for candidate in path.rglob("*"):
                if not candidate.is_file():
                    continue

                size_bytes += candidate.stat().st_size
                files += 1

        except OSError:
            return ServerImageCacheCategoryResponse(
                size_bytes=0,
                files=0,
            )

        return ServerImageCacheCategoryResponse(
            size_bytes=size_bytes,
            files=files,
        )

    def _image_cache_usage(
        self,
    ) -> ServerImageCacheResponse:
        base_path = Path(
            self._settings.image_storage_path,
        ).resolve()

        shows = self._image_cache_category_usage(
            base_path / "shows",
        )
        seasons = self._image_cache_category_usage(
            base_path / "seasons",
        )
        episodes = self._image_cache_category_usage(
            base_path / "episodes",
        )

        return ServerImageCacheResponse(
            total_size_bytes=(shows.size_bytes + seasons.size_bytes + episodes.size_bytes),
            total_files=(shows.files + seasons.files + episodes.files),
            breakdown=ServerImageCacheBreakdownResponse(
                shows=shows,
                seasons=seasons,
                episodes=episodes,
            ),
        )


class _TMDBClientContext:
    """Own a short-lived TMDB client used only by a health check."""

    def __init__(
        self,
        *,
        settings: Settings,
    ) -> None:
        self._client = TMDBClient(
            settings=settings,
        )

    def __enter__(self) -> TMDBClient:
        return self._client

    def __exit__(
        self,
        exc_type,
        exc_value,
        traceback,
    ) -> None:
        self._client.close()
