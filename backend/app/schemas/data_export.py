from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field

from app.models.enums import LibraryStatus


class ExportUserResponse(BaseModel):
    """Portable user data included in a SofaWatch export."""

    display_name: str


class ExportLibraryShowResponse(BaseModel):
    """Portable TV series Library entry."""

    tmdb_id: int = Field(
        gt=0,
    )

    status: LibraryStatus

    started_at: datetime | None = None
    completed_at: datetime | None = None


class ExportLibraryMovieResponse(BaseModel):
    """Portable Movie Library entry."""

    tmdb_id: int = Field(
        gt=0,
    )

    status: LibraryStatus

    started_at: datetime | None = None
    completed_at: datetime | None = None


class ExportLibraryResponse(BaseModel):
    """Portable Library data."""

    shows: list[ExportLibraryShowResponse]
    movies: list[ExportLibraryMovieResponse]


class ExportEpisodeWatchEventResponse(BaseModel):
    """Portable historical Episode viewing."""

    show_tmdb_id: int = Field(
        gt=0,
    )

    season_number: int = Field(
        ge=0,
    )

    episode_number: int = Field(
        ge=0,
    )

    episode_tmdb_id: int = Field(
        gt=0,
    )

    watched_at: datetime


class ExportMovieWatchEventResponse(BaseModel):
    """Portable historical Movie viewing."""

    movie_tmdb_id: int = Field(
        gt=0,
    )

    watched_at: datetime


class ExportWatchHistoryResponse(BaseModel):
    """Portable viewing history."""

    episodes: list[ExportEpisodeWatchEventResponse]
    movies: list[ExportMovieWatchEventResponse]


class SofaWatchExportResponse(BaseModel):
    """Versioned portable SofaWatch user data export."""

    format: Literal["sofawatch-export"] = "sofawatch-export"

    version: Literal[1] = 1

    exported_at: datetime

    user: ExportUserResponse
    library: ExportLibraryResponse
    history: ExportWatchHistoryResponse
