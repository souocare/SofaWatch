from datetime import date

from pydantic import BaseModel, Field


class EpisodeSummary(BaseModel):
    """Episode metadata returned by TMDB."""

    tmdb_id: int = Field(gt=0)

    episode_number: int = Field(ge=0)

    title: str
    overview: str | None = None

    air_date: date | None = None
    runtime: int | None = Field(default=None, ge=0)

    vote_average: float = Field(default=0.0, ge=0, le=10)
    vote_count: int = Field(default=0, ge=0)

    still_path: str | None = None
