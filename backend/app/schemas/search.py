from datetime import date
from enum import StrEnum

from pydantic import BaseModel, Field


class SearchMediaType(StrEnum):
    """Supported media types returned by the general search."""

    SHOW = "show"
    MOVIE = "movie"


class SearchMediaTypeFilter(StrEnum):
    """Media-type filter accepted by the general search endpoint."""

    ALL = "all"
    SHOW = "show"
    MOVIE = "movie"


class SearchResult(BaseModel):
    """Movie or TV series returned by the SofaWatch general search API."""

    media_type: SearchMediaType
    tmdb_id: int = Field(gt=0)

    title: str
    original_title: str

    overview: str | None = None

    release_date: date | None = None

    poster_url: str | None = None
    backdrop_url: str | None = None

    original_language: str
    genre_ids: list[int] = Field(default_factory=list)

    popularity: float = 0.0
    vote_average: float = Field(default=0.0, ge=0, le=10)
    vote_count: int = Field(default=0, ge=0)


class SearchResponse(BaseModel):
    """Paginated response returned by the general search endpoint."""

    page: int = Field(ge=1)
    results: list[SearchResult] = Field(default_factory=list)

    total_pages: int = Field(ge=0)
    total_results: int = Field(ge=0)
