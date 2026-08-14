from datetime import UTC, date, datetime, timedelta
from types import SimpleNamespace
from unittest.mock import Mock
from uuid import UUID, uuid4

from app.models.enums import LibraryStatus
from app.repositories.episode_progress import (
    EpisodeProgressRepository,
    LastWatchedEpisode,
    NextUnwatchedEpisode,
)
from app.repositories.library import LibraryRepository
from app.services.watch_next import WatchNextService
from app.repositories.episode import EpisodeRepository


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
    episode_repository: Mock,
    progress_repository: Mock,
    last_watched_by_show: dict[UUID, LastWatchedEpisode] | None = None,
) -> WatchNextService:
    progress_repository.list_last_watched_for_shows.return_value = (
        last_watched_by_show or {}
    )

    return WatchNextService(
        library_repository=library_repository,
        episode_repository=episode_repository,
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
    episode_repository = Mock(
        spec=EpisodeRepository,
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
    episode_repository.get_aired_counts_by_show_ids.return_value = {
        show.id: 10,
    }

    progress_repository.get_watched_aired_counts_by_show_ids.return_value = {
        show.id: 7,
    }

    service = create_service(
        library_repository=library_repository,
        progress_repository=progress_repository,
        episode_repository=episode_repository,
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

    assert item.progress.watched_episodes == 7
    assert item.progress.aired_episodes == 10
    assert item.progress.percentage == 70.0

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
    episode_repository.get_aired_counts_by_show_ids.assert_called_once()

    aired_call = episode_repository.get_aired_counts_by_show_ids.call_args

    assert aired_call.kwargs["show_ids"] == [
        show.id,
    ]
    assert aired_call.kwargs["as_of"] == date.today()

    progress_repository.get_watched_aired_counts_by_show_ids.assert_called_once()

    watched_call = (
        progress_repository
        .get_watched_aired_counts_by_show_ids
        .call_args
    )

    assert watched_call.kwargs["user_id"] == user_id
    assert watched_call.kwargs["show_ids"] == [
        show.id,
    ]
    assert watched_call.kwargs["as_of"] == date.today()


def test_excludes_show_without_available_next_episode() -> None:
    """Do not return a Show that has no aired unwatched Episode."""

    library_repository = Mock(
        spec=LibraryRepository,
    )

    progress_repository = Mock(
        spec=EpisodeProgressRepository,
    )
    episode_repository = Mock(
        spec=EpisodeRepository,
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
        episode_repository=episode_repository,
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
    episode_repository = Mock(
        spec=EpisodeRepository,
    )

    library_repository.list_shows_by_user.return_value = []

    service = create_service(
        library_repository=library_repository,
        progress_repository=progress_repository,
        episode_repository=episode_repository,
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
    episode_repository = Mock(
        spec=EpisodeRepository,
    )

    library_repository.list_shows_by_user.return_value = []

    service = create_service(
        library_repository=library_repository,
        progress_repository=progress_repository,
        episode_repository=episode_repository,
    )

    result = service.list_for_user(
        user_id=uuid4(),
    )

    assert result == []

    progress_repository.list_next_unwatched_for_shows.assert_not_called()
    episode_repository.get_aired_counts_by_show_ids.assert_not_called()

    progress_repository.get_watched_aired_counts_by_show_ids.assert_not_called()


def test_returns_multiple_watch_next_items() -> None:
    """Build Watch Next for multiple Watching Shows in one batch."""

    library_repository = Mock(
        spec=LibraryRepository,
    )

    progress_repository = Mock(
        spec=EpisodeProgressRepository,
    )
    episode_repository = Mock(
        spec=EpisodeRepository,
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
    episode_repository.get_aired_counts_by_show_ids.return_value = {
        first_show.id: 10,
        second_show.id: 8,
    }

    progress_repository.get_watched_aired_counts_by_show_ids.return_value = {
        first_show.id: 7,
        second_show.id: 3,
    }

    service = create_service(
        library_repository=library_repository,
        progress_repository=progress_repository,
        episode_repository=episode_repository,
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

    assert result[0].progress.watched_episodes == 7
    assert result[0].progress.aired_episodes == 10
    assert result[0].progress.percentage == 70.0

    assert result[1].progress.watched_episodes == 3
    assert result[1].progress.aired_episodes == 8
    assert result[1].progress.percentage == 37.5

    progress_repository.list_next_unwatched_for_shows.assert_called_once()
    episode_repository.get_aired_counts_by_show_ids.assert_called_once()

    progress_repository.get_watched_aired_counts_by_show_ids.assert_called_once()
    aired_call = episode_repository.get_aired_counts_by_show_ids.call_args

    assert aired_call.kwargs["show_ids"] == [
        first_show.id,
        second_show.id,
    ]

    watched_call = (
        progress_repository
        .get_watched_aired_counts_by_show_ids
        .call_args
    )

    assert watched_call.kwargs["show_ids"] == [
        first_show.id,
        second_show.id,
    ]

def test_excludes_stale_show_from_watch_next() -> None:
    """A stale Watching Show belongs to Stale Watching, not Watch Next."""

    library_repository = Mock(spec=LibraryRepository)
    progress_repository = Mock(spec=EpisodeProgressRepository)
    episode_repository = Mock(spec=EpisodeRepository)

    show = create_show()
    entry = create_library_entry(show=show)

    episode = create_episode(
        air_date=date(2026, 5, 1),
    )

    library_repository.list_shows_by_user.return_value = [entry]

    progress_repository.list_next_unwatched_for_shows.return_value = {
        show.id: NextUnwatchedEpisode(
            show_id=show.id,
            episode=episode,
            season_number=2,
        )
    }

    last_episode = create_episode(
        tmdb_id=1947647,
        episode_number=3,
        title="Last Watched",
    )

    episode_repository.get_aired_counts_by_show_ids.return_value = {
        show.id: 10,
    }

    progress_repository.get_watched_aired_counts_by_show_ids.return_value = {
        show.id: 7,
    }

    service = create_service(
        library_repository=library_repository,
        episode_repository=episode_repository,
        progress_repository=progress_repository,
        last_watched_by_show={
            show.id: LastWatchedEpisode(
                show_id=show.id,
                episode=last_episode,
                season_number=2,
                watched_at=datetime.now(UTC) - timedelta(days=61),
            ),
        },
    )

    result = service.list_for_user(
        user_id=uuid4(),
    )

    assert result == []

def test_keeps_recently_watched_show_in_watch_next() -> None:
    """A recently watched Show with an available Episode stays in Watch Next."""

    library_repository = Mock(spec=LibraryRepository)
    progress_repository = Mock(spec=EpisodeProgressRepository)
    episode_repository = Mock(spec=EpisodeRepository)

    show = create_show()
    entry = create_library_entry(show=show)
    episode = create_episode()

    last_episode = create_episode(
        tmdb_id=1947647,
        episode_number=3,
        title="Last Watched",
    )

    library_repository.list_shows_by_user.return_value = [entry]

    progress_repository.list_next_unwatched_for_shows.return_value = {
        show.id: NextUnwatchedEpisode(
            show_id=show.id,
            episode=episode,
            season_number=2,
        )
    }

    episode_repository.get_aired_counts_by_show_ids.return_value = {
        show.id: 10,
    }

    progress_repository.get_watched_aired_counts_by_show_ids.return_value = {
        show.id: 7,
    }

    service = create_service(
        library_repository=library_repository,
        episode_repository=episode_repository,
        progress_repository=progress_repository,
        last_watched_by_show={
            show.id: LastWatchedEpisode(
                show_id=show.id,
                episode=last_episode,
                season_number=2,
                watched_at=datetime.now(UTC) - timedelta(days=10),
            ),
        },
    )

    result = service.list_for_user(
        user_id=uuid4(),
    )

    assert len(result) == 1
    assert result[0].show.id == show.id
    assert result[0].next_episode.id == episode.id

def test_orders_watch_next_by_episode_air_date() -> None:
    """Order Watch Next by oldest available Episode air date first."""

    library_repository = Mock(spec=LibraryRepository)
    progress_repository = Mock(spec=EpisodeProgressRepository)
    episode_repository = Mock(spec=EpisodeRepository)

    older_show = create_show(
        tmdb_id=95396,
        title="Severance",
    )

    newer_show = create_show(
        tmdb_id=100088,
        title="The Last of Us",
    )

    older_entry = create_library_entry(show=older_show)
    newer_entry = create_library_entry(show=newer_show)

    older_episode = create_episode(
        tmdb_id=1001,
        title="Older Episode",
        air_date=date(2026, 8, 10),
    )

    newer_episode = create_episode(
        tmdb_id=1002,
        title="Newer Episode",
        air_date=date(2026, 8, 12),
    )

    library_repository.list_shows_by_user.return_value = [
        newer_entry,
        older_entry,
    ]

    progress_repository.list_next_unwatched_for_shows.return_value = {
        older_show.id: NextUnwatchedEpisode(
            show_id=older_show.id,
            episode=older_episode,
            season_number=1,
        ),
        newer_show.id: NextUnwatchedEpisode(
            show_id=newer_show.id,
            episode=newer_episode,
            season_number=1,
        ),
    }

    episode_repository.get_aired_counts_by_show_ids.return_value = {
        older_show.id: 5,
        newer_show.id: 5,
    }

    progress_repository.get_watched_aired_counts_by_show_ids.return_value = {
        older_show.id: 2,
        newer_show.id: 2,
    }

    service = create_service(
        library_repository=library_repository,
        episode_repository=episode_repository,
        progress_repository=progress_repository,
    )

    result = service.list_for_user(
        user_id=uuid4(),
    )

    assert [item.show.title for item in result] == [
        "Severance",
        "The Last of Us",
    ]

def test_orders_same_air_date_by_show_title() -> None:
    """Use Show title as deterministic tie-breaker for equal air dates."""

    library_repository = Mock(spec=LibraryRepository)
    progress_repository = Mock(spec=EpisodeProgressRepository)
    episode_repository = Mock(spec=EpisodeRepository)

    zebra_show = create_show(
        tmdb_id=100001,
        title="Zebra",
    )

    alpha_show = create_show(
        tmdb_id=100002,
        title="Alpha",
    )

    zebra_entry = create_library_entry(show=zebra_show)
    alpha_entry = create_library_entry(show=alpha_show)

    shared_air_date = date(2026, 8, 10)

    zebra_episode = create_episode(
        tmdb_id=2001,
        title="Episode Z",
        air_date=shared_air_date,
    )

    alpha_episode = create_episode(
        tmdb_id=2002,
        title="Episode A",
        air_date=shared_air_date,
    )

    library_repository.list_shows_by_user.return_value = [
        zebra_entry,
        alpha_entry,
    ]

    progress_repository.list_next_unwatched_for_shows.return_value = {
        zebra_show.id: NextUnwatchedEpisode(
            show_id=zebra_show.id,
            episode=zebra_episode,
            season_number=1,
        ),
        alpha_show.id: NextUnwatchedEpisode(
            show_id=alpha_show.id,
            episode=alpha_episode,
            season_number=1,
        ),
    }

    episode_repository.get_aired_counts_by_show_ids.return_value = {
        zebra_show.id: 5,
        alpha_show.id: 5,
    }

    progress_repository.get_watched_aired_counts_by_show_ids.return_value = {
        zebra_show.id: 2,
        alpha_show.id: 2,
    }

    service = create_service(
        library_repository=library_repository,
        episode_repository=episode_repository,
        progress_repository=progress_repository,
    )

    result = service.list_for_user(
        user_id=uuid4(),
    )

    assert [item.show.title for item in result] == [
        "Alpha",
        "Zebra",
    ]

def test_caught_up_show_returns_to_watch_next_when_new_episode_airs() -> None:
    """A caught-up Watching Show returns when a new aired Episode is available."""

    library_repository = Mock(spec=LibraryRepository)
    progress_repository = Mock(spec=EpisodeProgressRepository)
    episode_repository = Mock(spec=EpisodeRepository)

    show = create_show()
    entry = create_library_entry(show=show)

    new_episode = create_episode(
        tmdb_id=2001,
        episode_number=5,
        title="Newly Aired",
        air_date=datetime.now(UTC).date(),
    )

    library_repository.list_shows_by_user.return_value = [entry]

    progress_repository.list_next_unwatched_for_shows.side_effect = [
        {},
        {
            show.id: NextUnwatchedEpisode(
                show_id=show.id,
                episode=new_episode,
                season_number=2,
            )
        },
    ]

    episode_repository.get_aired_counts_by_show_ids.side_effect = [
        {
            show.id: 4,
        },
        {
            show.id: 5,
        },
    ]

    progress_repository.get_watched_aired_counts_by_show_ids.side_effect = [
        {
            show.id: 4,
        },
        {
            show.id: 4,
        },
    ]

    service = create_service(
        library_repository=library_repository,
        episode_repository=episode_repository,
        progress_repository=progress_repository,
    )

    user_id = uuid4()

    caught_up_result = service.list_for_user(
        user_id=user_id,
    )

    assert caught_up_result == []

    new_episode_result = service.list_for_user(
        user_id=user_id,
    )

    assert len(new_episode_result) == 1

    item = new_episode_result[0]

    assert item.show.id == show.id
    assert item.next_episode.id == new_episode.id
    assert item.progress.watched_episodes == 4
    assert item.progress.aired_episodes == 5
    assert item.progress.percentage == 80.0


def test_ended_show_with_unwatched_episode_remains_in_watch_next() -> None:
    """An ended Show may still belong to Watch Next while Episodes remain."""

    library_repository = Mock(spec=LibraryRepository)
    progress_repository = Mock(spec=EpisodeProgressRepository)
    episode_repository = Mock(spec=EpisodeRepository)

    show = create_show(
        title="Breaking Bad",
    )
    show.status = "Ended"

    entry = create_library_entry(
        show=show,
        status=LibraryStatus.WATCHING,
    )

    episode = create_episode(
        tmdb_id=3001,
        episode_number=10,
        title="Fly",
        air_date=date(2010, 5, 23),
    )

    library_repository.list_shows_by_user.return_value = [entry]

    progress_repository.list_next_unwatched_for_shows.return_value = {
        show.id: NextUnwatchedEpisode(
            show_id=show.id,
            episode=episode,
            season_number=3,
        ),
    }

    episode_repository.get_aired_counts_by_show_ids.return_value = {
        show.id: 62,
    }

    progress_repository.get_watched_aired_counts_by_show_ids.return_value = {
        show.id: 29,
    }

    service = create_service(
        library_repository=library_repository,
        episode_repository=episode_repository,
        progress_repository=progress_repository,
    )

    result = service.list_for_user(
        user_id=uuid4(),
    )

    assert len(result) == 1

    item = result[0]

    assert item.show.id == show.id
    assert item.show.status == "Ended"
    assert item.library_status == LibraryStatus.WATCHING
    assert item.next_episode.id == episode.id