from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict

from app.models.enums import LibraryStatus


class LibraryEntryResponse(BaseModel):
    """Library entry returned by the API."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    show_id: UUID
    status: LibraryStatus
    rating: float | None
    started_at: datetime | None
    completed_at: datetime | None
    created_at: datetime
    updated_at: datetime


class LibraryStatusUpdate(BaseModel):
    """Library tracking status update."""

    status: LibraryStatus