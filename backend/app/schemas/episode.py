from datetime import date
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class EpisodeResponse(BaseModel):
    """Locally stored TV episode returned by the API."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    tmdb_id: int = Field(gt=0)
    episode_number: int = Field(ge=0)

    title: str
    overview: str | None = None

    air_date: date | None = None
    runtime: int | None = Field(
        default=None,
        ge=0,
    )

    vote_average: float = Field(
        ge=0,
        le=10,
    )
    vote_count: int = Field(ge=0)

    tmdb_still_path: str | None = None
    local_still_path: str | None = None
