from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class EpisodeWatchedRequest(BaseModel):
    """Optional viewing date when marking an Episode as watched."""

    watched_at: datetime | None = None


class PreviousUnwatchedEpisodesResponse(BaseModel):
    """Summary of eligible earlier Episodes that remain unwatched."""

    episode_id: UUID

    previous_unwatched_count: int = Field(
        ge=0,
    )

    @property
    def has_previous_unwatched(self) -> bool:
        return self.previous_unwatched_count > 0


class EpisodeProgressResponse(BaseModel):
    """Episode viewing progress returned by the API."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    episode_id: UUID
    is_watched: bool
    watched_at: datetime | None


class EpisodeProgressWithWatchCountResponse(BaseModel):
    """Episode progress enriched with historical viewing information."""

    id: UUID
    episode_id: UUID

    is_watched: bool
    watched_at: datetime | None

    watch_count: int = Field(
        ge=0,
        description="Number of historical viewing events recorded for the Episode.",
    )


class EpisodeWatchedWithPreviousResponse(BaseModel):
    """Result of marking an Episode and eligible previous Episodes watched."""

    progress: EpisodeProgressResponse

    previous_marked_count: int = Field(
        ge=0,
        description=(
            "Number of previously unwatched Episodes marked as watched "
            "alongside the target Episode."
        ),
    )
