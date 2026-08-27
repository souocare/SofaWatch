from datetime import date, datetime
from uuid import UUID

from pydantic import BaseModel, Field

from app.schemas.show import ShowSummaryResponse


class WatchHistoryEpisodeResponse(BaseModel):
    """Episode information displayed in Watch History."""

    id: UUID
    tmdb_id: int = Field(gt=0)

    season_number: int = Field(ge=1)
    episode_number: int = Field(ge=0)

    title: str

    air_date: date | None = None
    runtime: int | None = Field(
        default=None,
        ge=0,
    )

    still_url: str | None = None

    watched_at: datetime

    # Total number of historical viewings recorded for this Episode.
    watch_count: int = Field(
        ge=1,
    )


class WatchHistoryItemResponse(BaseModel):
    """One historical Episode viewing in the user's Watch History."""

    # Identifies this specific viewing.
    #
    # This is deliberately different from episode.id because the same
    # Episode may appear several times in Watch History after rewatches.
    event_id: UUID

    show: ShowSummaryResponse
    episode: WatchHistoryEpisodeResponse


class WatchHistoryPageResponse(BaseModel):
    """Cursor-paginated Watch History response."""

    items: list[WatchHistoryItemResponse]
    next_cursor: str | None = None
    has_more: bool
