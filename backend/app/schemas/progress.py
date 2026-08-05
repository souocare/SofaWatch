from uuid import UUID

from pydantic import BaseModel, Field

from app.schemas.episode import EpisodeResponse


class SeasonProgressResponse(BaseModel):
    """Viewing progress for a TV season."""

    season_id: UUID

    watched_episodes: int = Field(ge=0)
    total_episodes: int = Field(ge=0)

    progress_percentage: float = Field(
        ge=0,
        le=100,
    )

    aired_episodes: int = Field(ge=0)
    watched_aired_episodes: int = Field(ge=0)

    aired_progress_percentage: float = Field(
        ge=0,
        le=100,
    )

    caught_up: bool


class ShowProgressResponse(BaseModel):
    """Viewing progress for a TV series."""

    show_id: UUID

    watched_episodes: int = Field(ge=0)
    total_episodes: int = Field(ge=0)

    progress_percentage: float = Field(
        ge=0,
        le=100,
    )

    aired_episodes: int = Field(ge=0)
    watched_aired_episodes: int = Field(ge=0)

    aired_progress_percentage: float = Field(
        ge=0,
        le=100,
    )

    caught_up: bool


class NextEpisodeResponse(BaseModel):
    """Next unwatched episode of a TV series."""

    show_id: UUID
    next_episode: EpisodeResponse | None


class NextUpcomingEpisodeResponse(BaseModel):
    """Next future episode of a TV series."""

    show_id: UUID
    next_episode: EpisodeResponse | None
