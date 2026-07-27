from types import SimpleNamespace
from unittest.mock import Mock
from uuid import UUID, uuid4

import pytest

from app.repositories.episode import EpisodeRepository
from app.repositories.season import SeasonRepository
from app.services.episode import EpisodeService


@pytest.fixture
def season_id() -> UUID:
    """Provide a local TV season identifier."""

    return uuid4()


@pytest.fixture
def season_repository() -> Mock:
    """Provide a mocked season repository."""

    return Mock(spec=SeasonRepository)


@pytest.fixture
def episode_repository() -> Mock:
    """Provide a mocked episode repository."""

    return Mock(spec=EpisodeRepository)


@pytest.fixture
def episode_service(
    season_repository: Mock,
    episode_repository: Mock,
) -> EpisodeService:
    """Provide an episode service using mocked repositories."""

    return EpisodeService(
        episode_repository=episode_repository,
        season_repository=season_repository,
    )


def make_season(
    *,
    season_id: UUID,
    tmdb_id: int = 134792,
    season_number: int = 1,
    title: str = "Season 1",
) -> SimpleNamespace:
    """Create a lightweight TV season object for service tests."""

    return SimpleNamespace(
        id=season_id,
        tmdb_id=tmdb_id,
        season_number=season_number,
        title=title,
    )


def make_episode(
    *,
    season_id: UUID,
    tmdb_id: int,
    episode_number: int,
    title: str,
) -> SimpleNamespace:
    """Create a lightweight TV episode object for service tests."""

    return SimpleNamespace(
        id=uuid4(),
        season_id=season_id,
        tmdb_id=tmdb_id,
        episode_number=episode_number,
        title=title,
    )


def test_list_for_season_returns_none_when_season_does_not_exist(
    season_id: UUID,
    episode_service: EpisodeService,
    season_repository: Mock,
    episode_repository: Mock,
) -> None:
    """Return None when the requested TV season does not exist."""

    season_repository.get_by_id.return_value = None

    result = episode_service.list_for_season(
        season_id,
    )

    assert result is None

    season_repository.get_by_id.assert_called_once_with(
        season_id,
    )
    episode_repository.list_by_season_id.assert_not_called()


def test_list_for_season_returns_empty_list_when_season_has_no_episodes(
    season_id: UUID,
    episode_service: EpisodeService,
    season_repository: Mock,
    episode_repository: Mock,
) -> None:
    """Return an empty list when the TV season has no episodes."""

    season = make_season(
        season_id=season_id,
    )

    season_repository.get_by_id.return_value = season
    episode_repository.list_by_season_id.return_value = []

    result = episode_service.list_for_season(
        season_id,
    )

    assert result == []

    season_repository.get_by_id.assert_called_once_with(
        season_id,
    )
    episode_repository.list_by_season_id.assert_called_once_with(
        season_id,
    )


def test_list_for_season_returns_stored_episodes(
    season_id: UUID,
    episode_service: EpisodeService,
    season_repository: Mock,
    episode_repository: Mock,
) -> None:
    """Return the locally stored episodes belonging to a TV season."""

    season = make_season(
        season_id=season_id,
    )

    episodes = [
        make_episode(
            season_id=season_id,
            tmdb_id=2001,
            episode_number=1,
            title="Episode 1",
        ),
        make_episode(
            season_id=season_id,
            tmdb_id=2002,
            episode_number=2,
            title="Episode 2",
        ),
        make_episode(
            season_id=season_id,
            tmdb_id=2003,
            episode_number=3,
            title="Episode 3",
        ),
    ]

    season_repository.get_by_id.return_value = season
    episode_repository.list_by_season_id.return_value = episodes

    result = episode_service.list_for_season(
        season_id,
    )

    assert result == episodes
    assert len(result) == 3
    assert [
        episode.episode_number
        for episode in result
    ] == [
        1,
        2,
        3,
    ]

    season_repository.get_by_id.assert_called_once_with(
        season_id,
    )
    episode_repository.list_by_season_id.assert_called_once_with(
        season_id,
    )


def test_list_for_season_returns_repository_result_without_modifying_it(
    season_id: UUID,
    episode_service: EpisodeService,
    season_repository: Mock,
    episode_repository: Mock,
) -> None:
    """Return the exact collection provided by the repository."""

    season = make_season(
        season_id=season_id,
    )

    episodes = [
        make_episode(
            season_id=season_id,
            tmdb_id=2002,
            episode_number=2,
            title="Episode 2",
        ),
        make_episode(
            season_id=season_id,
            tmdb_id=2001,
            episode_number=1,
            title="Episode 1",
        ),
    ]

    season_repository.get_by_id.return_value = season
    episode_repository.list_by_season_id.return_value = episodes

    result = episode_service.list_for_season(
        season_id,
    )

    assert result is episodes
    assert result[0].episode_number == 2
    assert result[1].episode_number == 1

def test_get_by_id_returns_episode(
    episode_service: EpisodeService,
    episode_repository: Mock,
) -> None:
    """Return an episode identified by its internal identifier."""

    episode_id = uuid4()
    season_id = uuid4()

    episode = SimpleNamespace(
        id=episode_id,
        season_id=season_id,
        tmdb_id=2001,
        episode_number=1,
        title="Episode 1",
    )

    episode_repository.get_by_id.return_value = episode

    result = episode_service.get_by_id(
        episode_id,
    )

    assert result is episode
    assert result.id == episode_id

    episode_repository.get_by_id.assert_called_once_with(
        episode_id,
    )


def test_get_by_id_returns_none_when_episode_does_not_exist(
    episode_service: EpisodeService,
    episode_repository: Mock,
) -> None:
    """Return None when the requested episode does not exist."""

    episode_id = uuid4()

    episode_repository.get_by_id.return_value = None

    result = episode_service.get_by_id(
        episode_id,
    )

    assert result is None

    episode_repository.get_by_id.assert_called_once_with(
        episode_id,
    )


def test_get_by_number_returns_episode(
    season_id: UUID,
    episode_service: EpisodeService,
    episode_repository: Mock,
) -> None:
    """Return an episode identified by its season and episode number."""

    episode = make_episode(
        season_id=season_id,
        tmdb_id=2003,
        episode_number=3,
        title="Episode 3",
    )

    episode_repository.get_by_number.return_value = episode

    result = episode_service.get_by_number(
        season_id=season_id,
        episode_number=3,
    )

    assert result is episode
    assert result.season_id == season_id
    assert result.episode_number == 3

    episode_repository.get_by_number.assert_called_once_with(
        season_id=season_id,
        episode_number=3,
    )


def test_get_by_number_returns_none_when_episode_does_not_exist(
    season_id: UUID,
    episode_service: EpisodeService,
    episode_repository: Mock,
) -> None:
    """Return None when the requested episode number does not exist."""

    episode_repository.get_by_number.return_value = None

    result = episode_service.get_by_number(
        season_id=season_id,
        episode_number=10,
    )

    assert result is None

    episode_repository.get_by_number.assert_called_once_with(
        season_id=season_id,
        episode_number=10,
    )