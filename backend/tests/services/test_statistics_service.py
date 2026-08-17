from datetime import UTC, date, datetime
from unittest.mock import Mock
from uuid import uuid4

from app.repositories.episode_watch_event import EpisodeWatchEventRepository
from app.repositories.movie_watch_event import MovieWatchEventRepository
from app.services.statistics import StatisticsService


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