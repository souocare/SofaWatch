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


class ServerHealthResponse(BaseModel):
    """Administrative operational health summary for SofaWatch."""

    status: ServerHealthStatus

    checked_at: datetime

    uptime_seconds: int = Field(
        ge=0,
    )

    database: ServerDatabaseHealthResponse
    tmdb: ServerTMDBHealthResponse