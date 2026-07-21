from datetime import date

from pydantic import BaseModel, Field


class ShowSearchResult(BaseModel):
    """TV series returned by the SofaWatch search API."""

    tmdb_id: int = Field(gt=0)

    title: str
    original_title: str

    overview: str = ""
    first_air_date: date | None = None

    poster_url: str | None = None
    backdrop_url: str | None = None

    original_language: str
    genre_ids: list[int] = Field(default_factory=list)

    popularity: float = 0.0
    vote_average: float = 0.0
    vote_count: int = 0


class ShowSearchResponse(BaseModel):
    """Paginated TV series search response."""

    page: int = Field(ge=1)
    results: list[ShowSearchResult] = Field(default_factory=list)

    total_pages: int = Field(ge=0)
    total_results: int = Field(ge=0)
