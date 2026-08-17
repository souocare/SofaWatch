from datetime import date
from uuid import UUID

from pydantic import BaseModel, Field

from app.models.enums import LibraryStatus
from app.schemas.show import ShowSummaryResponse


class UpcomingEpisodeResponse(BaseModel):
    """Future Episode displayed in the Shows Upcoming timeline."""

    id: UUID
    tmdb_id: int = Field(gt=0)

    season_number: int = Field(ge=1)
    episode_number: int = Field(ge=0)

    title: str

    air_date: date
    runtime: int | None = Field(default=None, ge=0)

    still_url: str | None = None

    is_watched: bool = False


class UpcomingItemResponse(BaseModel):
    """One Episode in the current user's Upcoming timeline."""

    library_entry_id: UUID
    library_status: LibraryStatus

    show: ShowSummaryResponse
    episode: UpcomingEpisodeResponse