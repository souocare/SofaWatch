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
    in_library: bool = False

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




class ExploreTrendingWindow(StrEnum):
    """Supported TMDB trending time windows."""

    DAY = "day"
    WEEK = "week"


class ExploreTrendingResponse(BaseModel):
    """Ordered trending media returned to Explore."""

    items: list[ExploreMediaItem] = Field(
        default_factory=list,
    )

class ExploreMediaCollection(BaseModel):
    """A collection of media items exposed by Explore."""

    items: list[ExploreMediaItem] = Field(
        default_factory=list,
    )