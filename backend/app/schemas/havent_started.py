from uuid import UUID

from pydantic import BaseModel

from app.models.enums import LibraryStatus
from app.schemas.show import ShowSummaryResponse
from app.schemas.watch_next import WatchNextEpisodeResponse


class HaventStartedShowResponse(BaseModel):
    """Library Show that has not been started yet."""

    library_entry_id: UUID
    library_status: LibraryStatus

    show: ShowSummaryResponse

    first_episode: WatchNextEpisodeResponse