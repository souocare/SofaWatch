from datetime import date
from types import SimpleNamespace
from unittest.mock import Mock
from uuid import UUID, uuid4

from app.models.enums import LibraryStatus
from app.repositories.episode_progress import (
    EpisodeProgressRepository,
    NextUnwatchedEpisode,
)
from app.repositories.library import LibraryRepository
from app.services.watch_next import WatchNextService


def create_show(
    *,
    show_id: UUID | None = None,
    tmdb_id: int = 95396,
    title: str = "Severance",
) -> SimpleNamespace:
    """Create Show-like data required by WatchNextService."""

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
    status: LibraryStatus = LibraryStatus.WATCHING,
) -> SimpleNamespace:
    """Create LibraryEntry-like data required by WatchNextService."""

    return SimpleNamespace(
        id=uuid4(),
        show_id=show.id,
        show=show,
        status=status,
    )


def create_episode(
    *,
    tmdb_id: int = 1947648,
    episode_number: int = 4,
    title: str = "Woe's Hollow",
    air_date: date | None = date(2026, 8, 10),
) -> SimpleNamespace:
    """Create Episode-like data required by WatchNextService."""

    return SimpleNamespace(
        id=uuid4(),
        tmdb_id=tmdb_id,
        episode_number=episode_number,
        title=title,
        air_date=air_date,
        runtime=52,
        still_url="https://example.com/still.jpg",
    )


def create_service(
    *,
    library_repository: Mock,
    progress_repository: Mock,
) -> WatchNextService:
    return WatchNextService(
        library_repository=library_repository,
        progress_repository=progress_repository,
    )


def test_lists_next_episode_for_watching_shows() -> None:
    """Return the next aired unwatched Episode for each Watching Show."""

    library_repository = Mock(
        spec=LibraryRepository,
    )

    progress_repository = Mock(
        spec=EpisodeProgressRepository,
    )

    show = create_show()

    entry = create_library_entry(
        show=show,
    )

    episode = create_episode()

    candidate = NextUnwatchedEpisode(
        show_id=show.id,
        episode=episode,
        season_number=2,
    )

    library_repository.list_shows_by_user.return_value = [
        entry,
    ]

    progress_repository.list_next_unwatched_for_shows.return_value = {
        show.id: candidate,
    }

    service = create_service(
        library_repository=library_repository,
        progress_repository=progress_repository,
    )

    user_id = uuid4()

    result = service.list_for_user(
        user_id=user_id,
    )

    assert len(result) == 1

    item = result[0]

    assert item.library_entry_id == entry.id
    assert item.library_status == LibraryStatus.WATCHING

    assert item.show.id == show.id
    assert item.show.tmdb_id == 95396
    assert item.show.title == "Severance"

    assert item.next_episode.id == episode.id
    assert item.next_episode.tmdb_id == 1947648
    assert item.next_episode.season_number == 2
    assert item.next_episode.episode_number == 4
    assert item.next_episode.title == "Woe's Hollow"
    assert item.next_episode.air_date == date(2026, 8, 10)
    assert item.next_episode.runtime == 52

    library_repository.list_shows_by_user.assert_called_once_with(
        user_id,
        status=LibraryStatus.WATCHING,
    )

    progress_repository.list_next_unwatched_for_shows.assert_called_once()

    call = (
        progress_repository
        .list_next_unwatched_for_shows
        .call_args
    )

    assert call.kwargs["user_id"] == user_id
    assert call.kwargs["show_ids"] == [
        show.id,
    ]


def test_excludes_show_without_available_next_episode() -> None:
    """Do not return a Show that has no aired unwatched Episode."""

    library_repository = Mock(
        spec=LibraryRepository,
    )

    progress_repository = Mock(
        spec=EpisodeProgressRepository,
    )

    show = create_show()

    entry = create_library_entry(
        show=show,
    )

    library_repository.list_shows_by_user.return_value = [
        entry,
    ]

    progress_repository.list_next_unwatched_for_shows.return_value = {}

    service = create_service(
        library_repository=library_repository,
        progress_repository=progress_repository,
    )

    result = service.list_for_user(
        user_id=uuid4(),
    )

    assert result == []


def test_requests_only_watching_library_entries() -> None:
    """Watch Next must read only Shows currently marked as Watching."""

    library_repository = Mock(
        spec=LibraryRepository,
    )

    progress_repository = Mock(
        spec=EpisodeProgressRepository,
    )

    library_repository.list_shows_by_user.return_value = []

    service = create_service(
        library_repository=library_repository,
        progress_repository=progress_repository,
    )

    user_id = uuid4()

    result = service.list_for_user(
        user_id=user_id,
    )

    assert result == []

    library_repository.list_shows_by_user.assert_called_once_with(
        user_id,
        status=LibraryStatus.WATCHING,
    )


def test_empty_watch_list_does_not_query_episode_progress() -> None:
    """Avoid the Episode query when there are no Watching Shows."""

    library_repository = Mock(
        spec=LibraryRepository,
    )

    progress_repository = Mock(
        spec=EpisodeProgressRepository,
    )

    library_repository.list_shows_by_user.return_value = []

    service = create_service(
        library_repository=library_repository,
        progress_repository=progress_repository,
    )

    result = service.list_for_user(
        user_id=uuid4(),
    )

    assert result == []

    progress_repository.list_next_unwatched_for_shows.assert_not_called()


def test_returns_multiple_watch_next_items() -> None:
    """Build Watch Next for multiple Watching Shows in one batch."""

    library_repository = Mock(
        spec=LibraryRepository,
    )

    progress_repository = Mock(
        spec=EpisodeProgressRepository,
    )

    first_show = create_show(
        tmdb_id=95396,
        title="Severance",
    )

    second_show = create_show(
        tmdb_id=100088,
        title="The Last of Us",
    )

    first_entry = create_library_entry(
        show=first_show,
    )

    second_entry = create_library_entry(
        show=second_show,
    )

    first_episode = create_episode(
        tmdb_id=1947648,
        episode_number=4,
        title="Woe's Hollow",
    )

    second_episode = create_episode(
        tmdb_id=3000001,
        episode_number=3,
        title="Long, Long Time",
    )

    library_repository.list_shows_by_user.return_value = [
        first_entry,
        second_entry,
    ]

    progress_repository.list_next_unwatched_for_shows.return_value = {
        first_show.id: NextUnwatchedEpisode(
            show_id=first_show.id,
            episode=first_episode,
            season_number=2,
        ),
        second_show.id: NextUnwatchedEpisode(
            show_id=second_show.id,
            episode=second_episode,
            season_number=1,
        ),
    }

    service = create_service(
        library_repository=library_repository,
        progress_repository=progress_repository,
    )

    result = service.list_for_user(
        user_id=uuid4(),
    )

    assert len(result) == 2

    assert result[0].show.title == "Severance"
    assert result[0].next_episode.season_number == 2
    assert result[0].next_episode.episode_number == 4

    assert result[1].show.title == "The Last of Us"
    assert result[1].next_episode.season_number == 1
    assert result[1].next_episode.episode_number == 3

    progress_repository.list_next_unwatched_for_shows.assert_called_once()