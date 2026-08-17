from datetime import UTC, date, datetime, time, timedelta
from uuid import UUID

from app.repositories.episode_watch_event import EpisodeWatchEventRepository
from app.repositories.movie_watch_event import MovieWatchEventRepository
from app.schemas.statistics import WeeklyStatisticsResponse


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