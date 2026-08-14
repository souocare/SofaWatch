from datetime import date, datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, model_validator

from app.models.enums import LibraryStatus
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
            raise ValueError(
                "A library entry must reference exactly one media item."
            )

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


class LibraryStatusUpdate(BaseModel):
    """Library tracking status update."""

    status: LibraryStatus