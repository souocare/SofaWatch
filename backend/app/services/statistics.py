from datetime import UTC, date, datetime, time, timedelta
from uuid import UUID

from app.repositories.episode_watch_event import EpisodeWatchEventRepository
from app.repositories.movie_watch_event import MovieWatchEventRepository
from app.schemas.statistics import (
    DailyStatisticsResponse,
    MediaViewingStatisticsResponse,
    StatisticsActivityResponse,
    StatisticsSummaryResponse,
    WeeklyStatisticsResponse,
)


class StatisticsService:
    """Build reusable viewing statistics for a SofaWatch user."""

    def __init__(
        self,
        *,
        episode_watch_event_repository: EpisodeWatchEventRepository,
        movie_watch_event_repository: MovieWatchEventRepository,
    ) -> None:
        self._episode_watch_event_repository = (
            episode_watch_event_repository
        )

        self._movie_watch_event_repository = (
            movie_watch_event_repository
        )

    def get_weekly_summary(
        self,
        *,
        user_id: UUID,
        reference_date: date | None = None,
    ) -> WeeklyStatisticsResponse:
        """Return the user's viewing summary for the current calendar week.

        Weeks start on Monday and end on Sunday.

        Database filtering uses a half-open UTC interval:

        ``week_start <= watched_at < next_week_start``

        This avoids precision problems around the final instant of Sunday.
        """

        current_date = reference_date or datetime.now(UTC).date()

        week_start = current_date - timedelta(
            days=current_date.weekday(),
        )

        next_week_start = week_start + timedelta(
            days=7,
        )

        week_end = next_week_start - timedelta(
            days=1,
        )

        start_at = datetime.combine(
            week_start,
            time.min,
            tzinfo=UTC,
        )

        end_at = datetime.combine(
            next_week_start,
            time.min,
            tzinfo=UTC,
        )

        (
            episodes_watched,
            episode_watch_time_minutes,
        ) = self._episode_watch_event_repository.get_statistics_for_period(
            user_id=user_id,
            start_at=start_at,
            end_at=end_at,
        )

        (
            movies_watched,
            movie_watch_time_minutes,
        ) = self._movie_watch_event_repository.get_statistics_for_period(
            user_id=user_id,
            start_at=start_at,
            end_at=end_at,
        )

        return WeeklyStatisticsResponse(
            week_start=week_start,
            week_end=week_end,
            episodes_watched=episodes_watched,
            movies_watched=movies_watched,
            watch_time_minutes=(
                episode_watch_time_minutes
                + movie_watch_time_minutes
            ),
        )

    def get_summary(
        self,
        *,
        user_id: UUID,
    ) -> StatisticsSummaryResponse:
        """Return the user's all-time viewing summary."""

        shows_watched = (
            self._episode_watch_event_repository.count_watched_shows(
                user_id=user_id,
            )
        )

        (
            episode_watch_count,
            unique_episodes,
            episode_rewatch_count,
            episode_watch_time,
            episode_rewatch_time,
        ) = self._episode_watch_event_repository.get_all_time_statistics(
            user_id=user_id,
        )

        (
            movie_watch_count,
            unique_movies,
            movie_rewatch_count,
            movie_watch_time,
            movie_rewatch_time,
        ) = self._movie_watch_event_repository.get_all_time_statistics(
            user_id=user_id,
        )

        return StatisticsSummaryResponse(
            shows_watched=shows_watched,
            episodes=MediaViewingStatisticsResponse(
                watch_count=episode_watch_count,
                unique_count=unique_episodes,
                rewatch_count=episode_rewatch_count,
                watch_time_minutes=episode_watch_time,
                rewatch_time_minutes=episode_rewatch_time,
            ),
            movies=MediaViewingStatisticsResponse(
                watch_count=movie_watch_count,
                unique_count=unique_movies,
                rewatch_count=movie_rewatch_count,
                watch_time_minutes=movie_watch_time,
                rewatch_time_minutes=movie_rewatch_time,
            ),
            watch_time_minutes=(
                episode_watch_time
                + movie_watch_time
            ),
            rewatch_time_minutes=(
                episode_rewatch_time
                + movie_rewatch_time
            ),
        )


    def get_activity(
        self,
        *,
        user_id: UUID,
        days: int,
        reference_date: date | None = None,
    ) -> StatisticsActivityResponse:
        """Return daily viewing activity for a recent calendar-day range.

        The requested range includes ``reference_date`` itself.

        Repository results contain only days with viewing activity. This
        service fills missing calendar days with zero values so API clients
        receive a complete, chronological time series.
        """

        if days not in {
            7,
            14,
        }:
            raise ValueError(
                "Statistics activity supports only 7 or 14 days."
            )

        current_date = reference_date or datetime.now(
            UTC,
        ).date()

        start_date = current_date - timedelta(
            days=days - 1,
        )

        end_date = current_date

        start_at = datetime.combine(
            start_date,
            time.min,
            tzinfo=UTC,
        )

        end_at = datetime.combine(
            current_date + timedelta(days=1),
            time.min,
            tzinfo=UTC,
        )

        episode_rows = (
            self._episode_watch_event_repository
            .get_daily_statistics_for_period(
                user_id=user_id,
                start_at=start_at,
                end_at=end_at,
            )
        )

        movie_rows = (
            self._movie_watch_event_repository
            .get_daily_statistics_for_period(
                user_id=user_id,
                start_at=start_at,
                end_at=end_at,
            )
        )

        episodes_by_day = {
            date.fromisoformat(row.day): row
            for row in episode_rows
        }

        movies_by_day = {
            date.fromisoformat(row.day): row
            for row in movie_rows
        }

        daily_statistics: list[
            DailyStatisticsResponse
        ] = []

        for offset in range(days):
            day = start_date + timedelta(
                days=offset,
            )

            episode_statistics = episodes_by_day.get(
                day,
            )

            movie_statistics = movies_by_day.get(
                day,
            )

            episode_watch_count = (
                episode_statistics.watch_count
                if episode_statistics is not None
                else 0
            )

            episode_watch_time = (
                episode_statistics.watch_time_minutes
                if episode_statistics is not None
                else 0
            )

            movie_watch_count = (
                movie_statistics.watch_count
                if movie_statistics is not None
                else 0
            )

            movie_watch_time = (
                movie_statistics.watch_time_minutes
                if movie_statistics is not None
                else 0
            )

            daily_statistics.append(
                DailyStatisticsResponse(
                    day=day,
                    episodes_watched=episode_watch_count,
                    movies_watched=movie_watch_count,
                    episode_watch_time_minutes=(
                        episode_watch_time
                    ),
                    movie_watch_time_minutes=(
                        movie_watch_time
                    ),
                    watch_time_minutes=(
                        episode_watch_time
                        + movie_watch_time
                    ),
                )
            )

        return StatisticsActivityResponse(
            start_date=start_date,
            end_date=end_date,
            days=daily_statistics,
        )