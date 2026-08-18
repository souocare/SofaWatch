from datetime import UTC, date, datetime
from unittest.mock import Mock
from uuid import uuid4

from app.repositories.episode_watch_event import EpisodeWatchEventRepository
from app.repositories.movie_watch_event import MovieWatchEventRepository
from app.services.statistics import StatisticsService
from app.repositories.viewing_statistics import DailyViewingStatistics


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

    service = StatisticsService(
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

    service = StatisticsService(
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

        service = StatisticsService(
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

    service = StatisticsService(
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
        125,   # watch_count
        100,   # unique_count
        25,    # rewatch_count
        6250,  # watch_time_minutes
        1250,  # rewatch_time_minutes
    )

    movie_repository.get_all_time_statistics.return_value = (
        34,    # watch_count
        30,    # unique_count
        4,     # rewatch_count
        4200,  # watch_time_minutes
        500,   # rewatch_time_minutes
    )

    service = StatisticsService(
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

    service = StatisticsService(
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

    service = StatisticsService(
        episode_watch_event_repository=episode_repository,
        movie_watch_event_repository=movie_repository,
    )

    user_id = uuid4()

    result = service.get_activity(
        user_id=user_id,
        days=7,
        reference_date=date(
            2026,
            8,
            18,
        ),
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

    assert [
        item.day
        for item in result.days
    ] == [
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

    service = StatisticsService(
        episode_watch_event_repository=episode_repository,
        movie_watch_event_repository=movie_repository,
    )

    result = service.get_activity(
        user_id=uuid4(),
        days=7,
        reference_date=date(
            2026,
            8,
            18,
        ),
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

    service = StatisticsService(
        episode_watch_event_repository=episode_repository,
        movie_watch_event_repository=movie_repository,
    )

    result = service.get_activity(
        user_id=uuid4(),
        days=14,
        reference_date=date(
            2026,
            8,
            18,
        ),
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


def test_get_activity_rejects_unsupported_day_range() -> None:
    episode_repository = Mock(
        spec=EpisodeWatchEventRepository,
    )

    movie_repository = Mock(
        spec=MovieWatchEventRepository,
    )

    service = StatisticsService(
        episode_watch_event_repository=episode_repository,
        movie_watch_event_repository=movie_repository,
    )

    try:
        service.get_activity(
            user_id=uuid4(),
            days=30,
            reference_date=date(
                2026,
                8,
                18,
            ),
        )
    except ValueError as error:
        assert str(error) == (
            "Statistics activity supports only 7 or 14 days."
        )
    else:
        raise AssertionError(
            "Expected unsupported activity range to raise ValueError."
        )