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


class ServerDatabaseHealthResponse(BaseModel):
    """Operational health information for the configured database."""

    status: ServerComponentStatus
    latency_ms: float | None = Field(
        default=None,
        ge=0,
    )


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