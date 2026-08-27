from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class EpisodeWatchEventResponse(BaseModel):
    """Historical Episode viewing event returned by the API."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    episode_id: UUID
    watched_at: datetime
