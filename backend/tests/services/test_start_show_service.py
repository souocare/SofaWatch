from datetime import date
from types import SimpleNamespace
from unittest.mock import Mock
from uuid import uuid4

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.enums import LibraryStatus
from app.models.episode import Episode
from app.models.episode_progress import EpisodeProgress
from app.models.episode_watch_event import EpisodeWatchEvent
from app.models.library import LibraryEntry
from app.models.season import Season
from app.models.show import Show
from app.models.user import User
from app.repositories.episode import EpisodeRepository
from app.repositories.episode_progress import EpisodeProgressRepository
from app.repositories.episode_watch_event import EpisodeWatchEventRepository
from app.repositories.library import LibraryRepository
from app.repositories.show import ShowRepository
from app.services.show_library_status import ShowLibraryStatusSynchronizer
from app.services.start_show import StartShowService


def create_service(
    *,
    session: Mock,
    library_repository: Mock,
    episode_repository: Mock,
    progress_repository: Mock,
    watch_event_repository: Mock | None = None,
    show_status_synchronizer: Mock | None = None,
) -> StartShowService:
    """Create a Start Show service with mocked dependencies."""

    return StartShowService(
        session=session,
        library_repository=library_repository,
        episode_repository=episode_repository,
        progress_repository=progress_repository,
        watch_event_repository=(watch_event_repository or Mock(spec=EpisodeWatchEventRepository)),
        show_status_synchronizer=(
            show_status_synchronizer or Mock(spec=ShowLibraryStatusSynchronizer)
        ),
    )


def test_starts_planning_show_from_first_available_episode() -> None:
    """Start a Planning Show and synchronize its derived Library status."""

    session = Mock(spec=Session)
    library_repository = Mock(spec=LibraryRepository)
    episode_repository = Mock(spec=EpisodeRepository)
    progress_repository = Mock(spec=EpisodeProgressRepository)
    watch_event_repository = Mock(spec=EpisodeWatchEventRepository)
    show_status_synchronizer = Mock(spec=ShowLibraryStatusSynchronizer)

    user_id = uuid4()
    show_id = uuid4()
    entry_id = uuid4()
    episode_id = uuid4()

    entry = SimpleNamespace(
        id=entry_id,
        show_id=show_id,
        status=LibraryStatus.PLANNING,
        started_at=None,
    )

    episode = SimpleNamespace(
        id=episode_id,
    )

    library_repository.get_by_user_and_show.return_value = entry

    episode_repository.get_first_aired_regular_for_show.return_value = (
        episode,
        1,
    )

    progress_repository.get_by_user_and_episode.return_value = None

    def synchronize_status(
        *,
        user_id: object,
        show_id: object,
        watched_at: object,
    ) -> None:
        entry.status = LibraryStatus.WATCHING
        entry.started_at = watched_at

    show_status_synchronizer.after_watch.side_effect = synchronize_status

    service = create_service(
        session=session,
        library_repository=library_repository,
        episode_repository=episode_repository,
        progress_repository=progress_repository,
        watch_event_repository=watch_event_repository,
        show_status_synchronizer=show_status_synchronizer,
    )

    result = service.start(
        user_id=user_id,
        show_id=show_id,
    )

    assert result is not None

    progress_repository.add.assert_called_once()

    progress = progress_repository.add.call_args.args[0]

    assert progress.user_id == user_id
    assert progress.episode_id == episode_id
    assert progress.is_watched is True
    assert progress.watched_at is not None

    episode_repository.get_first_aired_regular_for_show.assert_called_once_with(
        show_id=show_id,
        as_of=date.today(),
    )

    watch_event_repository.add.assert_called_once()

    watch_event = watch_event_repository.add.call_args.args[0]

    assert watch_event.user_id == user_id
    assert watch_event.episode_id == episode_id
    assert watch_event.watched_at == progress.watched_at

    show_status_synchronizer.after_watch.assert_called_once_with(
        user_id=user_id,
        show_id=show_id,
        watched_at=progress.watched_at,
    )

    assert entry.status == LibraryStatus.WATCHING
    assert entry.started_at == progress.watched_at

    assert result.library_entry_id == entry_id
    assert result.library_status == LibraryStatus.WATCHING
    assert result.show_id == show_id
    assert result.started_episode_id == episode_id

    session.commit.assert_called_once_with()


def test_reuses_existing_unwatched_progress() -> None:
    """Reuse existing progress and synchronize the Show Library status."""

    session = Mock(spec=Session)
    library_repository = Mock(spec=LibraryRepository)
    episode_repository = Mock(spec=EpisodeRepository)
    progress_repository = Mock(spec=EpisodeProgressRepository)
    watch_event_repository = Mock(spec=EpisodeWatchEventRepository)
    show_status_synchronizer = Mock(spec=ShowLibraryStatusSynchronizer)

    user_id = uuid4()
    show_id = uuid4()
    episode_id = uuid4()

    entry = SimpleNamespace(
        id=uuid4(),
        show_id=show_id,
        status=LibraryStatus.PLANNING,
        started_at=None,
    )

    episode = SimpleNamespace(
        id=episode_id,
    )

    existing_progress = SimpleNamespace(
        user_id=user_id,
        episode_id=episode_id,
        is_watched=False,
        watched_at=None,
    )

    library_repository.get_by_user_and_show.return_value = entry

    episode_repository.get_first_aired_regular_for_show.return_value = (
        episode,
        1,
    )

    progress_repository.get_by_user_and_episode.return_value = existing_progress

    def synchronize_status(
        *,
        user_id: object,
        show_id: object,
        watched_at: object,
    ) -> None:
        entry.status = LibraryStatus.WATCHING
        entry.started_at = watched_at

    show_status_synchronizer.after_watch.side_effect = synchronize_status

    service = create_service(
        session=session,
        library_repository=library_repository,
        episode_repository=episode_repository,
        progress_repository=progress_repository,
        watch_event_repository=watch_event_repository,
        show_status_synchronizer=show_status_synchronizer,
    )

    result = service.start(
        user_id=user_id,
        show_id=show_id,
    )

    assert result is not None

    assert existing_progress.is_watched is True
    assert existing_progress.watched_at is not None

    progress_repository.add.assert_not_called()

    watch_event_repository.add.assert_called_once()

    watch_event = watch_event_repository.add.call_args.args[0]

    assert watch_event.user_id == user_id
    assert watch_event.episode_id == episode_id
    assert watch_event.watched_at == existing_progress.watched_at

    show_status_synchronizer.after_watch.assert_called_once_with(
        user_id=user_id,
        show_id=show_id,
        watched_at=existing_progress.watched_at,
    )

    assert entry.status == LibraryStatus.WATCHING
    assert entry.started_at == existing_progress.watched_at

    assert result.library_status == LibraryStatus.WATCHING
    assert result.started_episode_id == episode_id

    session.commit.assert_called_once_with()


def test_returns_none_when_show_is_not_in_library() -> None:
    """Do not start a Show that is not in the user's Library."""

    session = Mock(spec=Session)
    library_repository = Mock(spec=LibraryRepository)
    episode_repository = Mock(spec=EpisodeRepository)
    progress_repository = Mock(spec=EpisodeProgressRepository)
    watch_event_repository = Mock(spec=EpisodeWatchEventRepository)
    show_status_synchronizer = Mock(spec=ShowLibraryStatusSynchronizer)

    library_repository.get_by_user_and_show.return_value = None

    service = create_service(
        session=session,
        library_repository=library_repository,
        episode_repository=episode_repository,
        progress_repository=progress_repository,
        watch_event_repository=watch_event_repository,
        show_status_synchronizer=show_status_synchronizer,
    )

    result = service.start(
        user_id=uuid4(),
        show_id=uuid4(),
    )

    assert result is None

    episode_repository.get_first_aired_regular_for_show.assert_not_called()
    progress_repository.add.assert_not_called()
    watch_event_repository.add.assert_not_called()
    show_status_synchronizer.after_watch.assert_not_called()
    session.commit.assert_not_called()


def test_returns_none_when_no_aired_episode_is_available() -> None:
    """Do not start a Show without an aired regular Episode."""

    session = Mock(spec=Session)
    library_repository = Mock(spec=LibraryRepository)
    episode_repository = Mock(spec=EpisodeRepository)
    progress_repository = Mock(spec=EpisodeProgressRepository)
    watch_event_repository = Mock(spec=EpisodeWatchEventRepository)
    show_status_synchronizer = Mock(spec=ShowLibraryStatusSynchronizer)

    user_id = uuid4()
    show_id = uuid4()

    entry = SimpleNamespace(
        id=uuid4(),
        show_id=show_id,
        status=LibraryStatus.PLANNING,
        started_at=None,
    )

    library_repository.get_by_user_and_show.return_value = entry
    episode_repository.get_first_aired_regular_for_show.return_value = None

    service = create_service(
        session=session,
        library_repository=library_repository,
        episode_repository=episode_repository,
        progress_repository=progress_repository,
        watch_event_repository=watch_event_repository,
        show_status_synchronizer=show_status_synchronizer,
    )

    result = service.start(
        user_id=user_id,
        show_id=show_id,
    )

    assert result is None

    progress_repository.add.assert_not_called()
    watch_event_repository.add.assert_not_called()
    show_status_synchronizer.after_watch.assert_not_called()
    session.commit.assert_not_called()

    assert entry.status == LibraryStatus.PLANNING
    assert entry.started_at is None


def test_starting_single_episode_terminal_show_completes_library_entry(
    db_session: Session,
) -> None:
    """Starting a terminal one-Episode Show must complete its Library entry."""

    user = User(
        display_name="Test User",
    )
    db_session.add(user)
    db_session.flush()

    show = Show(
        tmdb_id=999001,
        title="Completed Miniseries",
        original_title="Completed Miniseries",
        original_language="en",
        metadata_language="en-US",
        status="Ended",
        in_production=False,
    )
    db_session.add(show)
    db_session.flush()

    season = Season(
        show_id=show.id,
        tmdb_id=999002,
        season_number=1,
        title="Season 1",
    )
    db_session.add(season)
    db_session.flush()

    episode = Episode(
        season_id=season.id,
        tmdb_id=999003,
        episode_number=1,
        title="Episode 1",
        air_date=date(2026, 8, 1),
    )
    db_session.add(episode)
    db_session.flush()

    entry = LibraryEntry(
        user_id=user.id,
        show_id=show.id,
        status=LibraryStatus.PLANNING,
    )
    db_session.add(entry)
    db_session.flush()

    library_repository = LibraryRepository(db_session)
    episode_repository = EpisodeRepository(db_session)
    progress_repository = EpisodeProgressRepository(db_session)
    watch_event_repository = EpisodeWatchEventRepository(db_session)

    show_status_synchronizer = ShowLibraryStatusSynchronizer(
        session=db_session,
        library_repository=library_repository,
        show_repository=ShowRepository(db_session),
        episode_repository=episode_repository,
        progress_repository=progress_repository,
    )

    service = StartShowService(
        session=db_session,
        library_repository=library_repository,
        episode_repository=episode_repository,
        progress_repository=progress_repository,
        watch_event_repository=watch_event_repository,
        show_status_synchronizer=show_status_synchronizer,
    )

    result = service.start(
        user_id=user.id,
        show_id=show.id,
    )

    assert result is not None

    assert result.library_entry_id == entry.id
    assert result.show_id == show.id
    assert result.started_episode_id == episode.id
    assert result.library_status == LibraryStatus.COMPLETED

    db_session.refresh(entry)

    assert entry.status == LibraryStatus.COMPLETED
    assert entry.started_at is not None
    assert entry.completed_at is not None
    assert entry.completed_at == entry.started_at

    progress = db_session.scalar(
        select(EpisodeProgress).where(
            EpisodeProgress.user_id == user.id,
            EpisodeProgress.episode_id == episode.id,
        )
    )

    assert progress is not None
    assert progress.is_watched is True
    assert progress.watched_at is not None

    watch_events = list(
        db_session.scalars(
            select(EpisodeWatchEvent).where(
                EpisodeWatchEvent.user_id == user.id,
                EpisodeWatchEvent.episode_id == episode.id,
            )
        )
    )

    assert len(watch_events) == 1
    assert watch_events[0].watched_at is not None
