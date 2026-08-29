from datetime import UTC, date, datetime, timedelta
from types import SimpleNamespace
from unittest.mock import Mock
from uuid import UUID, uuid4

from app.models.enums import LibraryStatus
from app.repositories.episode import EpisodeRepository
from app.repositories.episode_progress import (
    EpisodeProgressRepository,
    LastWatchedEpisode,
    NextUnwatchedEpisode,
)
from app.repositories.library import LibraryRepository
from app.services.stale_watching import StaleWatchingService


def create_show(
    *,
    show_id: UUID | None = None,
    tmdb_id: int = 95396,
    title: str = "Severance",
) -> SimpleNamespace:
    """Create Show-like data required by StaleWatchingService."""

    return SimpleNamespace(
        id=show_id or uuid4(),
        tmdb_id=tmdb_id,
        title=title,
        original_title=title,
        first_air_date=None,
        tmdb_poster_path=None,
        local_poster_path=None,
        poster_url=None,
        backdrop_url=None,
        status="Returning Series",
        vote_average=8.4,
    )


def create_library_entry(
    *,
    show: SimpleNamespace,
) -> SimpleNamespace:
    """Create LibraryEntry-like data required by StaleWatchingService."""

    return SimpleNamespace(
        id=uuid4(),
        show_id=show.id,
        show=show,
        status=LibraryStatus.WATCHING,
    )


def create_episode(
    *,
    tmdb_id: int,
    episode_number: int,
    title: str,
    air_date: date | None = None,
) -> SimpleNamespace:
    """Create Episode-like data required by StaleWatchingService."""

    return SimpleNamespace(
        id=uuid4(),
        tmdb_id=tmdb_id,
        episode_number=episode_number,
        title=title,
        air_date=air_date,
        runtime=50,
        still_url=None,
    )


def create_service(
    *,
    library_repository: Mock,
    episode_repository: Mock,
    progress_repository: Mock,
) -> StaleWatchingService:
    """Create StaleWatchingService with mocked repositories."""

    return StaleWatchingService(
        library_repository=library_repository,
        episode_repository=episode_repository,
        progress_repository=progress_repository,
    )


def test_includes_show_when_activity_and_pending_episode_are_stale() -> None:
    """Include a Watching Show inactive for more than 60 days."""

    library_repository = Mock(spec=LibraryRepository)
    episode_repository = Mock(spec=EpisodeRepository)
    progress_repository = Mock(spec=EpisodeProgressRepository)

    show = create_show()
    entry = create_library_entry(show=show)

    last_episode = create_episode(
        tmdb_id=1001,
        episode_number=3,
        title="Last Watched",
    )

    next_episode = create_episode(
        tmdb_id=1002,
        episode_number=4,
        title="Next Episode",
        air_date=date(2026, 5, 1),
    )

    last_watched_at = datetime.now(UTC) - timedelta(days=61)

    library_repository.list_shows_by_user.return_value = [entry]

    progress_repository.list_last_watched_for_shows.return_value = {
        show.id: LastWatchedEpisode(
            show_id=show.id,
            episode=last_episode,
            season_number=1,
            watched_at=last_watched_at,
        )
    }

    progress_repository.list_next_unwatched_for_shows.return_value = {
        show.id: NextUnwatchedEpisode(
            show_id=show.id,
            episode=next_episode,
            season_number=1,
        )
    }

    episode_repository.get_aired_counts_by_show_ids.return_value = {
        show.id: 10,
    }

    progress_repository.get_watched_aired_counts_by_show_ids.return_value = {
        show.id: 4,
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

    assert item.show.tmdb_id == 95396
    assert item.library_status == LibraryStatus.WATCHING

    assert item.last_watched.episode_number == 3
    assert item.last_watched.watched_at == last_watched_at

    assert item.next_episode.episode_number == 4

    assert item.progress.watched_episodes == 4
    assert item.progress.aired_episodes == 10
    assert item.progress.percentage == 40.0
    assert item.progress.caught_up is False


def test_excludes_show_when_pending_episode_is_recent() -> None:
    """Keep newly available content out of stale Watching."""

    library_repository = Mock(spec=LibraryRepository)
    episode_repository = Mock(spec=EpisodeRepository)
    progress_repository = Mock(spec=EpisodeProgressRepository)

    show = create_show()
    entry = create_library_entry(show=show)

    last_episode = create_episode(
        tmdb_id=1001,
        episode_number=8,
        title="Previous Finale",
    )

    next_episode = create_episode(
        tmdb_id=1002,
        episode_number=1,
        title="New Season Premiere",
        air_date=datetime.now(UTC).date(),
    )

    library_repository.list_shows_by_user.return_value = [entry]

    progress_repository.list_last_watched_for_shows.return_value = {
        show.id: LastWatchedEpisode(
            show_id=show.id,
            episode=last_episode,
            season_number=1,
            watched_at=datetime.now(UTC) - timedelta(days=100),
        )
    }

    progress_repository.list_next_unwatched_for_shows.return_value = {
        show.id: NextUnwatchedEpisode(
            show_id=show.id,
            episode=next_episode,
            season_number=2,
        )
    }

    episode_repository.get_aired_counts_by_show_ids.return_value = {
        show.id: 10,
    }

    progress_repository.get_watched_aired_counts_by_show_ids.return_value = {
        show.id: 8,
    }

    service = create_service(
        library_repository=library_repository,
        episode_repository=episode_repository,
        progress_repository=progress_repository,
    )

    result = service.list_for_user(
        user_id=uuid4(),
    )

    assert result == []


def test_excludes_show_when_last_watched_less_than_60_days_ago() -> None:
    """Exclude a Watching Show that was viewed recently."""

    library_repository = Mock(spec=LibraryRepository)
    episode_repository = Mock(spec=EpisodeRepository)
    progress_repository = Mock(spec=EpisodeProgressRepository)

    show = create_show()
    entry = create_library_entry(show=show)

    last_episode = create_episode(
        tmdb_id=1001,
        episode_number=3,
        title="Last Watched",
    )

    library_repository.list_shows_by_user.return_value = [entry]

    progress_repository.list_last_watched_for_shows.return_value = {
        show.id: LastWatchedEpisode(
            show_id=show.id,
            episode=last_episode,
            season_number=1,
            watched_at=datetime.now(UTC) - timedelta(days=59),
        )
    }

    service = create_service(
        library_repository=library_repository,
        episode_repository=episode_repository,
        progress_repository=progress_repository,
    )

    result = service.list_for_user(
        user_id=uuid4(),
    )

    assert result == []

    progress_repository.list_next_unwatched_for_shows.assert_not_called()
    episode_repository.get_aired_counts_by_show_ids.assert_not_called()
    progress_repository.get_watched_aired_counts_by_show_ids.assert_not_called()


def test_excludes_show_that_has_never_been_started() -> None:
    """Exclude a Show when no watched Episode exists."""

    library_repository = Mock(spec=LibraryRepository)
    episode_repository = Mock(spec=EpisodeRepository)
    progress_repository = Mock(spec=EpisodeProgressRepository)

    show = create_show()
    entry = create_library_entry(show=show)

    library_repository.list_shows_by_user.return_value = [entry]

    progress_repository.list_last_watched_for_shows.return_value = {}

    service = create_service(
        library_repository=library_repository,
        episode_repository=episode_repository,
        progress_repository=progress_repository,
    )

    result = service.list_for_user(
        user_id=uuid4(),
    )

    assert result == []

    progress_repository.list_next_unwatched_for_shows.assert_not_called()
    episode_repository.get_aired_counts_by_show_ids.assert_not_called()
    progress_repository.get_watched_aired_counts_by_show_ids.assert_not_called()


def test_excludes_caught_up_show_without_next_unwatched_episode() -> None:
    """Exclude a stale Show that has no aired unwatched Episode left."""

    library_repository = Mock(spec=LibraryRepository)
    episode_repository = Mock(spec=EpisodeRepository)
    progress_repository = Mock(spec=EpisodeProgressRepository)

    show = create_show()
    entry = create_library_entry(show=show)

    last_episode = create_episode(
        tmdb_id=1001,
        episode_number=3,
        title="Last Watched",
    )

    library_repository.list_shows_by_user.return_value = [entry]

    progress_repository.list_last_watched_for_shows.return_value = {
        show.id: LastWatchedEpisode(
            show_id=show.id,
            episode=last_episode,
            season_number=1,
            watched_at=datetime.now(UTC) - timedelta(days=90),
        )
    }

    progress_repository.list_next_unwatched_for_shows.return_value = {}

    service = create_service(
        library_repository=library_repository,
        episode_repository=episode_repository,
        progress_repository=progress_repository,
    )

    result = service.list_for_user(
        user_id=uuid4(),
    )

    assert result == []

    episode_repository.get_aired_counts_by_show_ids.assert_not_called()
    progress_repository.get_watched_aired_counts_by_show_ids.assert_not_called()


def test_orders_oldest_activity_first() -> None:
    """Order stale Shows by oldest watched activity first."""

    library_repository = Mock(spec=LibraryRepository)
    episode_repository = Mock(spec=EpisodeRepository)
    progress_repository = Mock(spec=EpisodeProgressRepository)

    older_show = create_show(
        tmdb_id=95396,
        title="Severance",
    )

    newer_show = create_show(
        tmdb_id=100088,
        title="The Last of Us",
    )

    older_entry = create_library_entry(
        show=older_show,
    )

    newer_entry = create_library_entry(
        show=newer_show,
    )

    older_last_episode = create_episode(
        tmdb_id=1001,
        episode_number=2,
        title="Older Last Watched",
    )

    newer_last_episode = create_episode(
        tmdb_id=2001,
        episode_number=5,
        title="Newer Last Watched",
    )

    older_next_episode = create_episode(
        tmdb_id=1002,
        episode_number=3,
        title="Older Next",
        air_date=date(2026, 5, 1),
    )

    newer_next_episode = create_episode(
        tmdb_id=2002,
        episode_number=6,
        title="Newer Next",
        air_date=date(2026, 5, 15),
    )

    older_watched_at = datetime.now(UTC) - timedelta(days=120)
    newer_watched_at = datetime.now(UTC) - timedelta(days=70)

    library_repository.list_shows_by_user.return_value = [
        newer_entry,
        older_entry,
    ]

    progress_repository.list_last_watched_for_shows.return_value = {
        older_show.id: LastWatchedEpisode(
            show_id=older_show.id,
            episode=older_last_episode,
            season_number=1,
            watched_at=older_watched_at,
        ),
        newer_show.id: LastWatchedEpisode(
            show_id=newer_show.id,
            episode=newer_last_episode,
            season_number=1,
            watched_at=newer_watched_at,
        ),
    }

    progress_repository.list_next_unwatched_for_shows.return_value = {
        older_show.id: NextUnwatchedEpisode(
            show_id=older_show.id,
            episode=older_next_episode,
            season_number=1,
        ),
        newer_show.id: NextUnwatchedEpisode(
            show_id=newer_show.id,
            episode=newer_next_episode,
            season_number=1,
        ),
    }

    episode_repository.get_aired_counts_by_show_ids.return_value = {
        older_show.id: 10,
        newer_show.id: 20,
    }

    progress_repository.get_watched_aired_counts_by_show_ids.return_value = {
        older_show.id: 4,
        newer_show.id: 12,
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

    assert result[0].last_watched.watched_at == older_watched_at
    assert result[1].last_watched.watched_at == newer_watched_at

    assert result[0].progress.watched_episodes == 4
    assert result[0].progress.aired_episodes == 10
    assert result[0].progress.percentage == 40.0
    assert result[0].progress.caught_up is False

    assert result[1].progress.watched_episodes == 12
    assert result[1].progress.aired_episodes == 20
    assert result[1].progress.percentage == 60.0
    assert result[1].progress.caught_up is False


def test_empty_watching_library_does_not_query_progress() -> None:
    """Avoid progress queries when there are no Watching Shows."""

    library_repository = Mock(spec=LibraryRepository)
    episode_repository = Mock(spec=EpisodeRepository)
    progress_repository = Mock(spec=EpisodeProgressRepository)

    library_repository.list_shows_by_user.return_value = []

    service = create_service(
        library_repository=library_repository,
        episode_repository=episode_repository,
        progress_repository=progress_repository,
    )

    result = service.list_for_user(
        user_id=uuid4(),
    )

    assert result == []

    progress_repository.list_last_watched_for_shows.assert_not_called()
    progress_repository.list_next_unwatched_for_shows.assert_not_called()
    episode_repository.get_aired_counts_by_show_ids.assert_not_called()
    progress_repository.get_watched_aired_counts_by_show_ids.assert_not_called()


def test_requests_only_watching_library_entries() -> None:
    """Stale Watching must read only Shows currently marked as Watching."""

    library_repository = Mock(spec=LibraryRepository)
    episode_repository = Mock(spec=EpisodeRepository)
    progress_repository = Mock(spec=EpisodeProgressRepository)

    library_repository.list_shows_by_user.return_value = []

    service = create_service(
        library_repository=library_repository,
        episode_repository=episode_repository,
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

    progress_repository.list_last_watched_for_shows.assert_not_called()
    progress_repository.list_next_unwatched_for_shows.assert_not_called()
    episode_repository.get_aired_counts_by_show_ids.assert_not_called()
    progress_repository.get_watched_aired_counts_by_show_ids.assert_not_called()