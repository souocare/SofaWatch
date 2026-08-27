from datetime import UTC, date, datetime
from types import SimpleNamespace
from unittest.mock import Mock
from uuid import uuid4

from app.repositories.episode import EpisodeRepository
from app.repositories.episode_progress import EpisodeProgressRepository
from app.repositories.episode_watch_event import EpisodeWatchEventRepository
from app.repositories.library import LibraryRepository
from app.repositories.movie_watch_event import MovieWatchEventRepository
from app.repositories.statistics_insights import (
    EpisodeViewingInsight,
    GenreViewingInsight,
    MovieViewingInsight,
    ShowViewingInsight,
)
from app.repositories.viewing_statistics import DailyViewingStatistics
from app.schemas.statistics import StatisticsActivityPeriod
from app.services.statistics import StatisticsService


def create_statistics_service(
    *,
    episode_watch_event_repository: EpisodeWatchEventRepository,
    movie_watch_event_repository: MovieWatchEventRepository,
    library_repository: LibraryRepository | None = None,
    episode_repository: EpisodeRepository | None = None,
    episode_progress_repository: EpisodeProgressRepository | None = None,
) -> StatisticsService:
    """Create StatisticsService with isolated repository dependencies."""

    return StatisticsService(
        episode_watch_event_repository=episode_watch_event_repository,
        movie_watch_event_repository=movie_watch_event_repository,
        library_repository=(
            library_repository
            or Mock(
                spec=LibraryRepository,
            )
        ),
        episode_repository=(
            episode_repository
            or Mock(
                spec=EpisodeRepository,
            )
        ),
        episode_progress_repository=(
            episode_progress_repository
            or Mock(
                spec=EpisodeProgressRepository,
            )
        ),
    )


def test_weekly_summary_combines_episode_and_movie_statistics() -> None:
    """Combine Episode and Movie viewing statistics into one summary."""

    user_id = uuid4()

    episode_repository = Mock(
        spec=EpisodeWatchEventRepository,
    )

    movie_repository = Mock(
        spec=MovieWatchEventRepository,
    )

    episode_repository.get_statistics_for_period.return_value = (
        8,
        416,
    )

    movie_repository.get_statistics_for_period.return_value = (
        2,
        226,
    )

    service = create_statistics_service(
        episode_watch_event_repository=episode_repository,
        movie_watch_event_repository=movie_repository,
    )

    result = service.get_weekly_summary(
        user_id=user_id,
        reference_date=date(
            2026,
            8,
            19,
        ),
    )

    assert result.week_start == date(
        2026,
        8,
        17,
    )

    assert result.week_end == date(
        2026,
        8,
        23,
    )

    assert result.episodes_watched == 8
    assert result.movies_watched == 2

    assert result.watch_time_minutes == 642

    expected_start = datetime(
        2026,
        8,
        17,
        tzinfo=UTC,
    )

    expected_end = datetime(
        2026,
        8,
        24,
        tzinfo=UTC,
    )

    episode_repository.get_statistics_for_period.assert_called_once_with(
        user_id=user_id,
        start_at=expected_start,
        end_at=expected_end,
    )

    movie_repository.get_statistics_for_period.assert_called_once_with(
        user_id=user_id,
        start_at=expected_start,
        end_at=expected_end,
    )


def test_weekly_summary_returns_zero_statistics_without_viewings() -> None:
    """Return an explicit zero summary when the user watched nothing."""

    user_id = uuid4()

    episode_repository = Mock(
        spec=EpisodeWatchEventRepository,
    )

    movie_repository = Mock(
        spec=MovieWatchEventRepository,
    )

    episode_repository.get_statistics_for_period.return_value = (
        0,
        0,
    )

    movie_repository.get_statistics_for_period.return_value = (
        0,
        0,
    )

    service = create_statistics_service(
        episode_watch_event_repository=episode_repository,
        movie_watch_event_repository=movie_repository,
    )

    result = service.get_weekly_summary(
        user_id=user_id,
        reference_date=date(
            2026,
            8,
            17,
        ),
    )

    assert result.week_start == date(
        2026,
        8,
        17,
    )

    assert result.week_end == date(
        2026,
        8,
        23,
    )

    assert result.episodes_watched == 0
    assert result.movies_watched == 0
    assert result.watch_time_minutes == 0


def test_weekly_summary_uses_monday_for_every_day_of_week() -> None:
    """Keep the same Monday-to-Sunday range throughout the week."""

    user_id = uuid4()

    for reference_date in (
        date(2026, 8, 17),
        date(2026, 8, 18),
        date(2026, 8, 19),
        date(2026, 8, 20),
        date(2026, 8, 21),
        date(2026, 8, 22),
        date(2026, 8, 23),
    ):
        episode_repository = Mock(
            spec=EpisodeWatchEventRepository,
        )

        movie_repository = Mock(
            spec=MovieWatchEventRepository,
        )

        episode_repository.get_statistics_for_period.return_value = (
            0,
            0,
        )

        movie_repository.get_statistics_for_period.return_value = (
            0,
            0,
        )

        service = create_statistics_service(
            episode_watch_event_repository=episode_repository,
            movie_watch_event_repository=movie_repository,
        )

        result = service.get_weekly_summary(
            user_id=user_id,
            reference_date=reference_date,
        )

        assert result.week_start == date(
            2026,
            8,
            17,
        )

        assert result.week_end == date(
            2026,
            8,
            23,
        )


def test_weekly_summary_rolls_over_on_next_monday() -> None:
    """Start a new summary period when the next Monday begins."""

    user_id = uuid4()

    episode_repository = Mock(
        spec=EpisodeWatchEventRepository,
    )

    movie_repository = Mock(
        spec=MovieWatchEventRepository,
    )

    episode_repository.get_statistics_for_period.return_value = (
        1,
        52,
    )

    movie_repository.get_statistics_for_period.return_value = (
        1,
        120,
    )

    service = create_statistics_service(
        episode_watch_event_repository=episode_repository,
        movie_watch_event_repository=movie_repository,
    )

    result = service.get_weekly_summary(
        user_id=user_id,
        reference_date=date(
            2026,
            8,
            24,
        ),
    )

    assert result.week_start == date(
        2026,
        8,
        24,
    )

    assert result.week_end == date(
        2026,
        8,
        30,
    )

    assert result.watch_time_minutes == 172


def test_get_summary_combines_lifetime_viewing_statistics() -> None:
    episode_repository = Mock(
        spec=EpisodeWatchEventRepository,
    )

    movie_repository = Mock(
        spec=MovieWatchEventRepository,
    )

    episode_repository.count_watched_shows.return_value = 12

    episode_repository.get_all_time_statistics.return_value = (
        125,  # watch_count
        100,  # unique_count
        25,  # rewatch_count
        6250,  # watch_time_minutes
        1250,  # rewatch_time_minutes
    )

    movie_repository.get_all_time_statistics.return_value = (
        34,  # watch_count
        30,  # unique_count
        4,  # rewatch_count
        4200,  # watch_time_minutes
        500,  # rewatch_time_minutes
    )

    service = create_statistics_service(
        episode_watch_event_repository=episode_repository,
        movie_watch_event_repository=movie_repository,
    )

    user_id = uuid4()

    result = service.get_summary(
        user_id=user_id,
    )

    assert result.shows_watched == 12

    assert result.episodes.watch_count == 125
    assert result.episodes.unique_count == 100
    assert result.episodes.rewatch_count == 25
    assert result.episodes.watch_time_minutes == 6250
    assert result.episodes.rewatch_time_minutes == 1250

    assert result.movies.watch_count == 34
    assert result.movies.unique_count == 30
    assert result.movies.rewatch_count == 4
    assert result.movies.watch_time_minutes == 4200
    assert result.movies.rewatch_time_minutes == 500

    assert result.watch_time_minutes == 10450
    assert result.rewatch_time_minutes == 1750

    episode_repository.count_watched_shows.assert_called_once_with(
        user_id=user_id,
    )

    episode_repository.get_all_time_statistics.assert_called_once_with(
        user_id=user_id,
    )

    movie_repository.get_all_time_statistics.assert_called_once_with(
        user_id=user_id,
    )


def test_get_summary_returns_zero_values_without_viewings() -> None:
    episode_repository = Mock(
        spec=EpisodeWatchEventRepository,
    )

    movie_repository = Mock(
        spec=MovieWatchEventRepository,
    )

    episode_repository.count_watched_shows.return_value = 0

    episode_repository.get_all_time_statistics.return_value = (
        0,
        0,
        0,
        0,
        0,
    )

    movie_repository.get_all_time_statistics.return_value = (
        0,
        0,
        0,
        0,
        0,
    )

    service = create_statistics_service(
        episode_watch_event_repository=episode_repository,
        movie_watch_event_repository=movie_repository,
    )

    result = service.get_summary(
        user_id=uuid4(),
    )

    assert result.shows_watched == 0

    assert result.episodes.watch_count == 0
    assert result.episodes.unique_count == 0
    assert result.episodes.rewatch_count == 0
    assert result.episodes.watch_time_minutes == 0
    assert result.episodes.rewatch_time_minutes == 0

    assert result.movies.watch_count == 0
    assert result.movies.unique_count == 0
    assert result.movies.rewatch_count == 0
    assert result.movies.watch_time_minutes == 0
    assert result.movies.rewatch_time_minutes == 0

    assert result.watch_time_minutes == 0
    assert result.rewatch_time_minutes == 0


def test_get_activity_combines_episode_and_movie_daily_statistics() -> None:
    episode_repository = Mock(
        spec=EpisodeWatchEventRepository,
    )

    movie_repository = Mock(
        spec=MovieWatchEventRepository,
    )

    episode_repository.get_daily_statistics_for_period.return_value = [
        DailyViewingStatistics(
            day="2026-08-13",
            watch_count=2,
            watch_time_minutes=100,
        ),
        DailyViewingStatistics(
            day="2026-08-17",
            watch_count=3,
            watch_time_minutes=150,
        ),
    ]

    movie_repository.get_daily_statistics_for_period.return_value = [
        DailyViewingStatistics(
            day="2026-08-17",
            watch_count=1,
            watch_time_minutes=120,
        ),
        DailyViewingStatistics(
            day="2026-08-18",
            watch_count=1,
            watch_time_minutes=155,
        ),
    ]

    service = create_statistics_service(
        episode_watch_event_repository=episode_repository,
        movie_watch_event_repository=movie_repository,
    )

    user_id = uuid4()

    result = service.get_activity(
        user_id=user_id,
        period=StatisticsActivityPeriod.DAYS_7,
        reference_date=date(2026, 8, 18),
    )

    assert result.start_date == date(
        2026,
        8,
        12,
    )

    assert result.end_date == date(
        2026,
        8,
        18,
    )

    assert len(result.days) == 7

    assert [item.day for item in result.days] == [
        date(2026, 8, 12),
        date(2026, 8, 13),
        date(2026, 8, 14),
        date(2026, 8, 15),
        date(2026, 8, 16),
        date(2026, 8, 17),
        date(2026, 8, 18),
    ]

    august_13 = result.days[1]

    assert august_13.episodes_watched == 2
    assert august_13.movies_watched == 0
    assert august_13.episode_watch_time_minutes == 100
    assert august_13.movie_watch_time_minutes == 0
    assert august_13.watch_time_minutes == 100

    august_17 = result.days[5]

    assert august_17.episodes_watched == 3
    assert august_17.movies_watched == 1
    assert august_17.episode_watch_time_minutes == 150
    assert august_17.movie_watch_time_minutes == 120
    assert august_17.watch_time_minutes == 270

    august_18 = result.days[6]

    assert august_18.episodes_watched == 0
    assert august_18.movies_watched == 1
    assert august_18.watch_time_minutes == 155


def test_get_activity_fills_days_without_viewing_with_zeroes() -> None:
    episode_repository = Mock(
        spec=EpisodeWatchEventRepository,
    )

    movie_repository = Mock(
        spec=MovieWatchEventRepository,
    )

    episode_repository.get_daily_statistics_for_period.return_value = []
    movie_repository.get_daily_statistics_for_period.return_value = []

    service = create_statistics_service(
        episode_watch_event_repository=episode_repository,
        movie_watch_event_repository=movie_repository,
    )

    result = service.get_activity(
        user_id=uuid4(),
        period=StatisticsActivityPeriod.DAYS_7,
        reference_date=date(2026, 8, 18),
    )

    assert len(result.days) == 7

    for item in result.days:
        assert item.episodes_watched == 0
        assert item.movies_watched == 0
        assert item.episode_watch_time_minutes == 0
        assert item.movie_watch_time_minutes == 0
        assert item.watch_time_minutes == 0


def test_get_activity_supports_fourteen_days() -> None:
    episode_repository = Mock(
        spec=EpisodeWatchEventRepository,
    )

    movie_repository = Mock(
        spec=MovieWatchEventRepository,
    )

    episode_repository.get_daily_statistics_for_period.return_value = []
    movie_repository.get_daily_statistics_for_period.return_value = []

    service = create_statistics_service(
        episode_watch_event_repository=episode_repository,
        movie_watch_event_repository=movie_repository,
    )

    result = service.get_activity(
        user_id=uuid4(),
        period=StatisticsActivityPeriod.DAYS_14,
        reference_date=date(2026, 8, 18),
    )

    assert result.start_date == date(
        2026,
        8,
        5,
    )

    assert result.end_date == date(
        2026,
        8,
        18,
    )

    assert len(result.days) == 14


def test_get_activity_supports_thirty_day_period() -> None:
    episode_repository = Mock(
        spec=EpisodeWatchEventRepository,
    )

    movie_repository = Mock(
        spec=MovieWatchEventRepository,
    )

    episode_repository.get_daily_statistics_for_period.return_value = []
    movie_repository.get_daily_statistics_for_period.return_value = []

    service = create_statistics_service(
        episode_watch_event_repository=episode_repository,
        movie_watch_event_repository=movie_repository,
    )

    result = service.get_activity(
        user_id=uuid4(),
        period=StatisticsActivityPeriod.DAYS_30,
        reference_date=date(
            2026,
            8,
            18,
        ),
    )

    assert result.start_date == date(
        2026,
        7,
        20,
    )

    assert result.end_date == date(
        2026,
        8,
        18,
    )

    assert len(result.days) == 30


def test_activity_supports_thirty_days() -> None:
    episode_repository = Mock(
        spec=EpisodeWatchEventRepository,
    )
    movie_repository = Mock(
        spec=MovieWatchEventRepository,
    )

    episode_repository.get_daily_statistics_for_period.return_value = []
    movie_repository.get_daily_statistics_for_period.return_value = []

    service = create_statistics_service(
        episode_watch_event_repository=episode_repository,
        movie_watch_event_repository=movie_repository,
    )

    result = service.get_activity(
        user_id=uuid4(),
        period=StatisticsActivityPeriod.DAYS_30,
        reference_date=date(2026, 8, 18),
    )

    assert result.start_date == date(2026, 7, 20)
    assert result.end_date == date(2026, 8, 18)
    assert len(result.days) == 30


def test_activity_supports_ninety_days() -> None:
    episode_repository = Mock(
        spec=EpisodeWatchEventRepository,
    )
    movie_repository = Mock(
        spec=MovieWatchEventRepository,
    )

    episode_repository.get_daily_statistics_for_period.return_value = []
    movie_repository.get_daily_statistics_for_period.return_value = []

    service = create_statistics_service(
        episode_watch_event_repository=episode_repository,
        movie_watch_event_repository=movie_repository,
    )

    result = service.get_activity(
        user_id=uuid4(),
        period=StatisticsActivityPeriod.DAYS_90,
        reference_date=date(2026, 8, 18),
    )

    assert result.start_date == date(2026, 5, 21)
    assert result.end_date == date(2026, 8, 18)
    assert len(result.days) == 90


def test_activity_supports_one_year() -> None:
    episode_repository = Mock(
        spec=EpisodeWatchEventRepository,
    )
    movie_repository = Mock(
        spec=MovieWatchEventRepository,
    )

    episode_repository.get_daily_statistics_for_period.return_value = []
    movie_repository.get_daily_statistics_for_period.return_value = []

    service = create_statistics_service(
        episode_watch_event_repository=episode_repository,
        movie_watch_event_repository=movie_repository,
    )

    result = service.get_activity(
        user_id=uuid4(),
        period=StatisticsActivityPeriod.YEAR_1,
        reference_date=date(2026, 8, 18),
    )

    assert result.start_date == date(2025, 8, 19)
    assert result.end_date == date(2026, 8, 18)
    assert len(result.days) == 365


def test_activity_all_starts_at_earliest_viewing() -> None:
    episode_repository = Mock(
        spec=EpisodeWatchEventRepository,
    )
    movie_repository = Mock(
        spec=MovieWatchEventRepository,
    )

    episode_repository.get_earliest_watched_at_for_user.return_value = datetime(
        2024,
        5,
        10,
        20,
        0,
        tzinfo=UTC,
    )

    movie_repository.get_earliest_watched_at_for_user.return_value = datetime(
        2023,
        11,
        2,
        21,
        0,
        tzinfo=UTC,
    )

    episode_repository.get_daily_statistics_for_period.return_value = []
    movie_repository.get_daily_statistics_for_period.return_value = []

    service = create_statistics_service(
        episode_watch_event_repository=episode_repository,
        movie_watch_event_repository=movie_repository,
    )

    result = service.get_activity(
        user_id=uuid4(),
        period=StatisticsActivityPeriod.ALL,
        reference_date=date(2026, 8, 18),
    )

    assert result.start_date == date(2023, 11, 2)
    assert result.end_date == date(2026, 8, 18)

    expected_days = (date(2026, 8, 18) - date(2023, 11, 2)).days + 1

    assert len(result.days) == expected_days


def test_activity_all_returns_today_without_viewing_history() -> None:
    episode_repository = Mock(
        spec=EpisodeWatchEventRepository,
    )
    movie_repository = Mock(
        spec=MovieWatchEventRepository,
    )

    episode_repository.get_earliest_watched_at_for_user.return_value = None
    movie_repository.get_earliest_watched_at_for_user.return_value = None

    episode_repository.get_daily_statistics_for_period.return_value = []
    movie_repository.get_daily_statistics_for_period.return_value = []

    service = create_statistics_service(
        episode_watch_event_repository=episode_repository,
        movie_watch_event_repository=movie_repository,
    )

    result = service.get_activity(
        user_id=uuid4(),
        period=StatisticsActivityPeriod.ALL,
        reference_date=date(2026, 8, 18),
    )

    assert result.start_date == date(2026, 8, 18)
    assert result.end_date == date(2026, 8, 18)
    assert len(result.days) == 1

    assert result.days[0].day == date(2026, 8, 18)
    assert result.days[0].episodes_watched == 0
    assert result.days[0].movies_watched == 0
    assert result.days[0].watch_time_minutes == 0


def test_get_habits_calculates_current_and_longest_streaks() -> None:
    episode_repository = Mock(
        spec=EpisodeWatchEventRepository,
    )

    movie_repository = Mock(
        spec=MovieWatchEventRepository,
    )

    episode_repository.get_earliest_watched_at_for_user.return_value = datetime(
        2026,
        8,
        10,
        tzinfo=UTC,
    )

    movie_repository.get_earliest_watched_at_for_user.return_value = None

    episode_repository.get_daily_statistics_for_period.return_value = [
        SimpleNamespace(
            day="2026-08-10",
            watch_time_minutes=0,
            watch_count=1,
        ),
        SimpleNamespace(
            day="2026-08-11",
            watch_time_minutes=0,
            watch_count=1,
        ),
        SimpleNamespace(
            day="2026-08-12",
            watch_time_minutes=0,
            watch_count=1,
        ),
        SimpleNamespace(
            day="2026-08-16",
            watch_time_minutes=0,
            watch_count=1,
        ),
        SimpleNamespace(
            day="2026-08-17",
            watch_time_minutes=0,
            watch_count=1,
        ),
        SimpleNamespace(
            day="2026-08-18",
            watch_time_minutes=0,
            watch_count=1,
        ),
    ]

    movie_repository.get_daily_statistics_for_period.return_value = []

    service = create_statistics_service(
        episode_watch_event_repository=episode_repository,
        movie_watch_event_repository=movie_repository,
    )

    result = service.get_habits(
        user_id=uuid4(),
        reference_date=date(
            2026,
            8,
            18,
        ),
    )

    assert result.current_streak_days == 3
    assert result.longest_streak_days == 3


def test_get_habits_keeps_current_streak_alive_from_yesterday() -> None:
    episode_repository = Mock(
        spec=EpisodeWatchEventRepository,
    )

    movie_repository = Mock(
        spec=MovieWatchEventRepository,
    )

    episode_repository.get_earliest_watched_at_for_user.return_value = datetime(
        2026,
        8,
        15,
        tzinfo=UTC,
    )

    movie_repository.get_earliest_watched_at_for_user.return_value = None

    episode_repository.get_daily_statistics_for_period.return_value = [
        SimpleNamespace(
            day="2026-08-15",
            watch_time_minutes=0,
            watch_count=1,
        ),
        SimpleNamespace(
            day="2026-08-16",
            watch_time_minutes=0,
            watch_count=1,
        ),
        SimpleNamespace(
            day="2026-08-17",
            watch_time_minutes=0,
            watch_count=1,
        ),
    ]

    movie_repository.get_daily_statistics_for_period.return_value = []

    service = create_statistics_service(
        episode_watch_event_repository=episode_repository,
        movie_watch_event_repository=movie_repository,
    )

    result = service.get_habits(
        user_id=uuid4(),
        reference_date=date(
            2026,
            8,
            18,
        ),
    )

    assert result.current_streak_days == 3
    assert result.longest_streak_days == 3


def test_get_habits_returns_zero_current_streak_when_last_activity_is_old() -> None:
    episode_repository = Mock(
        spec=EpisodeWatchEventRepository,
    )

    movie_repository = Mock(
        spec=MovieWatchEventRepository,
    )

    episode_repository.get_earliest_watched_at_for_user.return_value = datetime(
        2026,
        8,
        10,
        tzinfo=UTC,
    )

    movie_repository.get_earliest_watched_at_for_user.return_value = None

    episode_repository.get_daily_statistics_for_period.return_value = [
        SimpleNamespace(
            day="2026-08-10",
            watch_time_minutes=0,
            watch_count=1,
        ),
        SimpleNamespace(
            day="2026-08-11",
            watch_time_minutes=0,
            watch_count=1,
        ),
        SimpleNamespace(
            day="2026-08-12",
            watch_time_minutes=0,
            watch_count=1,
        ),
    ]

    movie_repository.get_daily_statistics_for_period.return_value = []

    service = create_statistics_service(
        episode_watch_event_repository=episode_repository,
        movie_watch_event_repository=movie_repository,
    )

    result = service.get_habits(
        user_id=uuid4(),
        reference_date=date(
            2026,
            8,
            18,
        ),
    )

    assert result.current_streak_days == 0
    assert result.longest_streak_days == 3


def test_get_habits_combines_episode_and_movie_active_days() -> None:
    episode_repository = Mock(
        spec=EpisodeWatchEventRepository,
    )

    movie_repository = Mock(
        spec=MovieWatchEventRepository,
    )

    episode_repository.get_earliest_watched_at_for_user.return_value = datetime(
        2026,
        8,
        15,
        tzinfo=UTC,
    )

    movie_repository.get_earliest_watched_at_for_user.return_value = datetime(
        2026,
        8,
        16,
        tzinfo=UTC,
    )

    episode_repository.get_daily_statistics_for_period.return_value = [
        SimpleNamespace(
            day="2026-08-15",
            watch_time_minutes=0,
            watch_count=1,
        ),
        SimpleNamespace(
            day="2026-08-17",
            watch_time_minutes=0,
            watch_count=1,
        ),
    ]

    movie_repository.get_daily_statistics_for_period.return_value = [
        SimpleNamespace(
            day="2026-08-16",
            watch_time_minutes=0,
            watch_count=1,
        ),
        SimpleNamespace(
            day="2026-08-18",
            watch_time_minutes=0,
            watch_count=1,
        ),
    ]

    service = create_statistics_service(
        episode_watch_event_repository=episode_repository,
        movie_watch_event_repository=movie_repository,
    )

    result = service.get_habits(
        user_id=uuid4(),
        reference_date=date(
            2026,
            8,
            18,
        ),
    )

    assert result.current_streak_days == 4
    assert result.longest_streak_days == 4


def test_get_habits_counts_shared_episode_and_movie_day_once() -> None:
    episode_repository = Mock(
        spec=EpisodeWatchEventRepository,
    )

    movie_repository = Mock(
        spec=MovieWatchEventRepository,
    )

    watched_at = datetime(
        2026,
        8,
        18,
        tzinfo=UTC,
    )

    episode_repository.get_earliest_watched_at_for_user.return_value = watched_at

    movie_repository.get_earliest_watched_at_for_user.return_value = watched_at

    episode_repository.get_daily_statistics_for_period.return_value = [
        SimpleNamespace(
            day="2026-08-18",
            watch_time_minutes=0,
            watch_count=1,
        ),
    ]

    movie_repository.get_daily_statistics_for_period.return_value = [
        SimpleNamespace(
            day="2026-08-18",
            watch_time_minutes=0,
            watch_count=1,
        ),
    ]

    service = create_statistics_service(
        episode_watch_event_repository=episode_repository,
        movie_watch_event_repository=movie_repository,
    )

    result = service.get_habits(
        user_id=uuid4(),
        reference_date=date(
            2026,
            8,
            18,
        ),
    )

    assert result.current_streak_days == 1
    assert result.longest_streak_days == 1


def test_get_habits_returns_zeroes_without_viewing_history() -> None:
    episode_repository = Mock(
        spec=EpisodeWatchEventRepository,
    )

    movie_repository = Mock(
        spec=MovieWatchEventRepository,
    )

    episode_repository.get_earliest_watched_at_for_user.return_value = None
    movie_repository.get_earliest_watched_at_for_user.return_value = None

    service = create_statistics_service(
        episode_watch_event_repository=episode_repository,
        movie_watch_event_repository=movie_repository,
    )

    result = service.get_habits(
        user_id=uuid4(),
        reference_date=date(
            2026,
            8,
            18,
        ),
    )

    assert result.current_streak_days == 0
    assert result.longest_streak_days == 0

    episode_repository.get_daily_statistics_for_period.assert_not_called()
    movie_repository.get_daily_statistics_for_period.assert_not_called()


def test_get_habits_calculates_biggest_marathon_from_episode_and_movie_time() -> None:
    episode_repository = Mock(
        spec=EpisodeWatchEventRepository,
    )

    movie_repository = Mock(
        spec=MovieWatchEventRepository,
    )

    episode_repository.get_earliest_watched_at_for_user.return_value = datetime(
        2026,
        8,
        10,
        tzinfo=UTC,
    )

    movie_repository.get_earliest_watched_at_for_user.return_value = datetime(
        2026,
        8,
        10,
        tzinfo=UTC,
    )

    episode_repository.get_daily_statistics_for_period.return_value = [
        SimpleNamespace(
            day="2026-08-10",
            watch_time_minutes=100,
            watch_count=1,
        ),
        SimpleNamespace(
            day="2026-08-12",
            watch_time_minutes=180,
            watch_count=1,
        ),
    ]

    movie_repository.get_daily_statistics_for_period.return_value = [
        SimpleNamespace(
            day="2026-08-10",
            watch_time_minutes=155,
            watch_count=1,
        ),
        SimpleNamespace(
            day="2026-08-11",
            watch_time_minutes=120,
            watch_count=1,
        ),
        SimpleNamespace(
            day="2026-08-12",
            watch_time_minutes=90,
            watch_count=1,
        ),
    ]

    service = create_statistics_service(
        episode_watch_event_repository=episode_repository,
        movie_watch_event_repository=movie_repository,
    )

    result = service.get_habits(
        user_id=uuid4(),
        reference_date=date(
            2026,
            8,
            18,
        ),
    )

    # 12 August: 180 Episode minutes + 90 Movie minutes.
    assert result.biggest_marathon_watch_time_minutes == 270
    assert result.biggest_marathon_day == date(
        2026,
        8,
        12,
    )


def test_get_habits_uses_most_recent_day_when_marathon_time_is_tied() -> None:
    episode_repository = Mock(
        spec=EpisodeWatchEventRepository,
    )

    movie_repository = Mock(
        spec=MovieWatchEventRepository,
    )

    episode_repository.get_earliest_watched_at_for_user.return_value = datetime(
        2026,
        8,
        10,
        tzinfo=UTC,
    )

    movie_repository.get_earliest_watched_at_for_user.return_value = None

    episode_repository.get_daily_statistics_for_period.return_value = [
        SimpleNamespace(
            day="2026-08-10",
            watch_time_minutes=180,
            watch_count=1,
        ),
        SimpleNamespace(
            day="2026-08-15",
            watch_time_minutes=180,
            watch_count=1,
        ),
    ]

    movie_repository.get_daily_statistics_for_period.return_value = []

    service = create_statistics_service(
        episode_watch_event_repository=episode_repository,
        movie_watch_event_repository=movie_repository,
    )

    result = service.get_habits(
        user_id=uuid4(),
        reference_date=date(
            2026,
            8,
            18,
        ),
    )

    assert result.biggest_marathon_watch_time_minutes == 180
    assert result.biggest_marathon_day == date(
        2026,
        8,
        15,
    )


def test_get_habits_returns_no_marathon_day_when_all_watch_time_is_unknown() -> None:
    episode_repository = Mock(
        spec=EpisodeWatchEventRepository,
    )

    movie_repository = Mock(
        spec=MovieWatchEventRepository,
    )

    episode_repository.get_earliest_watched_at_for_user.return_value = datetime(
        2026,
        8,
        18,
        tzinfo=UTC,
    )

    movie_repository.get_earliest_watched_at_for_user.return_value = None

    episode_repository.get_daily_statistics_for_period.return_value = [
        SimpleNamespace(
            day="2026-08-18",
            watch_time_minutes=0,
            watch_count=1,
        ),
    ]

    movie_repository.get_daily_statistics_for_period.return_value = []

    service = create_statistics_service(
        episode_watch_event_repository=episode_repository,
        movie_watch_event_repository=movie_repository,
    )

    result = service.get_habits(
        user_id=uuid4(),
        reference_date=date(
            2026,
            8,
            18,
        ),
    )

    assert result.current_streak_days == 1
    assert result.longest_streak_days == 1

    assert result.biggest_marathon_watch_time_minutes == 0
    assert result.biggest_marathon_day is None


def test_get_habits_calculates_longest_episode_binge() -> None:
    episode_repository = Mock(
        spec=EpisodeWatchEventRepository,
    )

    movie_repository = Mock(
        spec=MovieWatchEventRepository,
    )

    episode_repository.get_earliest_watched_at_for_user.return_value = datetime(
        2026,
        8,
        10,
        tzinfo=UTC,
    )

    movie_repository.get_earliest_watched_at_for_user.return_value = None

    episode_repository.get_daily_statistics_for_period.return_value = [
        SimpleNamespace(
            day="2026-08-10",
            watch_count=3,
            watch_time_minutes=150,
        ),
        SimpleNamespace(
            day="2026-08-12",
            watch_count=7,
            watch_time_minutes=350,
        ),
        SimpleNamespace(
            day="2026-08-15",
            watch_count=4,
            watch_time_minutes=200,
        ),
    ]

    movie_repository.get_daily_statistics_for_period.return_value = []

    service = create_statistics_service(
        episode_watch_event_repository=episode_repository,
        movie_watch_event_repository=movie_repository,
    )

    result = service.get_habits(
        user_id=uuid4(),
        reference_date=date(
            2026,
            8,
            18,
        ),
    )

    assert result.longest_binge_episode_count == 7

    assert result.longest_binge_day == date(
        2026,
        8,
        12,
    )


def test_get_habits_uses_most_recent_day_when_episode_binge_is_tied() -> None:
    episode_repository = Mock(
        spec=EpisodeWatchEventRepository,
    )

    movie_repository = Mock(
        spec=MovieWatchEventRepository,
    )

    episode_repository.get_earliest_watched_at_for_user.return_value = datetime(
        2026,
        8,
        10,
        tzinfo=UTC,
    )

    movie_repository.get_earliest_watched_at_for_user.return_value = None

    episode_repository.get_daily_statistics_for_period.return_value = [
        SimpleNamespace(
            day="2026-08-10",
            watch_count=5,
            watch_time_minutes=250,
        ),
        SimpleNamespace(
            day="2026-08-15",
            watch_count=5,
            watch_time_minutes=250,
        ),
    ]

    movie_repository.get_daily_statistics_for_period.return_value = []

    service = create_statistics_service(
        episode_watch_event_repository=episode_repository,
        movie_watch_event_repository=movie_repository,
    )

    result = service.get_habits(
        user_id=uuid4(),
        reference_date=date(
            2026,
            8,
            18,
        ),
    )

    assert result.longest_binge_episode_count == 5

    assert result.longest_binge_day == date(
        2026,
        8,
        15,
    )


def test_get_habits_returns_no_episode_binge_for_movie_only_history() -> None:
    episode_repository = Mock(
        spec=EpisodeWatchEventRepository,
    )

    movie_repository = Mock(
        spec=MovieWatchEventRepository,
    )

    episode_repository.get_earliest_watched_at_for_user.return_value = None

    movie_repository.get_earliest_watched_at_for_user.return_value = datetime(
        2026,
        8,
        18,
        tzinfo=UTC,
    )

    episode_repository.get_daily_statistics_for_period.return_value = []

    movie_repository.get_daily_statistics_for_period.return_value = [
        SimpleNamespace(
            day="2026-08-18",
            watch_count=3,
            watch_time_minutes=300,
        ),
    ]

    service = create_statistics_service(
        episode_watch_event_repository=episode_repository,
        movie_watch_event_repository=movie_repository,
    )

    result = service.get_habits(
        user_id=uuid4(),
        reference_date=date(
            2026,
            8,
            18,
        ),
    )

    assert result.longest_binge_episode_count == 0
    assert result.longest_binge_day is None


def test_get_habits_calculates_average_active_day_watch_time() -> None:
    episode_repository = Mock(
        spec=EpisodeWatchEventRepository,
    )

    movie_repository = Mock(
        spec=MovieWatchEventRepository,
    )

    episode_repository.get_earliest_watched_at_for_user.return_value = datetime(
        2026,
        8,
        10,
        tzinfo=UTC,
    )

    movie_repository.get_earliest_watched_at_for_user.return_value = datetime(
        2026,
        8,
        11,
        tzinfo=UTC,
    )

    episode_repository.get_daily_statistics_for_period.return_value = [
        SimpleNamespace(
            day="2026-08-10",
            watch_count=2,
            watch_time_minutes=100,
        ),
        SimpleNamespace(
            day="2026-08-11",
            watch_count=1,
            watch_time_minutes=50,
        ),
    ]

    movie_repository.get_daily_statistics_for_period.return_value = [
        SimpleNamespace(
            day="2026-08-11",
            watch_count=1,
            watch_time_minutes=120,
        ),
        SimpleNamespace(
            day="2026-08-12",
            watch_count=1,
            watch_time_minutes=90,
        ),
    ]

    service = create_statistics_service(
        episode_watch_event_repository=episode_repository,
        movie_watch_event_repository=movie_repository,
    )

    result = service.get_habits(
        user_id=uuid4(),
        reference_date=date(
            2026,
            8,
            18,
        ),
    )

    # Active days:
    # Aug 10 = 100
    # Aug 11 = 50 + 120 = 170
    # Aug 12 = 90
    #
    # 360 / 3 = 120.
    assert result.average_active_day_watch_time_minutes == 120


def test_get_habits_counts_zero_watch_time_day_in_active_day_average() -> None:
    episode_repository = Mock(
        spec=EpisodeWatchEventRepository,
    )

    movie_repository = Mock(
        spec=MovieWatchEventRepository,
    )

    episode_repository.get_earliest_watched_at_for_user.return_value = datetime(
        2026,
        8,
        17,
        tzinfo=UTC,
    )

    movie_repository.get_earliest_watched_at_for_user.return_value = None

    episode_repository.get_daily_statistics_for_period.return_value = [
        SimpleNamespace(
            day="2026-08-17",
            watch_count=1,
            watch_time_minutes=0,
        ),
        SimpleNamespace(
            day="2026-08-18",
            watch_count=1,
            watch_time_minutes=120,
        ),
    ]

    movie_repository.get_daily_statistics_for_period.return_value = []

    service = create_statistics_service(
        episode_watch_event_repository=episode_repository,
        movie_watch_event_repository=movie_repository,
    )

    result = service.get_habits(
        user_id=uuid4(),
        reference_date=date(
            2026,
            8,
            18,
        ),
    )

    assert result.average_active_day_watch_time_minutes == 60


def test_get_habits_calculates_most_active_weekday() -> None:
    episode_repository = Mock(
        spec=EpisodeWatchEventRepository,
    )

    movie_repository = Mock(
        spec=MovieWatchEventRepository,
    )

    episode_repository.get_earliest_watched_at_for_user.return_value = datetime(
        2026,
        8,
        10,
        tzinfo=UTC,
    )

    movie_repository.get_earliest_watched_at_for_user.return_value = datetime(
        2026,
        8,
        10,
        tzinfo=UTC,
    )

    episode_repository.get_daily_statistics_for_period.return_value = [
        SimpleNamespace(
            day="2026-08-10",
            watch_count=2,
            watch_time_minutes=100,
        ),
        SimpleNamespace(
            day="2026-08-17",
            watch_count=3,
            watch_time_minutes=150,
        ),
        SimpleNamespace(
            day="2026-08-11",
            watch_count=4,
            watch_time_minutes=200,
        ),
    ]

    movie_repository.get_daily_statistics_for_period.return_value = [
        SimpleNamespace(
            day="2026-08-10",
            watch_count=1,
            watch_time_minutes=120,
        ),
        SimpleNamespace(
            day="2026-08-17",
            watch_count=2,
            watch_time_minutes=240,
        ),
    ]

    service = create_statistics_service(
        episode_watch_event_repository=episode_repository,
        movie_watch_event_repository=movie_repository,
    )

    result = service.get_habits(
        user_id=uuid4(),
        reference_date=date(
            2026,
            8,
            18,
        ),
    )

    assert result.most_active_weekday == "Monday"
    assert result.most_active_weekday_watch_count == 8


def test_get_content_insights_combines_all_rankings() -> None:
    """Combine every Content Insights ranking into one response."""

    user_id = uuid4()

    show_id = uuid4()
    episode_id = uuid4()
    movie_id = uuid4()

    episode_repository = Mock(
        spec=EpisodeWatchEventRepository,
    )

    movie_repository = Mock(
        spec=MovieWatchEventRepository,
    )

    episode_repository.get_most_watched_shows.return_value = [
        ShowViewingInsight(
            show_id=show_id,
            tmdb_id=95396,
            title="Severance",
            poster_url=f"/api/v1/images/shows/{show_id}/poster",
            watch_count=12,
            rewatch_count=0,
        ),
    ]

    episode_repository.get_most_rewatched_shows.return_value = [
        ShowViewingInsight(
            show_id=show_id,
            tmdb_id=95396,
            title="Severance",
            poster_url=f"/api/v1/images/shows/{show_id}/poster",
            watch_count=12,
            rewatch_count=4,
        ),
    ]

    episode_repository.get_most_rewatched_episodes.return_value = [
        EpisodeViewingInsight(
            episode_id=episode_id,
            show_tmdb_id=95396,
            show_title="Severance",
            season_number=1,
            episode_number=1,
            episode_title="Good News About Hell",
            still_url=(f"/api/v1/images/episodes/{episode_id}/still"),
            watch_count=4,
            rewatch_count=3,
        ),
    ]

    movie_repository.get_most_rewatched_movies.return_value = [
        MovieViewingInsight(
            movie_id=movie_id,
            tmdb_id=438631,
            title="Dune",
            poster_url=f"/api/v1/images/movies/{movie_id}/poster",
            watch_count=3,
            rewatch_count=2,
        ),
    ]

    episode_repository.get_top_show_genres.return_value = [
        GenreViewingInsight(
            genre_id=1,
            name="Drama",
            watch_count=12,
        ),
    ]

    movie_repository.get_top_movie_genres.return_value = [
        GenreViewingInsight(
            genre_id=2,
            name="Science Fiction",
            watch_count=8,
        ),
    ]

    service = create_statistics_service(
        episode_watch_event_repository=episode_repository,
        movie_watch_event_repository=movie_repository,
    )

    result = service.get_content_insights(
        user_id=user_id,
    )

    assert len(result.most_watched_shows) == 1
    assert result.most_watched_shows[0].title == "Severance"
    assert result.most_watched_shows[0].watch_count == 12

    assert len(result.most_rewatched_shows) == 1
    assert result.most_rewatched_shows[0].rewatch_count == 4

    assert len(result.most_rewatched_episodes) == 1

    episode = result.most_rewatched_episodes[0]

    assert episode.show_title == "Severance"
    assert episode.season_number == 1
    assert episode.episode_number == 1
    assert episode.episode_title == "Good News About Hell"
    assert episode.watch_count == 4
    assert episode.rewatch_count == 3

    assert len(result.most_rewatched_movies) == 1
    assert result.most_rewatched_movies[0].title == "Dune"
    assert result.most_rewatched_movies[0].rewatch_count == 2

    assert [
        (
            item.name,
            item.watch_count,
        )
        for item in result.top_show_genres
    ] == [
        (
            "Drama",
            12,
        ),
    ]

    assert [
        (
            item.name,
            item.watch_count,
        )
        for item in result.top_movie_genres
    ] == [
        (
            "Science Fiction",
            8,
        ),
    ]

    episode_repository.get_most_watched_shows.assert_called_once_with(
        user_id=user_id,
        limit=5,
    )

    episode_repository.get_most_rewatched_shows.assert_called_once_with(
        user_id=user_id,
        limit=5,
    )

    episode_repository.get_most_rewatched_episodes.assert_called_once_with(
        user_id=user_id,
        limit=5,
    )

    movie_repository.get_most_rewatched_movies.assert_called_once_with(
        user_id=user_id,
        limit=5,
    )

    episode_repository.get_top_show_genres.assert_called_once_with(
        user_id=user_id,
        limit=5,
    )

    movie_repository.get_top_movie_genres.assert_called_once_with(
        user_id=user_id,
        limit=5,
    )


def test_get_content_insights_returns_empty_rankings_without_history() -> None:
    """Return usable empty Content Insights when no rankings exist."""

    user_id = uuid4()

    episode_repository = Mock(
        spec=EpisodeWatchEventRepository,
    )

    movie_repository = Mock(
        spec=MovieWatchEventRepository,
    )

    episode_repository.get_most_watched_shows.return_value = []
    episode_repository.get_most_rewatched_shows.return_value = []
    episode_repository.get_most_rewatched_episodes.return_value = []
    episode_repository.get_top_show_genres.return_value = []

    movie_repository.get_most_rewatched_movies.return_value = []
    movie_repository.get_top_movie_genres.return_value = []

    service = create_statistics_service(
        episode_watch_event_repository=episode_repository,
        movie_watch_event_repository=movie_repository,
    )

    result = service.get_content_insights(
        user_id=user_id,
    )

    assert result.most_watched_shows == []
    assert result.most_rewatched_shows == []
    assert result.most_rewatched_episodes == []
    assert result.most_rewatched_movies == []
    assert result.top_show_genres == []
    assert result.top_movie_genres == []


def test_get_library_statistics_returns_library_counts() -> None:
    """Return Shows, Movies and completed Show Library counts."""

    user_id = uuid4()

    episode_repository = Mock(
        spec=EpisodeWatchEventRepository,
    )

    movie_repository = Mock(
        spec=MovieWatchEventRepository,
    )

    library_repository = Mock(
        spec=LibraryRepository,
    )

    library_repository.count_shows_by_user.return_value = 18
    library_repository.count_movies_by_user.return_value = 42
    library_repository.count_completed_shows_by_user.return_value = 7

    service = create_statistics_service(
        episode_watch_event_repository=episode_repository,
        movie_watch_event_repository=movie_repository,
        library_repository=library_repository,
    )

    result = service.get_library_statistics(
        user_id=user_id,
    )

    assert result.shows_added == 18
    assert result.movies_added == 42
    assert result.shows_completed == 7

    library_repository.count_shows_by_user.assert_called_once_with(
        user_id=user_id,
    )

    library_repository.count_movies_by_user.assert_called_once_with(
        user_id=user_id,
    )

    library_repository.count_completed_shows_by_user.assert_called_once_with(
        user_id=user_id,
    )


def test_get_library_statistics_supports_empty_library() -> None:
    """Return usable zero Library statistics."""

    user_id = uuid4()

    episode_repository = Mock(
        spec=EpisodeWatchEventRepository,
    )

    movie_repository = Mock(
        spec=MovieWatchEventRepository,
    )

    library_repository = Mock(
        spec=LibraryRepository,
    )

    library_repository.count_shows_by_user.return_value = 0
    library_repository.count_movies_by_user.return_value = 0
    library_repository.count_completed_shows_by_user.return_value = 0

    service = create_statistics_service(
        episode_watch_event_repository=episode_repository,
        movie_watch_event_repository=movie_repository,
        library_repository=library_repository,
    )

    result = service.get_library_statistics(
        user_id=user_id,
    )

    assert result.shows_added == 0
    assert result.movies_added == 0
    assert result.shows_completed == 0


def test_get_backlog_statistics_combines_current_backlog_values() -> None:
    """Combine Episode and Movie backlog counts and known watch time."""

    user_id = uuid4()

    episode_watch_event_repository = Mock(
        spec=EpisodeWatchEventRepository,
    )

    movie_watch_event_repository = Mock(
        spec=MovieWatchEventRepository,
    )

    library_repository = Mock(
        spec=LibraryRepository,
    )

    episode_repository = Mock(
        spec=EpisodeRepository,
    )

    episode_progress_repository = Mock(
        spec=EpisodeProgressRepository,
    )

    show_ids = [
        uuid4(),
        uuid4(),
    ]

    library_repository.get_backlog_show_ids_for_user.return_value = show_ids

    episode_progress_repository.get_unwatched_aired_statistics.return_value = (
        12,
        540,
    )

    library_repository.get_planned_movie_statistics.return_value = (
        3,
        360,
    )

    episode_progress_repository.count_first_watched_regular_episodes_between.return_value = 8

    episode_repository.list_regular_for_shows_between.return_value = [
        SimpleNamespace() for _ in range(6)
    ]

    service = create_statistics_service(
        episode_watch_event_repository=episode_watch_event_repository,
        movie_watch_event_repository=movie_watch_event_repository,
        library_repository=library_repository,
        episode_repository=episode_repository,
        episode_progress_repository=episode_progress_repository,
    )

    result = service.get_backlog_statistics(
        user_id=user_id,
        reference_date=date(
            2026,
            8,
            19,
        ),
    )

    assert result.unwatched_aired_episodes == 12
    assert result.planned_movies == 3
    assert result.future_watch_time_minutes == 900

    assert result.catch_up_speed_episodes_per_week == 2.0

    assert result.backlog_trend == "shrinking"
    assert result.backlog_trend_episode_delta == -2


def test_get_backlog_statistics_reports_growing_backlog() -> None:
    """Report a growing backlog when more Episodes aired than were caught up."""

    user_id = uuid4()

    episode_watch_event_repository = Mock(
        spec=EpisodeWatchEventRepository,
    )

    movie_watch_event_repository = Mock(
        spec=MovieWatchEventRepository,
    )

    library_repository = Mock(
        spec=LibraryRepository,
    )

    episode_repository = Mock(
        spec=EpisodeRepository,
    )

    episode_progress_repository = Mock(
        spec=EpisodeProgressRepository,
    )

    show_ids = [
        uuid4(),
    ]

    library_repository.get_backlog_show_ids_for_user.return_value = show_ids

    episode_progress_repository.get_unwatched_aired_statistics.return_value = (
        7,
        315,
    )

    library_repository.get_planned_movie_statistics.return_value = (
        0,
        0,
    )

    episode_progress_repository.count_first_watched_regular_episodes_between.return_value = 3

    episode_repository.list_regular_for_shows_between.return_value = [
        SimpleNamespace() for _ in range(7)
    ]

    service = create_statistics_service(
        episode_watch_event_repository=episode_watch_event_repository,
        movie_watch_event_repository=movie_watch_event_repository,
        library_repository=library_repository,
        episode_repository=episode_repository,
        episode_progress_repository=episode_progress_repository,
    )

    result = service.get_backlog_statistics(
        user_id=user_id,
        reference_date=date(
            2026,
            8,
            19,
        ),
    )

    assert result.catch_up_speed_episodes_per_week == 0.75

    assert result.backlog_trend == "growing"
    assert result.backlog_trend_episode_delta == 4


def test_get_backlog_statistics_reports_stable_backlog() -> None:
    """Report a stable backlog when aired and caught-up counts match."""

    user_id = uuid4()

    episode_watch_event_repository = Mock(
        spec=EpisodeWatchEventRepository,
    )

    movie_watch_event_repository = Mock(
        spec=MovieWatchEventRepository,
    )

    library_repository = Mock(
        spec=LibraryRepository,
    )

    episode_repository = Mock(
        spec=EpisodeRepository,
    )

    episode_progress_repository = Mock(
        spec=EpisodeProgressRepository,
    )

    library_repository.get_backlog_show_ids_for_user.return_value = [
        uuid4(),
    ]

    episode_progress_repository.get_unwatched_aired_statistics.return_value = (
        4,
        180,
    )

    library_repository.get_planned_movie_statistics.return_value = (
        2,
        240,
    )

    episode_progress_repository.count_first_watched_regular_episodes_between.return_value = 4

    episode_repository.list_regular_for_shows_between.return_value = [
        SimpleNamespace() for _ in range(4)
    ]

    service = create_statistics_service(
        episode_watch_event_repository=episode_watch_event_repository,
        movie_watch_event_repository=movie_watch_event_repository,
        library_repository=library_repository,
        episode_repository=episode_repository,
        episode_progress_repository=episode_progress_repository,
    )

    result = service.get_backlog_statistics(
        user_id=user_id,
        reference_date=date(
            2026,
            8,
            19,
        ),
    )

    assert result.future_watch_time_minutes == 420

    assert result.catch_up_speed_episodes_per_week == 1.0

    assert result.backlog_trend == "stable"
    assert result.backlog_trend_episode_delta == 0


def test_get_backlog_statistics_returns_zeroes_without_backlog() -> None:
    """Return usable zero backlog statistics when nothing is pending."""

    user_id = uuid4()

    episode_watch_event_repository = Mock(
        spec=EpisodeWatchEventRepository,
    )

    movie_watch_event_repository = Mock(
        spec=MovieWatchEventRepository,
    )

    library_repository = Mock(
        spec=LibraryRepository,
    )

    episode_repository = Mock(
        spec=EpisodeRepository,
    )

    episode_progress_repository = Mock(
        spec=EpisodeProgressRepository,
    )

    library_repository.get_backlog_show_ids_for_user.return_value = []

    episode_progress_repository.get_unwatched_aired_statistics.return_value = (
        0,
        0,
    )

    library_repository.get_planned_movie_statistics.return_value = (
        0,
        0,
    )

    episode_progress_repository.count_first_watched_regular_episodes_between.return_value = 0

    episode_repository.list_regular_for_shows_between.return_value = []

    service = create_statistics_service(
        episode_watch_event_repository=episode_watch_event_repository,
        movie_watch_event_repository=movie_watch_event_repository,
        library_repository=library_repository,
        episode_repository=episode_repository,
        episode_progress_repository=episode_progress_repository,
    )

    result = service.get_backlog_statistics(
        user_id=user_id,
        reference_date=date(
            2026,
            8,
            19,
        ),
    )

    assert result.unwatched_aired_episodes == 0
    assert result.planned_movies == 0
    assert result.future_watch_time_minutes == 0

    assert result.catch_up_speed_episodes_per_week == 0.0

    assert result.backlog_trend == "stable"
    assert result.backlog_trend_episode_delta == 0


def test_get_backlog_statistics_uses_twenty_eight_day_trend_window() -> None:
    """Use the previous 28 calendar days including the reference date."""

    user_id = uuid4()
    show_id = uuid4()

    episode_watch_event_repository = Mock(
        spec=EpisodeWatchEventRepository,
    )

    movie_watch_event_repository = Mock(
        spec=MovieWatchEventRepository,
    )

    library_repository = Mock(
        spec=LibraryRepository,
    )

    episode_repository = Mock(
        spec=EpisodeRepository,
    )

    episode_progress_repository = Mock(
        spec=EpisodeProgressRepository,
    )

    library_repository.get_backlog_show_ids_for_user.return_value = [
        show_id,
    ]

    episode_progress_repository.get_unwatched_aired_statistics.return_value = (
        0,
        0,
    )

    library_repository.get_planned_movie_statistics.return_value = (
        0,
        0,
    )

    episode_progress_repository.count_first_watched_regular_episodes_between.return_value = 0

    episode_repository.list_regular_for_shows_between.return_value = []

    service = create_statistics_service(
        episode_watch_event_repository=episode_watch_event_repository,
        movie_watch_event_repository=movie_watch_event_repository,
        library_repository=library_repository,
        episode_repository=episode_repository,
        episode_progress_repository=episode_progress_repository,
    )

    service.get_backlog_statistics(
        user_id=user_id,
        reference_date=date(
            2026,
            8,
            19,
        ),
    )

    episode_repository.list_regular_for_shows_between.assert_called_once_with(
        show_ids=[
            show_id,
        ],
        from_date=date(
            2026,
            7,
            23,
        ),
        to_date=date(
            2026,
            8,
            19,
        ),
    )

    episode_progress_repository.count_first_watched_regular_episodes_between.assert_called_once_with(
        user_id=user_id,
        show_ids=[
            show_id,
        ],
        start_at=datetime(
            2026,
            7,
            23,
            tzinfo=UTC,
        ),
        end_at=datetime(
            2026,
            8,
            20,
            tzinfo=UTC,
        ),
    )
