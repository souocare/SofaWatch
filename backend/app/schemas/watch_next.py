from datetime import date
from uuid import UUID

from pydantic import BaseModel, Field

from app.models.enums import LibraryStatus
from app.schemas.show import ShowSummaryResponse


class WatchNextEpisodeResponse(BaseModel):
    """Episode information displayed in Watch Next."""

    id: UUID
    tmdb_id: int = Field(gt=0)

    season_number: int = Field(ge=1)
    episode_number: int = Field(ge=0)

    title: str

    air_date: date | None = None
    runtime: int | None = Field(default=None, ge=0)

    still_url: str | None = None


class WatchNextProgressResponse(BaseModel):
    """Current viewing progress across aired regular Episodes."""

    watched_episodes: int = Field(ge=0)
    aired_episodes: int = Field(ge=0)

    percentage: float = Field(
        ge=0,
        le=100,
    )


class WatchNextShowResponse(BaseModel):
    """Next Episode available to watch for a Library TV series."""

    library_entry_id: UUID
    library_status: LibraryStatus

    show: ShowSummaryResponse
    next_episode: WatchNextEpisodeResponse
    progress: WatchNextProgressResponse
