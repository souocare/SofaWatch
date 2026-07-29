from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class EpisodeWatchedRequest(BaseModel):
    """Optional viewing date when marking an episode as watched."""

    watched_at: datetime | None = None


class EpisodeProgressResponse(BaseModel):
    """Episode viewing progress returned by the API."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    episode_id: UUID
    is_watched: bool
    watched_at: datetime | None
