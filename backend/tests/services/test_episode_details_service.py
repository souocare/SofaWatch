from datetime import UTC, date, datetime
from types import SimpleNamespace
from unittest.mock import Mock
from uuid import UUID, uuid4

import pytest

from app.repositories.episode import EpisodeRepository
from app.repositories.episode_progress import EpisodeProgressRepository
from app.repositories.episode_watch_event import EpisodeWatchEventRepository
from app.repositories.season import SeasonRepository
from app.repositories.show import ShowRepository
from app.services.episode_details import EpisodeDetailsService


@pytest.fixture
def episode_repository() -> Mock:
    return Mock(spec=EpisodeRepository)


@pytest.fixture
def season_repository() -> Mock:
    return Mock(spec=SeasonRepository)


@pytest.fixture
def show_repository() -> Mock:
    return Mock(spec=ShowRepository)


@pytest.fixture
def progress_repository() -> Mock:
    return Mock(spec=EpisodeProgressRepository)


@pytest.fixture
def watch_event_repository() -> Mock:
    return Mock(spec=EpisodeWatchEventRepository)


@pytest.fixture
def service(
    episode_repository: Mock,
    season_repository: Mock,
    show_repository: Mock,
    progress_repository: Mock,
    watch_event_repository: Mock,
) -> EpisodeDetailsService:
    return EpisodeDetailsService(
        episode_repository=episode_repository,
        season_repository=season_repository,
        show_repository=show_repository,
        progress_repository=progress_repository,
        watch_event_repository=watch_event_repository,
    )


@pytest.fixture
def user_id() -> UUID:
    return uuid4()


def _make_episode() -> SimpleNamespace:
    return SimpleNamespace(
        id=uuid4(),
        season_id=uuid4(),
        tmdb_id=1947648,
        episode_number=4,
        title="Woe's Hollow",
        overview="Episode overview.",
        air_date=date(2025, 2, 7),
        runtime=52,
        vote_average=8.5,
        vote_count=100,
        tmdb_still_path="/still.jpg",
        local_still_path=None,
        still_url="/api/v1/images/episodes/episode/still",
    )


def _make_season(
    *,
    season_id: UUID,
) -> SimpleNamespace:
    return SimpleNamespace(
        id=season_id,
        show_id=uuid4(),
        tmdb_id=4001,
        season_number=2,
        title="Season 2",
        overview="Season overview.",
        air_date=date(2025, 1, 17),
        episode_count=10,
        vote_average=8.4,
        tmdb_poster_path="/season.jpg",
        local_poster_path=None,
        poster_url="/api/v1/images/seasons/season/poster",
    )


def _make_show(
    *,
    show_id: UUID,
) -> SimpleNamespace:
    return SimpleNamespace(
        id=show_id,
        tmdb_id=95396,
        title="Severance",
        original_title="Severance",
        poster_url="/api/v1/images/shows/show/poster",
        backdrop_url="/api/v1/images/shows/show/backdrop",
        first_air_date=date(2022, 2, 18),
        status="Returning Series",
        vote_average=8.7,
    )


def test_get_details_returns_none_when_episode_does_not_exist(
    service: EpisodeDetailsService,
    episode_repository: Mock,
    season_repository: Mock,
    show_repository: Mock,
    progress_repository: Mock,
    watch_event_repository: Mock,
    user_id: UUID,
) -> None:
    episode_id = uuid4()

    episode_repository.get_by_id.return_value = None

    result = service.get_details(
        user_id=user_id,
        episode_id=episode_id,
    )

    assert result is None

    episode_repository.get_by_id.assert_called_once_with(
        episode_id,
    )

    season_repository.get_by_id.assert_not_called()
    show_repository.get_by_id.assert_not_called()
    progress_repository.get_by_user_and_episode.assert_not_called()
    watch_event_repository.count_by_user_and_episode.assert_not_called()
    watch_event_repository.get_latest_for_user_and_episode.assert_not_called()


def test_get_details_returns_unwatched_episode_without_history(
    service: EpisodeDetailsService,
    episode_repository: Mock,
    season_repository: Mock,
    show_repository: Mock,
    progress_repository: Mock,
    watch_event_repository: Mock,
    user_id: UUID,
) -> None:
    episode = _make_episode()
    season = _make_season(
        season_id=episode.season_id,
    )
    show = _make_show(
        show_id=season.show_id,
    )

    episode_repository.get_by_id.return_value = episode
    season_repository.get_by_id.return_value = season
    show_repository.get_by_id.return_value = show

    progress_repository.get_by_user_and_episode.return_value = None
    watch_event_repository.count_by_user_and_episode.return_value = 0
    watch_event_repository.get_latest_for_user_and_episode.return_value = None

    result = service.get_details(
        user_id=user_id,
        episode_id=episode.id,
    )

    assert result is not None

    assert result.episode.id == episode.id
    assert result.season.id == season.id
    assert result.show.id == show.id

    assert result.progress.is_watched is False
    assert result.progress.watched_at is None
    assert result.progress.watch_count == 0
    assert result.progress.last_watched_at is None


def test_get_details_returns_current_progress_and_watch_history(
    service: EpisodeDetailsService,
    episode_repository: Mock,
    season_repository: Mock,
    show_repository: Mock,
    progress_repository: Mock,
    watch_event_repository: Mock,
    user_id: UUID,
) -> None:
    episode = _make_episode()
    season = _make_season(
        season_id=episode.season_id,
    )
    show = _make_show(
        show_id=season.show_id,
    )

    watched_at = datetime(
        2026,
        8,
        14,
        20,
        30,
        tzinfo=UTC,
    )

    progress = SimpleNamespace(
        is_watched=True,
        watched_at=watched_at,
    )

    latest_event = SimpleNamespace(
        watched_at=watched_at,
    )

    episode_repository.get_by_id.return_value = episode
    season_repository.get_by_id.return_value = season
    show_repository.get_by_id.return_value = show

    progress_repository.get_by_user_and_episode.return_value = progress
    watch_event_repository.count_by_user_and_episode.return_value = 2
    watch_event_repository.get_latest_for_user_and_episode.return_value = (
        latest_event
    )

    result = service.get_details(
        user_id=user_id,
        episode_id=episode.id,
    )

    assert result is not None

    assert result.progress.is_watched is True
    assert result.progress.watched_at == watched_at
    assert result.progress.watch_count == 2
    assert result.progress.last_watched_at == watched_at


def test_get_details_preserves_history_when_episode_is_currently_unwatched(
    service: EpisodeDetailsService,
    episode_repository: Mock,
    season_repository: Mock,
    show_repository: Mock,
    progress_repository: Mock,
    watch_event_repository: Mock,
    user_id: UUID,
) -> None:
    episode = _make_episode()
    season = _make_season(
        season_id=episode.season_id,
    )
    show = _make_show(
        show_id=season.show_id,
    )

    previous_watch = datetime(
        2026,
        8,
        10,
        21,
        tzinfo=UTC,
    )

    progress = SimpleNamespace(
        is_watched=False,
        watched_at=None,
    )

    latest_event = SimpleNamespace(
        watched_at=previous_watch,
    )

    episode_repository.get_by_id.return_value = episode
    season_repository.get_by_id.return_value = season
    show_repository.get_by_id.return_value = show

    progress_repository.get_by_user_and_episode.return_value = progress
    watch_event_repository.count_by_user_and_episode.return_value = 3
    watch_event_repository.get_latest_for_user_and_episode.return_value = (
        latest_event
    )

    result = service.get_details(
        user_id=user_id,
        episode_id=episode.id,
    )

    assert result is not None

    assert result.progress.is_watched is False
    assert result.progress.watched_at is None

    assert result.progress.watch_count == 3
    assert result.progress.last_watched_at == previous_watch