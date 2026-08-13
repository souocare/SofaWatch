from datetime import date, datetime
from uuid import UUID

from pydantic import BaseModel, Field

from app.models.enums import LibraryStatus
from app.schemas.show import ShowSummaryResponse


class StaleWatchingEpisodeResponse(BaseModel):
    """Episode metadata used by the stale Watching collection."""

    id: UUID
    tmdb_id: int = Field(gt=0)

    season_number: int = Field(ge=1)
    episode_number: int = Field(ge=0)

    title: str

    air_date: date | None = None
    runtime: int | None = Field(default=None, ge=0)

    still_url: str | None = None


class LastWatchedEpisodeResponse(StaleWatchingEpisodeResponse):
    """Most recently watched Episode of a TV series."""

    watched_at: datetime


class StaleWatchingShowResponse(BaseModel):
    """Watching Show that has not been continued recently."""

    library_entry_id: UUID
    library_status: LibraryStatus

    show: ShowSummaryResponse

    last_watched: LastWatchedEpisodeResponse
    next_episode: StaleWatchingEpisodeResponse