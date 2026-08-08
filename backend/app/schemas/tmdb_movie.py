from datetime import date

from pydantic import BaseModel, Field


class MovieGenre(BaseModel):
    """Genre associated with a movie."""

    tmdb_id: int = Field(gt=0)
    name: str


class MovieDetailsResponse(BaseModel):
    """Detailed movie information returned by the SofaWatch API."""

    tmdb_id: int = Field(gt=0)

    title: str
    original_title: str

    overview: str | None = None
    tagline: str | None = None

    release_date: date | None = None

    poster_url: str | None = None
    backdrop_url: str | None = None

    poster_path: str | None = None
    backdrop_path: str | None = None
    adult: bool = False
    video: bool = False

    genres: list[MovieGenre] = Field(default_factory=list)

    original_language: str

    runtime: int | None = Field(default=None, ge=0)
    status: str

    popularity: float = 0.0
    vote_average: float = Field(default=0.0, ge=0, le=10)
    vote_count: int = Field(default=0, ge=0)
