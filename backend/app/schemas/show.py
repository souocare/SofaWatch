from datetime import date, datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field

from app.schemas.genre import GenreResponse


class ShowSummaryResponse(BaseModel):
    """Summary of a TV series stored locally in SofaWatch."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    tmdb_id: int = Field(gt=0)

    title: str
    original_title: str

    first_air_date: date | None = None

    poster_path: str | None = None
    poster_cache_path: str | None = None

    status: str
    vote_average: float = Field(ge=0, le=10)


class ShowResponse(BaseModel):
    """Detailed TV series stored locally in SofaWatch."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID

    tmdb_id: int = Field(gt=0)
    tvdb_id: int | None = Field(default=None, gt=0)
    imdb_id: str | None = None

    title: str
    original_title: str

    overview: str
    tagline: str

    first_air_date: date | None = None
    last_air_date: date | None = None

    poster_path: str | None = None
    backdrop_path: str | None = None

    poster_cache_path: str | None = None
    backdrop_cache_path: str | None = None

    homepage_url: str | None = None
    original_language: str

    status: str
    show_type: str
    in_production: bool

    number_of_seasons: int = Field(ge=0)
    number_of_episodes: int = Field(ge=0)
    episode_run_time: int | None = Field(default=None, ge=0)

    popularity: float = Field(ge=0)
    vote_average: float = Field(ge=0, le=10)
    vote_count: int = Field(ge=0)

    metadata_language: str
    metadata_updated_at: datetime

    created_at: datetime
    updated_at: datetime

    genres: list[GenreResponse] = Field(default_factory=list)
