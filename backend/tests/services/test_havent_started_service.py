from datetime import date
from types import SimpleNamespace
from unittest.mock import Mock
from uuid import UUID, uuid4

from app.models.enums import LibraryStatus
from app.repositories.episode import EpisodeRepository
from app.repositories.library import LibraryRepository
from app.services.havent_started import HaventStartedService


def create_show(
    *,
    show_id: UUID | None = None,
    tmdb_id: int = 95396,
    title: str = "Severance",
) -> SimpleNamespace:
    """Create Show-like data required by HaventStartedService."""

    return SimpleNamespace(
        id=show_id or uuid4(),
        tmdb_id=tmdb_id,
        title=title,
        original_title=title,
        first_air_date=date(2022, 2, 18),
        tmdb_poster_path=None,
        local_poster_path=None,
        poster_url="https://example.com/poster.jpg",
        backdrop_url="https://example.com/backdrop.jpg",
        status="Returning Series",
        vote_average=8.4,
    )


def create_library_entry(
    *,
    show: SimpleNamespace,
    status: LibraryStatus = LibraryStatus.PLANNING,
) -> SimpleNamespace:
    """Create LibraryEntry-like data required by HaventStartedService."""

    return SimpleNamespace(
        id=uuid4(),
        show_id=show.id,
        show=show,
        status=status,
    )


def create_episode(
    *,
    tmdb_id: int = 1947648,
    episode_number: int = 1,
    title: str = "Good News About Hell",
    air_date: date | None = date(2022, 2, 18),
) -> SimpleNamespace:
    """Create Episode-like data required by HaventStartedService."""

    return SimpleNamespace(
        id=uuid4(),
        tmdb_id=tmdb_id,
        episode_number=episode_number,
        title=title,
        air_date=air_date,
        runtime=57,
        still_url="https://example.com/still.jpg",
    )


def create_service(
    *,
    library_repository: Mock,
    episode_repository: Mock,
) -> HaventStartedService:
    return HaventStartedService(
        library_repository=library_repository,
        episode_repository=episode_repository,
    )


def test_lists_first_available_episode_for_planning_show() -> None:
    """Return Planning Shows with their first aired regular Episode."""

    library_repository = Mock(spec=LibraryRepository)
    episode_repository = Mock(spec=EpisodeRepository)

    show = create_show()
    entry = create_library_entry(show=show)
    episode = create_episode()

    library_repository.list_shows_by_user.return_value = [entry]

    episode_repository.get_first_aired_regular_for_show.return_value = (
        episode,
        1,
    )

    service = create_service(
        library_repository=library_repository,
        episode_repository=episode_repository,
    )

    result = service.list_for_user(
        user_id=uuid4(),
    )

    assert len(result) == 1

    item = result[0]

    assert item.library_entry_id == entry.id
    assert item.library_status == LibraryStatus.PLANNING

    assert item.show.id == show.id
    assert item.show.tmdb_id == 95396
    assert item.show.title == "Severance"

    assert item.first_episode.id == episode.id
    assert item.first_episode.tmdb_id == 1947648
    assert item.first_episode.season_number == 1
    assert item.first_episode.episode_number == 1
    assert item.first_episode.title == "Good News About Hell"
    assert item.first_episode.air_date == date(2022, 2, 18)


def test_requests_only_planning_library_entries() -> None:
    """Haven't Started must read only Shows currently marked as Planning."""

    library_repository = Mock(spec=LibraryRepository)
    episode_repository = Mock(spec=EpisodeRepository)

    library_repository.list_shows_by_user.return_value = []

    service = create_service(
        library_repository=library_repository,
        episode_repository=episode_repository,
    )

    user_id = uuid4()

    result = service.list_for_user(
        user_id=user_id,
    )

    assert result == []

    library_repository.list_shows_by_user.assert_called_once_with(
        user_id,
        status=LibraryStatus.PLANNING,
    )

    episode_repository.get_first_aired_regular_for_show.assert_not_called()


def test_excludes_show_without_available_first_episode() -> None:
    """Do not return a Planning Show without an aired regular Episode."""

    library_repository = Mock(spec=LibraryRepository)
    episode_repository = Mock(spec=EpisodeRepository)

    show = create_show()
    entry = create_library_entry(show=show)

    library_repository.list_shows_by_user.return_value = [entry]

    episode_repository.get_first_aired_regular_for_show.return_value = None

    service = create_service(
        library_repository=library_repository,
        episode_repository=episode_repository,
    )

    result = service.list_for_user(
        user_id=uuid4(),
    )

    assert result == []