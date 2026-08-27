from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field

from app.schemas.episode import EpisodeResponse
from app.schemas.show import ShowSummaryResponse


class EpisodeDetailsSeasonResponse(BaseModel):
    """Season context for an Episode Details response."""

    id: UUID
    season_number: int = Field(ge=0)


class EpisodeDetailsProgressResponse(BaseModel):
    """Current and historical viewing state for an Episode."""

    is_watched: bool

    # Current progress timestamp.
    #
    # This becomes None after "Mark as unwatched".
    watched_at: datetime | None = None

    # Historical viewing information.
    #
    # Watch events are deliberately preserved when an Episode is merely
    # marked as unwatched.
    watch_count: int = Field(ge=0)
    last_watched_at: datetime | None = None


class EpisodeDetailsResponse(BaseModel):
    """Aggregated data required by the Episode Details screen."""

    episode: EpisodeResponse
    season: EpisodeDetailsSeasonResponse
    show: ShowSummaryResponse
    progress: EpisodeDetailsProgressResponse
