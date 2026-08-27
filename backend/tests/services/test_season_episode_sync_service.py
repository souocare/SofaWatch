from datetime import date
from types import SimpleNamespace
from unittest.mock import Mock
from uuid import uuid4

import pytest
from sqlalchemy.orm import Session

from app.models.episode import Episode
from app.models.season import Season
from app.models.show import Show
from app.repositories.episode import EpisodeRepository
from app.repositories.season import SeasonRepository
from app.repositories.show import ShowRepository
from app.services.season_episode_sync import SeasonEpisodeSyncService
from app.services.tmdb_season_details import TMDBSeasonDetailsService


@pytest.fixture
def show() -> Show:
    item = Show()

    item.id = uuid4()
    item.tmdb_id = 1620

    return item


@pytest.fixture
def season(show: Show) -> Season:
    item = Season()

    item.id = uuid4()
    item.show_id = show.id
    item.season_number = 2
    item.tmdb_id = 12345

    return item


@pytest.fixture
def show_repository(show: Show) -> Mock:
    repository = Mock(spec=ShowRepository)

    repository.get_by_id.return_value = show

    return repository


@pytest.fixture
def season_repository(season: Season) -> Mock:
    repository = Mock(spec=SeasonRepository)

    repository.get_by_id.return_value = season

    return repository


@pytest.fixture
def episode_repository() -> Mock:
    repository = Mock(spec=EpisodeRepository)

    repository.get_by_tmdb_id.return_value = None
    repository.get_by_number.return_value = None
    repository.list_by_season_id.return_value = []

    return repository


@pytest.fixture
def tmdb_season_details_service() -> Mock:
    service = Mock(spec=TMDBSeasonDetailsService)

    service.get_episodes.return_value = []

    return service


@pytest.fixture
def session() -> Mock:
    return Mock(spec=Session)


@pytest.fixture
def service(
    session: Mock,
    show_repository: Mock,
    season_repository: Mock,
    episode_repository: Mock,
    tmdb_season_details_service: Mock,
) -> SeasonEpisodeSyncService:
    return SeasonEpisodeSyncService(
        session=session,
        show_repository=show_repository,
        season_repository=season_repository,
        episode_repository=episode_repository,
        tmdb_season_details_service=tmdb_season_details_service,
    )


def make_episode_summary(
    *,
    tmdb_id: int = 2001,
    episode_number: int = 1,
    title: str = "Episode One",
):
    return SimpleNamespace(
        tmdb_id=tmdb_id,
        episode_number=episode_number,
        title=title,
        overview="Episode overview.",
        air_date=date(2026, 8, 1),
        runtime=52,
        vote_average=8.4,
        vote_count=120,
        still_path="/episode.jpg",
    )


def test_sync_requests_only_selected_season(
    service: SeasonEpisodeSyncService,
    season: Season,
    show: Show,
    tmdb_season_details_service: Mock,
) -> None:
    service.sync(
        season_id=season.id,
        language="en",
    )

    tmdb_season_details_service.get_episodes.assert_called_once_with(
        tmdb_id=show.tmdb_id,
        season_number=2,
        language="en",
    )


def test_sync_creates_new_episode(
    service: SeasonEpisodeSyncService,
    season: Season,
    episode_repository: Mock,
    tmdb_season_details_service: Mock,
) -> None:
    episode_details = make_episode_summary()

    tmdb_season_details_service.get_episodes.return_value = [
        episode_details,
    ]

    service.sync(
        season_id=season.id,
    )

    episode_repository.add.assert_called_once()

    episode = episode_repository.add.call_args.args[0]

    assert isinstance(episode, Episode)
    assert episode.season_id == season.id
    assert episode.tmdb_id == 2001
    assert episode.episode_number == 1
    assert episode.title == "Episode One"
    assert episode.overview == "Episode overview."
    assert episode.air_date == date(2026, 8, 1)
    assert episode.runtime == 52
    assert episode.vote_average == 8.4
    assert episode.vote_count == 120
    assert episode.tmdb_still_path == "/episode.jpg"


def test_sync_updates_existing_episode_by_tmdb_id(
    service: SeasonEpisodeSyncService,
    season: Season,
    episode_repository: Mock,
    tmdb_season_details_service: Mock,
) -> None:
    episode = Episode(
        season_id=season.id,
    )

    episode.tmdb_id = 2001
    episode.episode_number = 1
    episode.title = "Old title"

    episode_repository.get_by_tmdb_id.return_value = episode

    tmdb_season_details_service.get_episodes.return_value = [
        make_episode_summary(
            tmdb_id=2001,
            episode_number=1,
            title="Updated title",
        ),
    ]

    service.sync(
        season_id=season.id,
    )

    assert episode.title == "Updated title"

    episode_repository.get_by_number.assert_not_called()
    episode_repository.add.assert_not_called()


def test_sync_matches_existing_episode_by_number_when_tmdb_id_changes(
    service: SeasonEpisodeSyncService,
    season: Season,
    episode_repository: Mock,
    tmdb_season_details_service: Mock,
) -> None:
    episode = Episode(
        season_id=season.id,
    )

    episode.tmdb_id = 999
    episode.episode_number = 1
    episode.title = "Existing episode"

    episode_repository.get_by_tmdb_id.return_value = None
    episode_repository.get_by_number.return_value = episode

    tmdb_season_details_service.get_episodes.return_value = [
        make_episode_summary(
            tmdb_id=2001,
            episode_number=1,
            title="Updated episode",
        ),
    ]

    service.sync(
        season_id=season.id,
    )

    assert episode.tmdb_id == 2001
    assert episode.title == "Updated episode"

    episode_repository.add.assert_not_called()


def test_sync_returns_existing_local_episodes_without_provider_request(
    service: SeasonEpisodeSyncService,
    session: Mock,
    season: Season,
    episode_repository: Mock,
    show_repository: Mock,
    tmdb_season_details_service: Mock,
) -> None:
    """Return cached local Episodes without contacting the provider."""

    stored_episode = Episode(
        season_id=season.id,
    )

    episode_repository.list_by_season_id.return_value = [
        stored_episode,
    ]

    result = service.sync(
        season_id=season.id,
    )

    assert result == [stored_episode]

    episode_repository.list_by_season_id.assert_called_once_with(
        season.id,
    )

    show_repository.get_by_id.assert_not_called()
    tmdb_season_details_service.get_episodes.assert_not_called()

    session.commit.assert_not_called()
    session.rollback.assert_not_called()


def test_sync_force_refreshes_existing_local_episodes(
    service: SeasonEpisodeSyncService,
    session: Mock,
    season: Season,
    show: Show,
    episode_repository: Mock,
    tmdb_season_details_service: Mock,
) -> None:
    """Refresh local Episodes when explicitly requested."""

    stored_episode = Episode(
        season_id=season.id,
    )

    stored_episode.tmdb_id = 2001
    stored_episode.episode_number = 1
    stored_episode.title = "Old title"

    episode_repository.list_by_season_id.return_value = [
        stored_episode,
    ]

    episode_repository.get_by_tmdb_id.return_value = stored_episode

    tmdb_season_details_service.get_episodes.return_value = [
        make_episode_summary(
            tmdb_id=2001,
            episode_number=1,
            title="Updated title",
        ),
    ]

    result = service.sync(
        season_id=season.id,
        force_refresh=True,
    )

    tmdb_season_details_service.get_episodes.assert_called_once_with(
        tmdb_id=show.tmdb_id,
        season_number=season.season_number,
        language=None,
    )

    assert stored_episode.title == "Updated title"

    session.commit.assert_called_once_with()

    assert result == [stored_episode]


def test_sync_returns_none_when_season_does_not_exist(
    service: SeasonEpisodeSyncService,
    season_repository: Mock,
    show_repository: Mock,
    tmdb_season_details_service: Mock,
) -> None:
    season_repository.get_by_id.return_value = None

    result = service.sync(
        season_id=uuid4(),
    )

    assert result is None

    show_repository.get_by_id.assert_not_called()
    tmdb_season_details_service.get_episodes.assert_not_called()


def test_sync_returns_none_when_parent_show_does_not_exist(
    service: SeasonEpisodeSyncService,
    season: Season,
    show_repository: Mock,
    tmdb_season_details_service: Mock,
) -> None:
    show_repository.get_by_id.return_value = None

    result = service.sync(
        season_id=season.id,
    )

    assert result is None

    tmdb_season_details_service.get_episodes.assert_not_called()


def test_sync_rolls_back_when_persistence_fails(
    service: SeasonEpisodeSyncService,
    session: Mock,
    season: Season,
    episode_repository: Mock,
    tmdb_season_details_service: Mock,
) -> None:
    tmdb_season_details_service.get_episodes.return_value = [
        make_episode_summary(),
    ]

    episode_repository.add.side_effect = RuntimeError(
        "database failure",
    )

    with pytest.raises(
        RuntimeError,
        match="database failure",
    ):
        service.sync(
            season_id=season.id,
        )

    session.rollback.assert_called_once_with()
    session.commit.assert_not_called()
