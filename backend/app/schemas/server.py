from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field


ServerHealthStatus = Literal[
    "healthy",
    "degraded",
    "unavailable",
]

ServerComponentStatus = Literal[
    "healthy",
    "unavailable",
]

ServerDatabaseCheckStatus = Literal[
    "ok",
    "failed",
    "unavailable",
]

ServerLogLevel = Literal[
    "DEBUG",
    "INFO",
    "WARNING",
    "ERROR",
    "CRITICAL",
]

ServerLogComponent = Literal[
    "api",
    "worker",
]


class ServerDatabaseMigrationResponse(BaseModel):
    """Applied Alembic migration information."""

    revision: str | None = None
    message: str | None = None


class ServerDatabaseHealthResponse(BaseModel):
    """Operational health information for the configured database."""

    status: ServerComponentStatus

    engine: str

    latency_ms: float | None = Field(
        default=None,
        ge=0,
    )

    size_bytes: int | None = Field(
        default=None,
        ge=0,
    )

    wal_size_bytes: int | None = Field(
        default=None,
        ge=0,
    )
    integrity_check: ServerDatabaseCheckStatus
    foreign_key_check: ServerDatabaseCheckStatus
    migration: ServerDatabaseMigrationResponse


class ServerTMDBHealthResponse(BaseModel):
    """Operational health information for the TMDB integration."""

    status: ServerComponentStatus

    configured: bool

    latency_ms: float | None = Field(
        default=None,
        ge=0,
    )

class ServerEnvironmentResponse(BaseModel):
    """Safe administrative application configuration."""

    app_name: str
    environment: str
    debug: bool

    api_host: str
    api_port: int = Field(
        ge=1,
        le=65535,
    )

    default_language: str
    supported_languages: list[str]

    metadata_refresh_days: int = Field(
        ge=1,
    )


class ServerImageCacheCategoryResponse(BaseModel):
    """Storage usage for one image cache category."""

    size_bytes: int = Field(
        ge=0,
    )
    files: int = Field(
        ge=0,
    )


class ServerImageCacheBreakdownResponse(BaseModel):
    """Image cache usage grouped by SofaWatch media type."""

    shows: ServerImageCacheCategoryResponse
    seasons: ServerImageCacheCategoryResponse
    episodes: ServerImageCacheCategoryResponse


class ServerImageCacheResponse(BaseModel):
    """Image cache storage summary."""

    total_size_bytes: int = Field(
        ge=0,
    )
    total_files: int = Field(
        ge=0,
    )

    breakdown: ServerImageCacheBreakdownResponse


class ServerStorageResponse(BaseModel):
    """Administrative storage information."""

    data_directory: str

    writable: bool

    total_space_bytes: int | None = Field(
        default=None,
        ge=0,
    )
    used_space_bytes: int | None = Field(
        default=None,
        ge=0,
    )
    free_space_bytes: int | None = Field(
        default=None,
        ge=0,
    )

    usage_percentage: float | None = Field(
        default=None,
        ge=0,
        le=100,
    )

    image_cache: ServerImageCacheResponse


class ServerRuntimeResponse(BaseModel):
    """Safe runtime information for the SofaWatch process."""

    python_version: str
    platform: str
    started_at: datetime

class ServerHealthResponse(BaseModel):
    """Administrative operational health summary for SofaWatch."""

    status: ServerHealthStatus

    checked_at: datetime

    uptime_seconds: int = Field(
        ge=0,
    )

    database: ServerDatabaseHealthResponse
    tmdb: ServerTMDBHealthResponse
    environment: ServerEnvironmentResponse
    storage: ServerStorageResponse
    runtime: ServerRuntimeResponse


class ServerLogEntryResponse(BaseModel):
    """Safe structured Server log entry."""

    timestamp: datetime
    level: ServerLogLevel
    logger: str
    message: str
    component: ServerLogComponent


class ServerLogsResponse(BaseModel):
    """Paginated administrative Server logs."""

    items: list[ServerLogEntryResponse]

    offset: int = Field(
        ge=0,
    )

    limit: int = Field(
        gt=0,
    )

    total: int = Field(
        ge=0,
    )

    has_next: bool