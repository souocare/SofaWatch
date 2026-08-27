from datetime import date, datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, model_validator

from app.models.enums import LibraryStatus
from app.schemas.movie import MovieSummaryResponse
from app.schemas.show import ShowSummaryResponse


class LibraryEntryResponse(BaseModel):
    """Library entry returned by the API."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID

    show_id: UUID | None
    movie_id: UUID | None

    status: LibraryStatus

    rating: float | None

    started_at: datetime | None
    completed_at: datetime | None

    created_at: datetime
    updated_at: datetime

    @model_validator(mode="after")
    def validate_media_target(self) -> "LibraryEntryResponse":
        """Ensure the entry references exactly one media item."""

        has_show = self.show_id is not None
        has_movie = self.movie_id is not None

        if has_show == has_movie:
            raise ValueError("A library entry must reference exactly one media item.")

        return self


class LibraryFirstEpisodeResponse(BaseModel):
    """First aired regular Episode available for a Library Show."""

    id: UUID
    tmdb_id: int

    season_number: int
    episode_number: int

    title: str

    air_date: date | None
    runtime: int | None


class LibraryShowProgressResponse(BaseModel):
    """Viewing progress across aired regular Episodes for a Library Show."""

    watched_episodes: int = Field(ge=0)
    aired_episodes: int = Field(ge=0)

    percentage: float = Field(
        ge=0,
        le=100,
    )

    caught_up: bool


class LibraryShowResponse(BaseModel):
    """TV series stored in the current user's library."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    status: LibraryStatus

    rating: float | None

    started_at: datetime | None
    completed_at: datetime | None

    created_at: datetime
    updated_at: datetime

    show: ShowSummaryResponse

    first_available_episode: LibraryFirstEpisodeResponse | None = None

    progress: LibraryShowProgressResponse


class LibraryMovieResponse(BaseModel):
    """Movie stored in the current user's library."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    status: LibraryStatus

    rating: float | None

    started_at: datetime | None
    completed_at: datetime | None

    created_at: datetime
    updated_at: datetime

    movie: MovieSummaryResponse


class LibraryPreviewShowResponse(BaseModel):
    """TV series displayed in a compact Library preview."""

    show: ShowSummaryResponse

    watched_episodes: int = Field(
        ge=0,
    )

    aired_episodes: int = Field(
        ge=0,
    )


class LibraryPreviewMovieResponse(BaseModel):
    """Movie displayed in a compact Library preview."""

    movie: MovieSummaryResponse


class LibraryPreviewResponse(BaseModel):
    """Recently added media displayed in the Profile Library preview."""

    shows: list[LibraryPreviewShowResponse]
    movies: list[LibraryPreviewMovieResponse]


class LibraryStatusUpdate(BaseModel):
    """Library tracking status update."""

    status: LibraryStatus
