from uuid import UUID

from pydantic import BaseModel

from app.models.enums import LibraryStatus


class StartShowResponse(BaseModel):
    """Result of starting a TV series from the Library."""

    library_entry_id: UUID
    library_status: LibraryStatus

    show_id: UUID

    started_episode_id: UUID
