from datetime import UTC, datetime
from types import SimpleNamespace
from unittest.mock import Mock
from uuid import uuid4

import pytest
from sqlalchemy.orm import Session

from app.repositories.episode import EpisodeRepository
from app.repositories.episode_progress import EpisodeProgressRepository
from app.repositories.episode_watch_event import EpisodeWatchEventRepository
from app.repositories.season import SeasonRepository
from app.services.episode_watch_event import EpisodeWatchEventService
from app.services.show_library_status import ShowLibraryStatusSynchronizer


@pytest.fixture
def session() -> Mock:
    """Provide a mocked database session."""

    return Mock(spec=Session)


@pytest.fixture
def watch_event_repository() -> Mock:
    """Provide a mocked Episode watch event repository."""

    return Mock(
        spec=EpisodeWatchEventRepository,
    )


@pytest.fixture
def progress_repository() -> Mock:
    """Provide a mocked Episode progress repository."""

    return Mock(
        spec=EpisodeProgressRepository,
    )


@pytest.fixture
def service(
    session: Mock,
    watch_event_repository: Mock,
    progress_repository: Mock,
    episode_repository: Mock,
    season_repository: Mock,
    show_status_synchronizer: Mock,
) -> EpisodeWatchEventService:
    """Provide the Episode watch event service."""

    return EpisodeWatchEventService(
        session=session,
        watch_event_repository=watch_event_repository,
        progress_repository=progress_repository,
        episode_repository=episode_repository,
        season_repository=season_repository,
        show_status_synchronizer=show_status_synchronizer,
    )


@pytest.fixture
def show_status_synchronizer() -> Mock:
    """Provide a mocked Show Library status synchronizer."""

    return Mock(spec=ShowLibraryStatusSynchronizer)


@pytest.fixture
def episode_repository() -> Mock:
    """Provide a mocked Episode repository."""

    repository = Mock(spec=EpisodeRepository)
    repository.get_by_id.return_value = SimpleNamespace(
        season_id=uuid4(),
    )
    return repository


@pytest.fixture
def season_repository() -> Mock:
    """Provide a mocked Season repository."""

    repository = Mock(spec=SeasonRepository)
    repository.get_by_id.return_value = SimpleNamespace(
        show_id=uuid4(),
    )
    return repository


def test_list_for_episode_returns_all_watch_events(
    service: EpisodeWatchEventService,
    watch_event_repository: Mock,
) -> None:
    """Return every historical viewing event for an Episode."""

    user_id = uuid4()
    episode_id = uuid4()

    first_event = SimpleNamespace(
        id=uuid4(),
        user_id=user_id,
        episode_id=episode_id,
        watched_at=datetime(
            2026,
            8,
            14,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    second_event = SimpleNamespace(
        id=uuid4(),
        user_id=user_id,
        episode_id=episode_id,
        watched_at=datetime(
            2026,
            7,
            20,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    watch_event_repository.list_by_user_and_episode.return_value = [
        first_event,
        second_event,
    ]

    result = service.list_for_episode(
        user_id=user_id,
        episode_id=episode_id,
    )

    assert result == [
        first_event,
        second_event,
    ]

    watch_event_repository.list_by_user_and_episode.assert_called_once_with(
        user_id=user_id,
        episode_id=episode_id,
    )


def test_delete_returns_false_when_event_does_not_exist(
    service: EpisodeWatchEventService,
    session: Mock,
    watch_event_repository: Mock,
    progress_repository: Mock,
) -> None:
    """Do not change progress when the requested watch event does not exist."""

    user_id = uuid4()
    episode_id = uuid4()
    event_id = uuid4()

    watch_event_repository.get_by_id_for_user_and_episode.return_value = None

    result = service.delete(
        user_id=user_id,
        episode_id=episode_id,
        event_id=event_id,
    )

    assert result is False

    watch_event_repository.get_by_id_for_user_and_episode.assert_called_once_with(
        event_id=event_id,
        user_id=user_id,
        episode_id=episode_id,
    )

    watch_event_repository.delete.assert_not_called()
    watch_event_repository.get_latest_for_user_and_episode.assert_not_called()

    progress_repository.get_by_user_and_episode.assert_not_called()

    session.flush.assert_not_called()
    session.commit.assert_not_called()


def test_delete_returns_false_when_event_belongs_to_another_episode(
    service: EpisodeWatchEventService,
    session: Mock,
    watch_event_repository: Mock,
    progress_repository: Mock,
) -> None:
    """Reject a watch event that does not belong to the requested Episode."""

    user_id = uuid4()
    requested_episode_id = uuid4()
    event_id = uuid4()

    watch_event_repository.get_by_id_for_user_and_episode.return_value = None

    result = service.delete(
        user_id=user_id,
        episode_id=requested_episode_id,
        event_id=event_id,
    )

    assert result is False

    watch_event_repository.get_by_id_for_user_and_episode.assert_called_once_with(
        event_id=event_id,
        user_id=user_id,
        episode_id=requested_episode_id,
    )

    watch_event_repository.delete.assert_not_called()
    progress_repository.get_by_user_and_episode.assert_not_called()

    session.flush.assert_not_called()
    session.commit.assert_not_called()


def test_delete_intermediate_event_keeps_latest_progress(
    service: EpisodeWatchEventService,
    session: Mock,
    watch_event_repository: Mock,
    progress_repository: Mock,
) -> None:
    """Deleting an older event must preserve the latest viewing date."""

    user_id = uuid4()
    episode_id = uuid4()

    deleted_event = SimpleNamespace(
        id=uuid4(),
        user_id=user_id,
        episode_id=episode_id,
        watched_at=datetime(
            2026,
            7,
            20,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    latest_watched_at = datetime(
        2026,
        8,
        14,
        21,
        30,
        tzinfo=UTC,
    )

    latest_event = SimpleNamespace(
        id=uuid4(),
        user_id=user_id,
        episode_id=episode_id,
        watched_at=latest_watched_at,
    )

    progress = SimpleNamespace(
        user_id=user_id,
        episode_id=episode_id,
        is_watched=True,
        watched_at=latest_watched_at,
    )

    watch_event_repository.get_by_id_for_user_and_episode.return_value = deleted_event

    watch_event_repository.get_latest_for_user_and_episode.return_value = latest_event

    progress_repository.get_by_user_and_episode.return_value = progress

    result = service.delete(
        user_id=user_id,
        episode_id=episode_id,
        event_id=deleted_event.id,
    )

    assert result is True

    watch_event_repository.delete.assert_called_once_with(
        deleted_event,
    )

    session.flush.assert_called_once_with()

    watch_event_repository.get_latest_for_user_and_episode.assert_called_once_with(
        user_id=user_id,
        episode_id=episode_id,
    )

    progress_repository.get_by_user_and_episode.assert_called_once_with(
        user_id=user_id,
        episode_id=episode_id,
    )

    assert progress.is_watched is True
    assert progress.watched_at == latest_watched_at

    session.commit.assert_called_once_with()


def test_delete_latest_event_moves_progress_to_previous_watch(
    service: EpisodeWatchEventService,
    session: Mock,
    watch_event_repository: Mock,
    progress_repository: Mock,
) -> None:
    """Deleting the latest viewing must move progress to the previous event."""

    user_id = uuid4()
    episode_id = uuid4()

    latest_event = SimpleNamespace(
        id=uuid4(),
        user_id=user_id,
        episode_id=episode_id,
        watched_at=datetime(
            2026,
            8,
            14,
            21,
            30,
            tzinfo=UTC,
        ),
    )

    previous_watched_at = datetime(
        2026,
        7,
        20,
        20,
        15,
        tzinfo=UTC,
    )

    previous_event = SimpleNamespace(
        id=uuid4(),
        user_id=user_id,
        episode_id=episode_id,
        watched_at=previous_watched_at,
    )

    progress = SimpleNamespace(
        user_id=user_id,
        episode_id=episode_id,
        is_watched=True,
        watched_at=latest_event.watched_at,
    )

    watch_event_repository.get_by_id_for_user_and_episode.return_value = latest_event

    watch_event_repository.get_latest_for_user_and_episode.return_value = previous_event

    progress_repository.get_by_user_and_episode.return_value = progress

    result = service.delete(
        user_id=user_id,
        episode_id=episode_id,
        event_id=latest_event.id,
    )

    assert result is True

    watch_event_repository.delete.assert_called_once_with(
        latest_event,
    )

    session.flush.assert_called_once_with()

    assert progress.is_watched is True
    assert progress.watched_at == previous_watched_at

    session.commit.assert_called_once_with()


def test_delete_only_event_marks_episode_as_unwatched(
    service: EpisodeWatchEventService,
    session: Mock,
    watch_event_repository: Mock,
    progress_repository: Mock,
) -> None:
    """Deleting the only watch event must clear the current watched state."""

    user_id = uuid4()
    episode_id = uuid4()

    event = SimpleNamespace(
        id=uuid4(),
        user_id=user_id,
        episode_id=episode_id,
        watched_at=datetime(
            2026,
            8,
            14,
            21,
            30,
            tzinfo=UTC,
        ),
    )

    progress = SimpleNamespace(
        user_id=user_id,
        episode_id=episode_id,
        is_watched=True,
        watched_at=event.watched_at,
    )

    watch_event_repository.get_by_id_for_user_and_episode.return_value = event
    watch_event_repository.get_latest_for_user_and_episode.return_value = None

    progress_repository.get_by_user_and_episode.return_value = progress

    result = service.delete(
        user_id=user_id,
        episode_id=episode_id,
        event_id=event.id,
    )

    assert result is True

    watch_event_repository.delete.assert_called_once_with(
        event,
    )

    session.flush.assert_called_once_with()

    assert progress.is_watched is False
    assert progress.watched_at is None

    session.commit.assert_called_once_with()


def test_delete_event_succeeds_when_progress_entry_is_missing(
    service: EpisodeWatchEventService,
    session: Mock,
    watch_event_repository: Mock,
    progress_repository: Mock,
) -> None:
    """Historical cleanup must still succeed when current progress is missing."""

    user_id = uuid4()
    episode_id = uuid4()

    event = SimpleNamespace(
        id=uuid4(),
        user_id=user_id,
        episode_id=episode_id,
        watched_at=datetime(
            2026,
            8,
            14,
            21,
            30,
            tzinfo=UTC,
        ),
    )

    watch_event_repository.get_by_id_for_user_and_episode.return_value = event

    watch_event_repository.get_latest_for_user_and_episode.return_value = None

    progress_repository.get_by_user_and_episode.return_value = None

    result = service.delete(
        user_id=user_id,
        episode_id=episode_id,
        event_id=event.id,
    )

    assert result is True

    watch_event_repository.delete.assert_called_once_with(
        event,
    )

    session.flush.assert_called_once_with()

    progress_repository.get_by_user_and_episode.assert_called_once_with(
        user_id=user_id,
        episode_id=episode_id,
    )

    session.commit.assert_called_once_with()


def test_delete_all_removes_every_viewing_and_clears_progress(
    service: EpisodeWatchEventService,
    session: Mock,
    watch_event_repository: Mock,
    progress_repository: Mock,
) -> None:
    """Removing all viewings must leave the Episode completely unwatched."""

    user_id = uuid4()
    episode_id = uuid4()

    progress = SimpleNamespace(
        user_id=user_id,
        episode_id=episode_id,
        is_watched=True,
        watched_at=datetime(
            2026,
            8,
            14,
            21,
            30,
            tzinfo=UTC,
        ),
    )

    watch_event_repository.delete_all_for_user_and_episode.return_value = 3

    progress_repository.get_by_user_and_episode.return_value = progress

    deleted_count = service.delete_all(
        user_id=user_id,
        episode_id=episode_id,
    )

    assert deleted_count == 3

    watch_event_repository.delete_all_for_user_and_episode.assert_called_once_with(
        user_id=user_id,
        episode_id=episode_id,
    )

    progress_repository.get_by_user_and_episode.assert_called_once_with(
        user_id=user_id,
        episode_id=episode_id,
    )

    assert progress.is_watched is False
    assert progress.watched_at is None

    session.commit.assert_called_once_with()


def test_delete_all_is_idempotent_when_no_viewings_remain(
    service: EpisodeWatchEventService,
    session: Mock,
    watch_event_repository: Mock,
    progress_repository: Mock,
) -> None:
    """Deleting all viewings twice must still leave consistent progress."""

    user_id = uuid4()
    episode_id = uuid4()

    progress = SimpleNamespace(
        user_id=user_id,
        episode_id=episode_id,
        is_watched=False,
        watched_at=None,
    )

    watch_event_repository.delete_all_for_user_and_episode.return_value = 0
    progress_repository.get_by_user_and_episode.return_value = progress

    deleted_count = service.delete_all(
        user_id=user_id,
        episode_id=episode_id,
    )

    assert deleted_count == 0

    assert progress.is_watched is False
    assert progress.watched_at is None

    session.commit.assert_called_once_with()


def test_delete_all_succeeds_when_progress_entry_is_missing(
    service: EpisodeWatchEventService,
    session: Mock,
    watch_event_repository: Mock,
    progress_repository: Mock,
) -> None:
    """Historical cleanup must succeed even without current progress."""

    user_id = uuid4()
    episode_id = uuid4()

    watch_event_repository.delete_all_for_user_and_episode.return_value = 2
    progress_repository.get_by_user_and_episode.return_value = None

    deleted_count = service.delete_all(
        user_id=user_id,
        episode_id=episode_id,
    )

    assert deleted_count == 2

    watch_event_repository.delete_all_for_user_and_episode.assert_called_once_with(
        user_id=user_id,
        episode_id=episode_id,
    )

    progress_repository.get_by_user_and_episode.assert_called_once_with(
        user_id=user_id,
        episode_id=episode_id,
    )

    session.commit.assert_called_once_with()


def test_delete_last_watch_event_synchronizes_show_status(
    service: EpisodeWatchEventService,
    watch_event_repository: Mock,
    progress_repository: Mock,
    episode_repository: Mock,
    season_repository: Mock,
    show_status_synchronizer: Mock,
) -> None:
    """Deleting the last viewing must synchronize the Show Library status."""

    user_id = uuid4()
    episode_id = uuid4()
    season_id = uuid4()
    show_id = uuid4()

    event = SimpleNamespace(
        id=uuid4(),
        user_id=user_id,
        episode_id=episode_id,
        watched_at=datetime(
            2026,
            8,
            14,
            21,
            30,
            tzinfo=UTC,
        ),
    )

    progress = SimpleNamespace(
        user_id=user_id,
        episode_id=episode_id,
        is_watched=True,
        watched_at=event.watched_at,
    )

    episode_repository.get_by_id.return_value = SimpleNamespace(
        id=episode_id,
        season_id=season_id,
    )
    season_repository.get_by_id.return_value = SimpleNamespace(
        id=season_id,
        show_id=show_id,
    )

    watch_event_repository.get_by_id_for_user_and_episode.return_value = event
    watch_event_repository.get_latest_for_user_and_episode.return_value = None
    progress_repository.get_by_user_and_episode.return_value = progress

    result = service.delete(
        user_id=user_id,
        episode_id=episode_id,
        event_id=event.id,
    )

    assert result is True

    show_status_synchronizer.after_unwatch.assert_called_once_with(
        user_id=user_id,
        show_id=show_id,
    )


def test_delete_watch_event_does_not_synchronize_show_when_history_remains(
    service: EpisodeWatchEventService,
    watch_event_repository: Mock,
    progress_repository: Mock,
    episode_repository: Mock,
    season_repository: Mock,
    show_status_synchronizer: Mock,
) -> None:
    """Deleting one viewing must not unwatch the Show when history remains."""

    user_id = uuid4()
    episode_id = uuid4()
    season_id = uuid4()
    show_id = uuid4()

    deleted_event = SimpleNamespace(
        id=uuid4(),
        user_id=user_id,
        episode_id=episode_id,
        watched_at=datetime(
            2026,
            8,
            14,
            21,
            30,
            tzinfo=UTC,
        ),
    )

    remaining_event = SimpleNamespace(
        id=uuid4(),
        user_id=user_id,
        episode_id=episode_id,
        watched_at=datetime(
            2026,
            7,
            20,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    progress = SimpleNamespace(
        user_id=user_id,
        episode_id=episode_id,
        is_watched=True,
        watched_at=deleted_event.watched_at,
    )

    episode_repository.get_by_id.return_value = SimpleNamespace(
        id=episode_id,
        season_id=season_id,
    )
    season_repository.get_by_id.return_value = SimpleNamespace(
        id=season_id,
        show_id=show_id,
    )

    watch_event_repository.get_by_id_for_user_and_episode.return_value = deleted_event
    watch_event_repository.get_latest_for_user_and_episode.return_value = remaining_event
    progress_repository.get_by_user_and_episode.return_value = progress

    result = service.delete(
        user_id=user_id,
        episode_id=episode_id,
        event_id=deleted_event.id,
    )

    assert result is True
    assert progress.is_watched is True
    assert progress.watched_at == remaining_event.watched_at

    show_status_synchronizer.after_unwatch.assert_not_called()


def test_delete_all_synchronizes_show_status(
    service: EpisodeWatchEventService,
    watch_event_repository: Mock,
    progress_repository: Mock,
    episode_repository: Mock,
    season_repository: Mock,
    show_status_synchronizer: Mock,
) -> None:
    """Deleting all viewings must synchronize the Show Library status."""

    user_id = uuid4()
    episode_id = uuid4()
    season_id = uuid4()
    show_id = uuid4()

    progress = SimpleNamespace(
        user_id=user_id,
        episode_id=episode_id,
        is_watched=True,
        watched_at=datetime(
            2026,
            8,
            14,
            21,
            30,
            tzinfo=UTC,
        ),
    )

    episode_repository.get_by_id.return_value = SimpleNamespace(
        id=episode_id,
        season_id=season_id,
    )
    season_repository.get_by_id.return_value = SimpleNamespace(
        id=season_id,
        show_id=show_id,
    )

    watch_event_repository.delete_all_for_user_and_episode.return_value = 2
    progress_repository.get_by_user_and_episode.return_value = progress

    result = service.delete_all(
        user_id=user_id,
        episode_id=episode_id,
    )

    assert result == 2
    assert progress.is_watched is False
    assert progress.watched_at is None

    show_status_synchronizer.after_unwatch.assert_called_once_with(
        user_id=user_id,
        show_id=show_id,
    )


def test_delete_last_watch_event_synchronizes_show_when_progress_is_missing(
    service: EpisodeWatchEventService,
    watch_event_repository: Mock,
    progress_repository: Mock,
    episode_repository: Mock,
    season_repository: Mock,
    show_status_synchronizer: Mock,
) -> None:
    """Deleting the last viewing must synchronize even without progress."""

    user_id = uuid4()
    episode_id = uuid4()
    season_id = uuid4()
    show_id = uuid4()

    event = SimpleNamespace(
        id=uuid4(),
        user_id=user_id,
        episode_id=episode_id,
        watched_at=datetime(
            2026,
            8,
            14,
            21,
            30,
            tzinfo=UTC,
        ),
    )

    episode_repository.get_by_id.return_value = SimpleNamespace(
        id=episode_id,
        season_id=season_id,
    )
    season_repository.get_by_id.return_value = SimpleNamespace(
        id=season_id,
        show_id=show_id,
    )

    watch_event_repository.get_by_id_for_user_and_episode.return_value = event
    watch_event_repository.get_latest_for_user_and_episode.return_value = None
    progress_repository.get_by_user_and_episode.return_value = None

    result = service.delete(
        user_id=user_id,
        episode_id=episode_id,
        event_id=event.id,
    )

    assert result is True

    show_status_synchronizer.after_unwatch.assert_called_once_with(
        user_id=user_id,
        show_id=show_id,
    )
