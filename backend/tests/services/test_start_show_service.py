from datetime import date
from types import SimpleNamespace
from unittest.mock import Mock
from uuid import uuid4

from sqlalchemy.orm import Session

from app.models.enums import LibraryStatus
from app.repositories.episode import EpisodeRepository
from app.repositories.episode_progress import EpisodeProgressRepository
from app.repositories.episode_watch_event import EpisodeWatchEventRepository
from app.repositories.library import LibraryRepository
from app.services.start_show import StartShowService


def create_service(
    *,
    session: Mock,
    library_repository: Mock,
    episode_repository: Mock,
    progress_repository: Mock,
    watch_event_repository: Mock | None = None,
) -> StartShowService:
    return StartShowService(
        session=session,
        library_repository=library_repository,
        episode_repository=episode_repository,
        progress_repository=progress_repository,
        watch_event_repository=(watch_event_repository or Mock(spec=EpisodeWatchEventRepository)),
    )


def test_starts_planning_show_from_first_available_episode() -> None:
    """Start a Planning Show and mark its first Episode as watched."""

    session = Mock(spec=Session)
    library_repository = Mock(spec=LibraryRepository)
    episode_repository = Mock(spec=EpisodeRepository)
    progress_repository = Mock(spec=EpisodeProgressRepository)

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

    watch_event_repository = Mock(spec=EpisodeWatchEventRepository)

    service = create_service(
        session=session,
        library_repository=library_repository,
        episode_repository=episode_repository,
        progress_repository=progress_repository,
        watch_event_repository=watch_event_repository,
    )

    result = service.start(
        user_id=user_id,
        show_id=show_id,
    )

    assert result is not None

    assert entry.status == LibraryStatus.WATCHING
    assert entry.started_at is not None

    assert result.library_entry_id == entry_id
    assert result.library_status == LibraryStatus.WATCHING
    assert result.show_id == show_id
    assert result.started_episode_id == episode_id

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
    assert watch_event.watched_at is not None

    assert watch_event.watched_at == progress.watched_at

    session.commit.assert_called_once_with()


def test_reuses_existing_unwatched_progress() -> None:
    """Reuse an existing EpisodeProgress entry when starting a Show."""

    session = Mock(spec=Session)
    library_repository = Mock(spec=LibraryRepository)
    episode_repository = Mock(spec=EpisodeRepository)
    progress_repository = Mock(spec=EpisodeProgressRepository)

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

    watch_event_repository = Mock(spec=EpisodeWatchEventRepository)

    service = create_service(
        session=session,
        library_repository=library_repository,
        episode_repository=episode_repository,
        progress_repository=progress_repository,
        watch_event_repository=watch_event_repository,
    )

    result = service.start(
        user_id=user_id,
        show_id=show_id,
    )

    assert result is not None

    assert existing_progress.is_watched is True
    assert existing_progress.watched_at is not None

    progress_repository.add.assert_not_called()

    assert entry.status == LibraryStatus.WATCHING

    watch_event_repository.add.assert_called_once()

    watch_event = watch_event_repository.add.call_args.args[0]

    assert watch_event.user_id == user_id
    assert watch_event.episode_id == episode_id
    assert watch_event.watched_at == existing_progress.watched_at

    session.commit.assert_called_once_with()


def test_returns_none_when_show_is_not_in_library() -> None:
    """Do not start a Show that is not in the user's Library."""

    session = Mock(spec=Session)
    library_repository = Mock(spec=LibraryRepository)
    episode_repository = Mock(spec=EpisodeRepository)
    progress_repository = Mock(spec=EpisodeProgressRepository)

    library_repository.get_by_user_and_show.return_value = None
    watch_event_repository = Mock(spec=EpisodeWatchEventRepository)

    service = create_service(
        session=session,
        library_repository=library_repository,
        episode_repository=episode_repository,
        progress_repository=progress_repository,
    )

    result = service.start(
        user_id=uuid4(),
        show_id=uuid4(),
    )

    assert result is None

    episode_repository.get_first_aired_regular_for_show.assert_not_called()
    progress_repository.add.assert_not_called()
    session.commit.assert_not_called()
    watch_event_repository.add.assert_not_called()


def test_returns_none_when_no_aired_episode_is_available() -> None:
    """Do not start a Show without an aired regular Episode."""

    session = Mock(spec=Session)
    library_repository = Mock(spec=LibraryRepository)
    episode_repository = Mock(spec=EpisodeRepository)
    progress_repository = Mock(spec=EpisodeProgressRepository)

    show_id = uuid4()

    entry = SimpleNamespace(
        id=uuid4(),
        show_id=show_id,
        status=LibraryStatus.PLANNING,
        started_at=None,
    )

    library_repository.get_by_user_and_show.return_value = entry

    episode_repository.get_first_aired_regular_for_show.return_value = None

    watch_event_repository = Mock(spec=EpisodeWatchEventRepository)
    service = create_service(
        session=session,
        library_repository=library_repository,
        episode_repository=episode_repository,
        progress_repository=progress_repository,
    )

    result = service.start(
        user_id=uuid4(),
        show_id=show_id,
    )

    assert result is None

    progress_repository.add.assert_not_called()
    session.commit.assert_not_called()
    watch_event_repository.add.assert_not_called()

    assert entry.status == LibraryStatus.PLANNING
    assert entry.started_at is None
