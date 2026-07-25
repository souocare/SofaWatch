from datetime import date
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class SeasonResponse(BaseModel):
    """Locally stored TV season returned by the API."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    tmdb_id: int = Field(gt=0)
    season_number: int = Field(ge=0)

    title: str
    overview: str | None = None

    air_date: date | None = None
    episode_count: int = Field(ge=0)
    vote_average: float = Field(ge=0, le=10)

    tmdb_poster_path: str | None = None
    local_poster_path: str | None = None