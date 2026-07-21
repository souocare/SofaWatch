from datetime import date
from pydantic import BaseModel, ConfigDict, Field, field_validator
from typing import Any


class TMDBTVSearchResult(BaseModel):
    id: int
    name: str
    original_name: str
    overview: str
    first_air_date: date | None = None
    poster_path: str | None = None
    backdrop_path: str | None = None
    original_language: str
    genre_ids: list[int] = Field(default_factory=list)
    popularity: float
    vote_average: float
    vote_count: int

    @field_validator("first_air_date", mode="before")
    @classmethod
    def normalize_empty_first_air_date(
        cls,
        value: Any,
    ) -> Any:
        if value == "":
            return None

        return value


class TMDBTVSearchResponse(BaseModel):
    """Paginated response returned by the TMDB TV search endpoint."""

    page: int
    results: list[TMDBTVSearchResult]
    total_pages: int
    total_results: int

    model_config = ConfigDict(extra="ignore")
