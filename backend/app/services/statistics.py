from datetime import UTC, date, datetime, time, timedelta
from uuid import UUID

from app.repositories.episode import EpisodeRepository
from app.repositories.episode_progress import EpisodeProgressRepository
from app.repositories.episode_watch_event import EpisodeWatchEventRepository
from app.repositories.library import LibraryRepository
from app.repositories.movie_watch_event import MovieWatchEventRepository
from app.schemas.statistics import (
    DailyStatisticsResponse,
    MediaViewingStatisticsResponse,
    StatisticsActivityPeriod,
    StatisticsActivityResponse,
    StatisticsBacklogResponse,
    StatisticsBacklogTrend,
    StatisticsContentInsightsResponse,
    StatisticsEpisodeInsightResponse,
    StatisticsGenreInsightResponse,
    StatisticsHabitsResponse,
    StatisticsLibraryResponse,
    StatisticsMovieInsightResponse,
    StatisticsShowInsightResponse,
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
        library_repository: LibraryRepository,
        episode_repository: EpisodeRepository,
        episode_progress_repository: EpisodeProgressRepository,
    ) -> None:
        self._episode_watch_event_repository = episode_watch_event_repository

        self._movie_watch_event_repository = movie_watch_event_repository

        self._library_repository = library_repository

        self._episode_repository = episode_repository

        self._episode_progress_repository = episode_progress_repository

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
            watch_time_minutes=(episode_watch_time_minutes + movie_watch_time_minutes),
        )

    def get_summary(
        self,
        *,
        user_id: UUID,
    ) -> StatisticsSummaryResponse:
        """Return the user's all-time viewing summary."""

        shows_watched = self._episode_watch_event_repository.count_watched_shows(
            user_id=user_id,
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
            watch_time_minutes=(episode_watch_time + movie_watch_time),
            rewatch_time_minutes=(episode_rewatch_time + movie_rewatch_time),
        )

    def get_activity(
        self,
        *,
        user_id: UUID,
        period: StatisticsActivityPeriod,
        reference_date: date | None = None,
    ) -> StatisticsActivityResponse:
        """Return daily viewing activity for a recent calendar-day range.

        The requested range includes ``reference_date`` itself.

        Repository results contain only days with viewing activity. This
        service fills missing calendar days with zero values so API clients
        receive a complete, chronological time series.
        """

        current_date = (
            reference_date
            or datetime.now(
                UTC,
            ).date()
        )

        days = period.days

        if days is None:
            episode_first_watched_at = (
                self._episode_watch_event_repository.get_earliest_watched_at_for_user(
                    user_id=user_id,
                )
            )

            movie_first_watched_at = (
                self._movie_watch_event_repository.get_earliest_watched_at_for_user(
                    user_id=user_id,
                )
            )

            first_viewings = [
                watched_at
                for watched_at in (
                    episode_first_watched_at,
                    movie_first_watched_at,
                )
                if watched_at is not None
            ]

            if first_viewings:
                earliest_watched_at = min(
                    first_viewings,
                )

                if earliest_watched_at.tzinfo is None:
                    earliest_watched_at = earliest_watched_at.replace(
                        tzinfo=UTC,
                    )

                start_date = earliest_watched_at.astimezone(
                    UTC,
                ).date()
            else:
                # /*
                # * Keep an empty All response structurally useful:
                # * Today is returned as one zero-activity day.
                # */
                start_date = current_date

        else:
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

        episode_rows = self._episode_watch_event_repository.get_daily_statistics_for_period(
            user_id=user_id,
            start_at=start_at,
            end_at=end_at,
        )

        movie_rows = self._movie_watch_event_repository.get_daily_statistics_for_period(
            user_id=user_id,
            start_at=start_at,
            end_at=end_at,
        )

        episodes_by_day = {date.fromisoformat(row.day): row for row in episode_rows}

        movies_by_day = {date.fromisoformat(row.day): row for row in movie_rows}

        daily_statistics: list[DailyStatisticsResponse] = []

        number_of_days = (current_date - start_date).days + 1

        for offset in range(number_of_days):
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
                episode_statistics.watch_count if episode_statistics is not None else 0
            )

            episode_watch_time = (
                episode_statistics.watch_time_minutes if episode_statistics is not None else 0
            )

            movie_watch_count = movie_statistics.watch_count if movie_statistics is not None else 0

            movie_watch_time = (
                movie_statistics.watch_time_minutes if movie_statistics is not None else 0
            )

            daily_statistics.append(
                DailyStatisticsResponse(
                    day=day,
                    episodes_watched=episode_watch_count,
                    movies_watched=movie_watch_count,
                    episode_watch_time_minutes=(episode_watch_time),
                    movie_watch_time_minutes=(movie_watch_time),
                    watch_time_minutes=(episode_watch_time + movie_watch_time),
                )
            )

        return StatisticsActivityResponse(
            start_date=start_date,
            end_date=end_date,
            days=daily_statistics,
        )

    def get_habits(
        self,
        *,
        user_id: UUID,
        reference_date: date | None = None,
    ) -> StatisticsHabitsResponse:
        """Return all-time viewing habit statistics.

        A calendar day is active when the user has at least one Episode or
        Movie watch event on that day.

        Episode and Movie activity share the same streak. Multiple viewings,
        including rewatches, still represent a single active calendar day.

        The current streak remains alive when the most recent active day is
        yesterday because the user can still extend it by watching something
        today.
        """

        current_date = (
            reference_date
            or datetime.now(
                UTC,
            ).date()
        )

        episode_first_watched_at = (
            self._episode_watch_event_repository.get_earliest_watched_at_for_user(
                user_id=user_id,
            )
        )

        movie_first_watched_at = (
            self._movie_watch_event_repository.get_earliest_watched_at_for_user(
                user_id=user_id,
            )
        )

        first_viewings = [
            watched_at
            for watched_at in (
                episode_first_watched_at,
                movie_first_watched_at,
            )
            if watched_at is not None
        ]

        if not first_viewings:
            return StatisticsHabitsResponse(
                current_streak_days=0,
                longest_streak_days=0,
                biggest_marathon_watch_time_minutes=0,
                biggest_marathon_day=None,
                longest_binge_episode_count=0,
                longest_binge_day=None,
                average_active_day_watch_time_minutes=0,
                most_active_weekday=None,
                most_active_weekday_watch_count=0,
            )

        earliest_watched_at = min(
            _as_utc(
                watched_at,
            )
            for watched_at in first_viewings
        )

        start_at = datetime.combine(
            earliest_watched_at.date(),
            time.min,
            tzinfo=UTC,
        )

        end_at = datetime.combine(
            current_date + timedelta(days=1),
            time.min,
            tzinfo=UTC,
        )

        episode_rows = self._episode_watch_event_repository.get_daily_statistics_for_period(
            user_id=user_id,
            start_at=start_at,
            end_at=end_at,
        )

        movie_rows = self._movie_watch_event_repository.get_daily_statistics_for_period(
            user_id=user_id,
            start_at=start_at,
            end_at=end_at,
        )

        episode_statistics_by_day = {date.fromisoformat(row.day): row for row in episode_rows}

        movie_statistics_by_day = {date.fromisoformat(row.day): row for row in movie_rows}

        active_days = set(episode_statistics_by_day) | set(movie_statistics_by_day)

        (
            biggest_marathon_watch_time_minutes,
            biggest_marathon_day,
        ) = _biggest_marathon(
            active_days=active_days,
            episode_statistics_by_day=episode_statistics_by_day,
            movie_statistics_by_day=movie_statistics_by_day,
        )

        (
            longest_binge_episode_count,
            longest_binge_day,
        ) = _longest_episode_binge(
            episode_statistics_by_day=episode_statistics_by_day,
        )

        average_active_day_watch_time_minutes = _average_active_day_watch_time(
            active_days=active_days,
            episode_statistics_by_day=episode_statistics_by_day,
            movie_statistics_by_day=movie_statistics_by_day,
        )

        (
            most_active_weekday,
            most_active_weekday_watch_count,
        ) = _most_active_weekday(
            active_days=active_days,
            episode_statistics_by_day=episode_statistics_by_day,
            movie_statistics_by_day=movie_statistics_by_day,
        )

        if not active_days:
            return StatisticsHabitsResponse(
                current_streak_days=0,
                longest_streak_days=0,
                biggest_marathon_watch_time_minutes=0,
                biggest_marathon_day=None,
                most_active_weekday=None,
                most_active_weekday_watch_count=0,
            )

        return StatisticsHabitsResponse(
            current_streak_days=_current_streak_days(
                active_days=active_days,
                current_date=current_date,
            ),
            longest_streak_days=_longest_streak_days(
                active_days=active_days,
            ),
            biggest_marathon_watch_time_minutes=(biggest_marathon_watch_time_minutes),
            biggest_marathon_day=biggest_marathon_day,
            longest_binge_episode_count=(longest_binge_episode_count),
            longest_binge_day=longest_binge_day,
            average_active_day_watch_time_minutes=(average_active_day_watch_time_minutes),
            most_active_weekday=most_active_weekday,
            most_active_weekday_watch_count=(most_active_weekday_watch_count),
        )

    def get_content_insights(
        self,
        *,
        user_id: UUID,
        limit: int = 5,
    ) -> StatisticsContentInsightsResponse:
        """Return ranked all-time content viewing insights."""

        most_watched_shows = self._episode_watch_event_repository.get_most_watched_shows(
            user_id=user_id,
            limit=limit,
        )

        most_rewatched_shows = self._episode_watch_event_repository.get_most_rewatched_shows(
            user_id=user_id,
            limit=limit,
        )

        most_rewatched_episodes = self._episode_watch_event_repository.get_most_rewatched_episodes(
            user_id=user_id,
            limit=limit,
        )

        most_rewatched_movies = self._movie_watch_event_repository.get_most_rewatched_movies(
            user_id=user_id,
            limit=limit,
        )

        top_show_genres = self._episode_watch_event_repository.get_top_show_genres(
            user_id=user_id,
            limit=limit,
        )

        top_movie_genres = self._movie_watch_event_repository.get_top_movie_genres(
            user_id=user_id,
            limit=limit,
        )

        return StatisticsContentInsightsResponse(
            most_watched_shows=[
                StatisticsShowInsightResponse(
                    show_id=item.show_id,
                    tmdb_id=item.tmdb_id,
                    title=item.title,
                    poster_url=item.poster_url,
                    watch_count=item.watch_count,
                    rewatch_count=item.rewatch_count,
                )
                for item in most_watched_shows
            ],
            most_rewatched_shows=[
                StatisticsShowInsightResponse(
                    show_id=item.show_id,
                    tmdb_id=item.tmdb_id,
                    title=item.title,
                    poster_url=item.poster_url,
                    watch_count=item.watch_count,
                    rewatch_count=item.rewatch_count,
                )
                for item in most_rewatched_shows
            ],
            most_rewatched_episodes=[
                StatisticsEpisodeInsightResponse(
                    episode_id=item.episode_id,
                    show_tmdb_id=item.show_tmdb_id,
                    show_title=item.show_title,
                    season_number=item.season_number,
                    episode_number=item.episode_number,
                    episode_title=item.episode_title,
                    still_url=item.still_url,
                    watch_count=item.watch_count,
                    rewatch_count=item.rewatch_count,
                )
                for item in most_rewatched_episodes
            ],
            most_rewatched_movies=[
                StatisticsMovieInsightResponse(
                    movie_id=item.movie_id,
                    tmdb_id=item.tmdb_id,
                    title=item.title,
                    poster_url=item.poster_url,
                    watch_count=item.watch_count,
                    rewatch_count=item.rewatch_count,
                )
                for item in most_rewatched_movies
            ],
            top_show_genres=[
                StatisticsGenreInsightResponse(
                    genre_id=item.genre_id,
                    name=item.name,
                    watch_count=item.watch_count,
                )
                for item in top_show_genres
            ],
            top_movie_genres=[
                StatisticsGenreInsightResponse(
                    genre_id=item.genre_id,
                    name=item.name,
                    watch_count=item.watch_count,
                )
                for item in top_movie_genres
            ],
        )

    def get_library_statistics(
        self,
        *,
        user_id: UUID,
    ) -> StatisticsLibraryResponse:
        """Return current Library statistics for a SofaWatch user."""

        shows_added = self._library_repository.count_shows_by_user(
            user_id=user_id,
        )

        movies_added = self._library_repository.count_movies_by_user(
            user_id=user_id,
        )

        shows_completed = self._library_repository.count_completed_shows_by_user(
            user_id=user_id,
        )

        return StatisticsLibraryResponse(
            shows_added=shows_added,
            movies_added=movies_added,
            shows_completed=shows_completed,
        )

    def get_backlog_statistics(
        self,
        *,
        user_id: UUID,
        reference_date: date | None = None,
    ) -> StatisticsBacklogResponse:
        """Return current backlog and recent catch-up statistics.

        The recent trend window covers the previous 28 calendar days,
        including the reference date.

        Catch-up speed measures unique regular Episodes first watched
        during that window, normalized to Episodes per week.

        Backlog trend compares newly aired regular Episodes with Episodes
        first watched during the same period.
        """

        current_date = (
            reference_date
            or datetime.now(
                UTC,
            ).date()
        )

        backlog_show_ids = self._library_repository.get_backlog_show_ids_for_user(
            user_id=user_id,
        )

        (
            unwatched_aired_episodes,
            unwatched_aired_watch_time_minutes,
        ) = self._episode_progress_repository.get_unwatched_aired_statistics(
            user_id=user_id,
            show_ids=backlog_show_ids,
            as_of=current_date,
        )

        (
            planned_movies,
            planned_movie_watch_time_minutes,
        ) = self._library_repository.get_planned_movie_statistics(
            user_id=user_id,
        )

        future_watch_time_minutes = (
            unwatched_aired_watch_time_minutes + planned_movie_watch_time_minutes
        )

        trend_window_days = 28

        trend_start_date = current_date - timedelta(
            days=trend_window_days - 1,
        )

        trend_start_at = datetime.combine(
            trend_start_date,
            time.min,
            tzinfo=UTC,
        )

        trend_end_at = datetime.combine(
            current_date + timedelta(days=1),
            time.min,
            tzinfo=UTC,
        )

        first_watched_episodes = (
            self._episode_progress_repository.count_first_watched_regular_episodes_between(
                user_id=user_id,
                show_ids=backlog_show_ids,
                start_at=trend_start_at,
                end_at=trend_end_at,
            )
        )

        recently_aired_episodes = self._episode_repository.list_regular_for_shows_between(
            show_ids=backlog_show_ids,
            from_date=trend_start_date,
            to_date=current_date,
        )

        aired_episode_count = len(
            recently_aired_episodes,
        )

        catch_up_speed_episodes_per_week = round(
            first_watched_episodes / 4,
            2,
        )

        backlog_trend_episode_delta = aired_episode_count - first_watched_episodes

        if backlog_trend_episode_delta > 0:
            backlog_trend = StatisticsBacklogTrend.GROWING

        elif backlog_trend_episode_delta < 0:
            backlog_trend = StatisticsBacklogTrend.SHRINKING

        else:
            backlog_trend = StatisticsBacklogTrend.STABLE

        return StatisticsBacklogResponse(
            unwatched_aired_episodes=unwatched_aired_episodes,
            planned_movies=planned_movies,
            future_watch_time_minutes=future_watch_time_minutes,
            catch_up_speed_episodes_per_week=(catch_up_speed_episodes_per_week),
            backlog_trend=backlog_trend,
            backlog_trend_episode_delta=(backlog_trend_episode_delta),
        )


def _as_utc(
    value: datetime,
) -> datetime:
    """Normalize a database datetime to UTC."""

    if value.tzinfo is None:
        return value.replace(
            tzinfo=UTC,
        )

    return value.astimezone(
        UTC,
    )


def _current_streak_days(
    *,
    active_days: set[date],
    current_date: date,
) -> int:
    """Return the active streak that can still be continued today."""

    if current_date in active_days:
        cursor = current_date

    elif (current_date - timedelta(days=1)) in active_days:
        cursor = current_date - timedelta(
            days=1,
        )

    else:
        return 0

    streak = 0

    while cursor in active_days:
        streak += 1

        cursor -= timedelta(
            days=1,
        )

    return streak


def _biggest_marathon(
    *,
    active_days: set[date],
    episode_statistics_by_day: dict,
    movie_statistics_by_day: dict,
) -> tuple[int, date | None]:
    """Return the calendar day with the greatest known watch time.

    Episode and Movie watch time are combined.

    When multiple days have the same maximum watch time, the most recent
    day wins so the result remains deterministic and more relevant to the
    user.
    """

    biggest_minutes = 0
    biggest_day: date | None = None

    for active_day in sorted(
        active_days,
    ):
        episode_statistics = episode_statistics_by_day.get(
            active_day,
        )

        movie_statistics = movie_statistics_by_day.get(
            active_day,
        )

        episode_minutes = (
            episode_statistics.watch_time_minutes if episode_statistics is not None else 0
        )

        movie_minutes = movie_statistics.watch_time_minutes if movie_statistics is not None else 0

        watch_time_minutes = episode_minutes + movie_minutes

        if watch_time_minutes > biggest_minutes or (
            watch_time_minutes == biggest_minutes
            and watch_time_minutes > 0
            and (biggest_day is None or active_day > biggest_day)
        ):
            biggest_minutes = watch_time_minutes
            biggest_day = active_day

    return (
        biggest_minutes,
        biggest_day,
    )


def _longest_streak_days(
    *,
    active_days: set[date],
) -> int:
    """Return the longest historical run of consecutive active days."""

    if not active_days:
        return 0

    longest = 0
    current = 0
    previous_day: date | None = None

    for active_day in sorted(
        active_days,
    ):
        if previous_day is not None and active_day == previous_day + timedelta(days=1):
            current += 1
        else:
            current = 1

        longest = max(
            longest,
            current,
        )

        previous_day = active_day

    return longest


def _longest_episode_binge(
    *,
    episode_statistics_by_day: dict,
) -> tuple[int, date | None]:
    """Return the day with the greatest number of Episode watch events.

    Every Episode watch event counts independently, so rewatches are
    included.

    When multiple days have the same maximum Episode count, the most recent
    day wins.
    """

    longest_binge_count = 0
    longest_binge_day: date | None = None

    for active_day in sorted(
        episode_statistics_by_day,
    ):
        statistics = episode_statistics_by_day[active_day]

        episode_count = statistics.watch_count

        if episode_count > longest_binge_count or (
            episode_count == longest_binge_count
            and episode_count > 0
            and (longest_binge_day is None or active_day > longest_binge_day)
        ):
            longest_binge_count = episode_count
            longest_binge_day = active_day

    return (
        longest_binge_count,
        longest_binge_day,
    )


def _average_active_day_watch_time(
    *,
    active_days: set[date],
    episode_statistics_by_day: dict,
    movie_statistics_by_day: dict,
) -> int:
    """Return average known watch time across active calendar days.

    An active day contains at least one Episode or Movie watch event.

    Rewatches contribute normally to watch time. Viewings without a known
    runtime still make their calendar day active but contribute zero minutes.

    The result is rounded to the nearest whole minute.
    """

    if not active_days:
        return 0

    total_watch_time_minutes = 0

    for active_day in active_days:
        episode_statistics = episode_statistics_by_day.get(
            active_day,
        )

        movie_statistics = movie_statistics_by_day.get(
            active_day,
        )

        if episode_statistics is not None:
            total_watch_time_minutes += episode_statistics.watch_time_minutes

        if movie_statistics is not None:
            total_watch_time_minutes += movie_statistics.watch_time_minutes

    return int(total_watch_time_minutes / len(active_days) + 0.5)


def _most_active_weekday(
    *,
    active_days: set[date],
    episode_statistics_by_day: dict,
    movie_statistics_by_day: dict,
) -> tuple[str | None, int]:
    """Return the weekday containing the greatest number of watch events.

    Episode and Movie watch events are combined, and rewatches count
    independently.

    Ties are resolved first by total known watch time, then by weekday order
    from Monday to Sunday.
    """

    if not active_days:
        return None, 0

    weekday_counts = [0] * 7
    weekday_watch_times = [0] * 7

    for active_day in active_days:
        weekday_index = active_day.weekday()

        episode_statistics = episode_statistics_by_day.get(
            active_day,
        )

        movie_statistics = movie_statistics_by_day.get(
            active_day,
        )

        if episode_statistics is not None:
            weekday_counts[weekday_index] += episode_statistics.watch_count

            weekday_watch_times[weekday_index] += episode_statistics.watch_time_minutes

        if movie_statistics is not None:
            weekday_counts[weekday_index] += movie_statistics.watch_count

            weekday_watch_times[weekday_index] += movie_statistics.watch_time_minutes

    best_index = max(
        range(7),
        key=lambda index: (
            weekday_counts[index],
            weekday_watch_times[index],
            -index,
        ),
    )

    if weekday_counts[best_index] == 0:
        return None, 0

    weekday_names = (
        "Monday",
        "Tuesday",
        "Wednesday",
        "Thursday",
        "Friday",
        "Saturday",
        "Sunday",
    )

    return (
        weekday_names[best_index],
        weekday_counts[best_index],
    )
