from datetime import date, datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field

from app.schemas.genre import GenreResponse


class MovieSummaryResponse(BaseModel):
    """Summary of a movie stored locally in SofaWatch."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID

    tmdb_id: int = Field(gt=0)

    title: str
    original_title: str

    release_date: date | None = None

    tmdb_poster_path: str | None = None
    local_poster_path: str | None = None

    poster_url: str | None = None
    backdrop_url: str | None = None

    status: str

    vote_average: float = Field(ge=0, le=10)


class MovieResponse(BaseModel):
    """Detailed movie stored locally in SofaWatch."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID

    tmdb_id: int = Field(gt=0)

    title: str
    original_title: str

    overview: str | None = None
    tagline: str | None = None

    release_date: date | None = None

    tmdb_poster_path: str | None = None
    tmdb_backdrop_path: str | None = None

    local_poster_path: str | None = None
    local_backdrop_path: str | None = None

    poster_url: str | None = None
    backdrop_url: str | None = None

    original_language: str

    runtime: int | None = Field(default=None, ge=0)

    status: str

    adult: bool
    video: bool

    popularity: float = Field(ge=0)

    vote_average: float = Field(ge=0, le=10)

    vote_count: int = Field(ge=0)

    metadata_language: str
    metadata_updated_at: datetime

    created_at: datetime
    updated_at: datetime

    genres: list[GenreResponse] = Field(default_factory=list)
