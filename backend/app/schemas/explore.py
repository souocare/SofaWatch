from datetime import date
from enum import StrEnum

from pydantic import BaseModel, ConfigDict, Field


class ExploreMediaType(StrEnum):
    SHOW = "show"
    MOVIE = "movie"


class ExploreMediaItem(BaseModel):
    """Media summary exposed by the Explore API."""

    media_type: ExploreMediaType

    tmdb_id: int

    title: str
    original_title: str

    overview: str = ""

    release_date: date | None = None

    poster_url: str | None = None
    backdrop_url: str | None = None

    original_language: str

    genre_ids: list[int] = Field(
        default_factory=list,
    )

    popularity: float = 0
    vote_average: float = 0
    vote_count: int = 0

    model_config = ConfigDict(
        extra="ignore",
    )


class ExploreTrendingResponse(BaseModel):
    """Trending media returned to Explore."""

    shows: list[ExploreMediaItem] = Field(
        default_factory=list,
    )

    movies: list[ExploreMediaItem] = Field(
        default_factory=list,
    )