from uuid import UUID

from pydantic import BaseModel

from app.models.enums import LibraryStatus
from app.schemas.show import ShowSummaryResponse
from app.schemas.upcoming import UpcomingEpisodeResponse


class MissedRecentlyItemResponse(BaseModel):
    """Recent aired unwatched Episode from a Watching Show."""

    library_entry_id: UUID
    library_status: LibraryStatus

    show: ShowSummaryResponse

    episode: UpcomingEpisodeResponse
