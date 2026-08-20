from datetime import UTC, datetime
from time import perf_counter

from sqlalchemy import text
from sqlalchemy.orm import Session

from app.core.config import Settings
from app.providers.tmdb.client import TMDBClient
from app.providers.tmdb.exceptions import (
    TMDBConfigurationError,
    TMDBRequestError,
    TMDBResponseError,
)
from app.schemas.server import (
    ServerDatabaseHealthResponse,
    ServerHealthResponse,
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

        database = self._check_database()
        tmdb = self._check_tmdb()

        status = (
            "healthy"
            if (
                database.status == "healthy"
                and tmdb.status == "healthy"
            )
            else "degraded"
        )

        uptime_seconds = max(
            0,
            int(
                (
                    checked_at
                    - self._normalized_started_at()
                ).total_seconds()
            ),
        )

        return ServerHealthResponse(
            status=status,
            checked_at=checked_at,
            uptime_seconds=uptime_seconds,
            database=database,
            tmdb=tmdb,
        )

    def _check_database(
        self,
    ) -> ServerDatabaseHealthResponse:
        started = perf_counter()

        try:
            self._session.execute(
                text("SELECT 1"),
            ).scalar_one()

        except Exception:
            return ServerDatabaseHealthResponse(
                status="unavailable",
                latency_ms=None,
            )

        return ServerDatabaseHealthResponse(
            status="healthy",
            latency_ms=self._elapsed_milliseconds(started),
        )

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