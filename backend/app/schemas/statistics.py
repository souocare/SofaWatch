from datetime import date
from enum import StrEnum
from pydantic import BaseModel, Field
from uuid import UUID


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


class StatisticsActivityPeriod(StrEnum):
    """Supported viewing-activity time periods."""

    DAYS_7 = "7d"
    DAYS_14 = "14d"
    DAYS_30 = "30d"
    DAYS_90 = "90d"
    YEAR_1 = "1y"
    ALL = "all"

    @property
    def days(self) -> int | None:
        """Return the fixed day count, or None for all-time activity."""

        return {
            StatisticsActivityPeriod.DAYS_7: 7,
            StatisticsActivityPeriod.DAYS_14: 14,
            StatisticsActivityPeriod.DAYS_30: 30,
            StatisticsActivityPeriod.DAYS_90: 90,
            StatisticsActivityPeriod.YEAR_1: 365,
            StatisticsActivityPeriod.ALL: None,
        }[self]

class StatisticsActivityResponse(BaseModel):
    """Viewing activity over a consecutive calendar-day range."""

    start_date: date
    end_date: date

    days: list[DailyStatisticsResponse]


class StatisticsHabitsResponse(BaseModel):
    """All-time viewing habit statistics."""

    current_streak_days: int = Field(
        ge=0,
    )

    longest_streak_days: int = Field(
        ge=0,
    )

    biggest_marathon_watch_time_minutes: int = Field(
        ge=0,
    )

    biggest_marathon_day: date | None = None

    longest_binge_episode_count: int = Field(
        ge=0,
    )

    longest_binge_day: date | None = None

    average_active_day_watch_time_minutes: int = Field(
        ge=0,
    )

    most_active_weekday: str | None = None
    most_active_weekday_watch_count: int = Field(
        ge=0,
    )

class StatisticsShowInsightResponse(BaseModel):
    """Viewing insight for one Show."""

    show_id: UUID
    tmdb_id: int = Field(gt=0)
    title: str = Field(min_length=1)
    poster_url: str | None = None

    watch_count: int = Field(ge=0)
    rewatch_count: int = Field(ge=0)


class StatisticsEpisodeInsightResponse(BaseModel):
    """Rewatch insight for one Episode."""

    episode_id: UUID

    show_tmdb_id: int = Field(gt=0)
    show_title: str = Field(min_length=1)

    season_number: int = Field(ge=0)
    episode_number: int = Field(ge=0)
    episode_title: str = Field(min_length=1)

    still_url: str | None = None

    watch_count: int = Field(ge=0)
    rewatch_count: int = Field(ge=0)


class StatisticsMovieInsightResponse(BaseModel):
    """Viewing insight for one Movie."""

    movie_id: UUID
    tmdb_id: int = Field(gt=0)
    title: str = Field(min_length=1)
    poster_url: str | None = None

    watch_count: int = Field(ge=0)
    rewatch_count: int = Field(ge=0)


class StatisticsGenreInsightResponse(BaseModel):
    """Viewing insight for one Genre."""

    genre_id: int = Field(gt=0)
    name: str = Field(min_length=1)
    watch_count: int = Field(ge=0)


class StatisticsContentInsightsResponse(BaseModel):
    """Ranked all-time viewing insights for a SofaWatch user."""

    most_watched_shows: list[StatisticsShowInsightResponse]
    most_rewatched_shows: list[StatisticsShowInsightResponse]

    most_rewatched_episodes: list[StatisticsEpisodeInsightResponse]
    most_rewatched_movies: list[StatisticsMovieInsightResponse]

    top_show_genres: list[StatisticsGenreInsightResponse]
    top_movie_genres: list[StatisticsGenreInsightResponse]