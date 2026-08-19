from datetime import date, datetime
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, Field

from app.schemas.movie import MovieSummaryResponse
from app.schemas.show import ShowSummaryResponse


class HistoryEpisodeResponse(BaseModel):
    """Episode metadata displayed in the global History timeline."""

    id: UUID
    tmdb_id: int = Field(gt=0)

    season_number: int = Field(ge=1)
    episode_number: int = Field(ge=0)

    title: str

    air_date: date | None = None
    runtime: int | None = Field(default=None, ge=0)

    still_url: str | None = None


class HistoryEpisodeItemResponse(BaseModel):
    """One Episode viewing in the global History timeline."""

    media_type: Literal["episode"] = "episode"

    event_id: UUID
    watched_at: datetime

    show: ShowSummaryResponse
    episode: HistoryEpisodeResponse


class HistoryMovieItemResponse(BaseModel):
    """One Movie viewing in the global History timeline."""

    media_type: Literal["movie"] = "movie"

    event_id: UUID
    watched_at: datetime

    movie: MovieSummaryResponse


HistoryItemResponse = HistoryEpisodeItemResponse | HistoryMovieItemResponse


class HistoryPageResponse(BaseModel):
    """Cursor-paginated combined viewing History."""

    items: list[HistoryItemResponse]

    next_cursor: str | None = None
    has_more: bool


class HistoryPreviewResponse(BaseModel):
    """Compact Profile History preview."""

    episodes: list[HistoryEpisodeItemResponse]
    movies: list[HistoryMovieItemResponse]