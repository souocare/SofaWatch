from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class MovieWatchEventResponse(BaseModel):
    """Historical Movie viewing returned by the API."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    movie_id: UUID
    watched_at: datetime