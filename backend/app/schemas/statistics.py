from datetime import date

from pydantic import BaseModel, Field


class WeeklyStatisticsResponse(BaseModel):
    """Viewing summary for one calendar week."""
    week_start: date
    week_end: date

    episodes_watched: int = Field(
        ge=0,
    )
    movies_watched: int = Field(
        ge=0,
    )
    watch_time_minutes: int = Field(
        ge=0,
    )




class MediaViewingStatisticsResponse(BaseModel):
    """All-time viewing statistics for one media type."""

    watch_count: int = Field(
        ge=0,
    )

    unique_count: int = Field(
        ge=0,
    )

    rewatch_count: int = Field(
        ge=0,
    )

    watch_time_minutes: int = Field(
        ge=0,
    )

    rewatch_time_minutes: int = Field(
        ge=0,
    )

class StatisticsSummaryResponse(BaseModel):
    """All-time viewing summary for a SofaWatch user."""

    shows_watched: int = Field(
        ge=0,
    )

    episodes: MediaViewingStatisticsResponse

    movies: MediaViewingStatisticsResponse

    watch_time_minutes: int = Field(
        ge=0,
    )

    rewatch_time_minutes: int = Field(
        ge=0,
    )

class DailyStatisticsResponse(BaseModel):
    """Viewing activity for one calendar day."""

    day: date

    episodes_watched: int = Field(
        ge=0,
    )

    movies_watched: int = Field(
        ge=0,
    )

    episode_watch_time_minutes: int = Field(
        ge=0,
    )

    movie_watch_time_minutes: int = Field(
        ge=0,
    )

    watch_time_minutes: int = Field(
        ge=0,
    )


class StatisticsActivityResponse(BaseModel):
    """Viewing activity over a consecutive calendar-day range."""

    start_date: date
    end_date: date

    days: list[DailyStatisticsResponse]