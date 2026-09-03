from datetime import UTC, datetime
from types import SimpleNamespace
from unittest.mock import Mock
from uuid import uuid4

import pytest
from sqlalchemy.orm import Session

from app.models.enums import LibraryStatus
from app.repositories.episode import EpisodeRepository
from app.repositories.episode_progress import EpisodeProgressRepository
from app.repositories.library import LibraryRepository
from app.repositories.show import ShowRepository
from app.services.show_library_status import ShowLibraryStatusSynchronizer


@pytest.fixture
def session() -> Mock:
    """Provide a mocked database session."""

    return Mock(spec=Session)


@pytest.fixture
def library_repository() -> Mock:
    """Provide a mocked Library repository."""

    return Mock(spec=LibraryRepository)


@pytest.fixture
def show_repository() -> Mock:
    """Provide a mocked Show repository."""

    return Mock(spec=ShowRepository)


@pytest.fixture
def episode_repository() -> Mock:
    """Provide a mocked Episode repository."""

    return Mock(spec=EpisodeRepository)


@pytest.fixture
def progress_repository() -> Mock:
    """Provide a mocked Episode progress repository."""

    return Mock(spec=EpisodeProgressRepository)


@pytest.fixture
def synchronizer(
    session: Mock,
    library_repository: Mock,
    show_repository: Mock,
    episode_repository: Mock,
    progress_repository: Mock,
) -> ShowLibraryStatusSynchronizer:
    """Provide the Show Library status synchronizer."""

    return ShowLibraryStatusSynchronizer(
        session=session,
        library_repository=library_repository,
        show_repository=show_repository,
        episode_repository=episode_repository,
        progress_repository=progress_repository,
    )


def make_entry(
    *,
    status: LibraryStatus,
    started_at: datetime | None = None,
    completed_at: datetime | None = None,
) -> SimpleNamespace:
    """Create a lightweight Library entry for synchronization tests."""

    return SimpleNamespace(
        status=status,
        started_at=started_at,
        completed_at=completed_at,
    )


def make_show(
    *,
    status: str = "Returning Series",
    in_production: bool = True,
) -> SimpleNamespace:
    """Create a lightweight Show for synchronization tests."""

    return SimpleNamespace(
        status=status,
        in_production=in_production,
    )


def test_after_watch_moves_planning_show_to_watching(
    synchronizer: ShowLibraryStatusSynchronizer,
    session: Mock,
    library_repository: Mock,
    show_repository: Mock,
    episode_repository: Mock,
    progress_repository: Mock,
) -> None:
    """The first viewing must move a planned Show to Watching."""

    user_id = uuid4()
    show_id = uuid4()
    watched_at = datetime(2026, 8, 15, 21, 0, tzinfo=UTC)

    entry = make_entry(
        status=LibraryStatus.PLANNING,
    )

    library_repository.get_by_user_and_show.return_value = entry
    show_repository.get_by_id.return_value = make_show()
    progress_repository.count_watched_for_show.return_value = 1
    episode_repository.count_regular_by_show_id.return_value = 10

    synchronizer.after_watch(
        user_id=user_id,
        show_id=show_id,
        watched_at=watched_at,
    )

    assert entry.status == LibraryStatus.WATCHING
    assert entry.started_at == watched_at
    assert entry.completed_at is None

    session.flush.assert_called_once_with()


@pytest.mark.parametrize(
    "initial_status",
    [
        LibraryStatus.PAUSED,
        LibraryStatus.DROPPED,
    ],
)
def test_after_watch_resumes_manually_inactive_show(
    synchronizer: ShowLibraryStatusSynchronizer,
    library_repository: Mock,
    show_repository: Mock,
    episode_repository: Mock,
    progress_repository: Mock,
    initial_status: LibraryStatus,
) -> None:
    """Watching an Episode must resume a Paused or Dropped Show."""

    user_id = uuid4()
    show_id = uuid4()

    original_started_at = datetime(
        2026,
        7,
        1,
        20,
        0,
        tzinfo=UTC,
    )
    watched_at = datetime(
        2026,
        8,
        15,
        21,
        0,
        tzinfo=UTC,
    )

    entry = make_entry(
        status=initial_status,
        started_at=original_started_at,
    )

    library_repository.get_by_user_and_show.return_value = entry
    show_repository.get_by_id.return_value = make_show()
    progress_repository.count_watched_for_show.return_value = 4
    episode_repository.count_regular_by_show_id.return_value = 10

    synchronizer.after_watch(
        user_id=user_id,
        show_id=show_id,
        watched_at=watched_at,
    )

    assert entry.status == LibraryStatus.WATCHING
    assert entry.started_at == original_started_at
    assert entry.completed_at is None


def test_after_watch_keeps_caught_up_ongoing_show_watching(
    synchronizer: ShowLibraryStatusSynchronizer,
    library_repository: Mock,
    show_repository: Mock,
    episode_repository: Mock,
    progress_repository: Mock,
) -> None:
    """Watching every known Episode of an ongoing Show is not completion."""

    user_id = uuid4()
    show_id = uuid4()
    watched_at = datetime(2026, 8, 15, 21, 0, tzinfo=UTC)

    entry = make_entry(
        status=LibraryStatus.WATCHING,
        started_at=datetime(2026, 7, 1, 20, 0, tzinfo=UTC),
    )

    library_repository.get_by_user_and_show.return_value = entry
    show_repository.get_by_id.return_value = make_show(
        status="Returning Series",
        in_production=True,
    )

    progress_repository.count_watched_for_show.return_value = 8
    episode_repository.count_regular_by_show_id.return_value = 8

    synchronizer.after_watch(
        user_id=user_id,
        show_id=show_id,
        watched_at=watched_at,
    )

    assert entry.status == LibraryStatus.WATCHING
    assert entry.completed_at is None


@pytest.mark.parametrize(
    "provider_status",
    [
        "Ended",
        "Canceled",
        "Cancelled",
    ],
)
def test_after_watch_completes_terminal_show_when_all_regular_episodes_are_watched(
    synchronizer: ShowLibraryStatusSynchronizer,
    library_repository: Mock,
    show_repository: Mock,
    episode_repository: Mock,
    progress_repository: Mock,
    provider_status: str,
) -> None:
    """A terminal Show becomes Completed when all regular Episodes are watched."""

    user_id = uuid4()
    show_id = uuid4()
    watched_at = datetime(2026, 8, 15, 21, 0, tzinfo=UTC)

    entry = make_entry(
        status=LibraryStatus.WATCHING,
        started_at=datetime(2026, 7, 1, 20, 0, tzinfo=UTC),
    )

    library_repository.get_by_user_and_show.return_value = entry
    show_repository.get_by_id.return_value = make_show(
        status=provider_status,
        in_production=False,
    )

    progress_repository.count_watched_for_show.return_value = 10
    episode_repository.count_regular_by_show_id.return_value = 10

    synchronizer.after_watch(
        user_id=user_id,
        show_id=show_id,
        watched_at=watched_at,
    )

    assert entry.status == LibraryStatus.COMPLETED
    assert entry.completed_at == watched_at


def test_after_watch_does_not_complete_partially_watched_terminal_show(
    synchronizer: ShowLibraryStatusSynchronizer,
    library_repository: Mock,
    show_repository: Mock,
    episode_repository: Mock,
    progress_repository: Mock,
) -> None:
    """Provider completion alone must not mark the Library entry Completed."""

    user_id = uuid4()
    show_id = uuid4()
    watched_at = datetime(2026, 8, 15, 21, 0, tzinfo=UTC)

    entry = make_entry(
        status=LibraryStatus.WATCHING,
        started_at=datetime(2026, 7, 1, 20, 0, tzinfo=UTC),
    )

    library_repository.get_by_user_and_show.return_value = entry
    show_repository.get_by_id.return_value = make_show(
        status="Ended",
        in_production=False,
    )

    progress_repository.count_watched_for_show.return_value = 9
    episode_repository.count_regular_by_show_id.return_value = 10

    synchronizer.after_watch(
        user_id=user_id,
        show_id=show_id,
        watched_at=watched_at,
    )

    assert entry.status == LibraryStatus.WATCHING
    assert entry.completed_at is None


def test_after_watch_rewatch_preserves_original_completion_date(
    synchronizer: ShowLibraryStatusSynchronizer,
    library_repository: Mock,
    show_repository: Mock,
    episode_repository: Mock,
    progress_repository: Mock,
) -> None:
    """Rewatching a completed Show must preserve its original completion date."""

    user_id = uuid4()
    show_id = uuid4()

    original_started_at = datetime(
        2026,
        5,
        1,
        20,
        0,
        tzinfo=UTC,
    )
    original_completed_at = datetime(
        2026,
        6,
        1,
        22,
        0,
        tzinfo=UTC,
    )
    rewatched_at = datetime(
        2026,
        8,
        15,
        21,
        0,
        tzinfo=UTC,
    )

    entry = make_entry(
        status=LibraryStatus.COMPLETED,
        started_at=original_started_at,
        completed_at=original_completed_at,
    )

    library_repository.get_by_user_and_show.return_value = entry
    show_repository.get_by_id.return_value = make_show(
        status="Ended",
        in_production=False,
    )

    progress_repository.count_watched_for_show.return_value = 10
    episode_repository.count_regular_by_show_id.return_value = 10

    synchronizer.after_watch(
        user_id=user_id,
        show_id=show_id,
        watched_at=rewatched_at,
    )

    assert entry.status == LibraryStatus.COMPLETED
    assert entry.started_at == original_started_at
    assert entry.completed_at == original_completed_at


def test_after_unwatch_moves_completed_show_back_to_watching(
    synchronizer: ShowLibraryStatusSynchronizer,
    session: Mock,
    library_repository: Mock,
    progress_repository: Mock,
) -> None:
    """Removing completion progress must return a started Show to Watching."""

    user_id = uuid4()
    show_id = uuid4()

    started_at = datetime(
        2026,
        5,
        1,
        20,
        0,
        tzinfo=UTC,
    )

    entry = make_entry(
        status=LibraryStatus.COMPLETED,
        started_at=started_at,
        completed_at=datetime(
            2026,
            6,
            1,
            22,
            0,
            tzinfo=UTC,
        ),
    )

    library_repository.get_by_user_and_show.return_value = entry
    progress_repository.count_watched_for_show.return_value = 9

    synchronizer.after_unwatch(
        user_id=user_id,
        show_id=show_id,
    )

    assert entry.status == LibraryStatus.WATCHING
    assert entry.started_at == started_at
    assert entry.completed_at is None

    session.flush.assert_called_once_with()


@pytest.mark.parametrize(
    "manual_status",
    [
        LibraryStatus.PAUSED,
        LibraryStatus.DROPPED,
    ],
)
def test_after_unwatch_preserves_manual_show_status(
    synchronizer: ShowLibraryStatusSynchronizer,
    session: Mock,
    library_repository: Mock,
    progress_repository: Mock,
    manual_status: LibraryStatus,
) -> None:
    """Removing progress must not resume a manually inactive Show."""

    user_id = uuid4()
    show_id = uuid4()

    completed_at = None

    entry = make_entry(
        status=manual_status,
        started_at=datetime(
            2026,
            5,
            1,
            20,
            0,
            tzinfo=UTC,
        ),
        completed_at=completed_at,
    )

    library_repository.get_by_user_and_show.return_value = entry

    synchronizer.after_unwatch(
        user_id=user_id,
        show_id=show_id,
    )

    assert entry.status == manual_status
    assert entry.completed_at is completed_at

    session.flush.assert_not_called()
    progress_repository.count_watched_for_show.assert_not_called()


def test_after_unwatch_keeps_previously_started_show_watching_when_count_reaches_zero(
    synchronizer: ShowLibraryStatusSynchronizer,
    library_repository: Mock,
    progress_repository: Mock,
) -> None:
    """A previously started Show must not return to Planning."""

    user_id = uuid4()
    show_id = uuid4()

    started_at = datetime(
        2026,
        5,
        1,
        20,
        0,
        tzinfo=UTC,
    )

    entry = make_entry(
        status=LibraryStatus.WATCHING,
        started_at=started_at,
    )

    library_repository.get_by_user_and_show.return_value = entry
    progress_repository.count_watched_for_show.return_value = 0

    synchronizer.after_unwatch(
        user_id=user_id,
        show_id=show_id,
    )

    assert entry.status == LibraryStatus.WATCHING
    assert entry.started_at == started_at
    assert entry.completed_at is None


def test_after_unwatch_returns_never_started_show_to_planning(
    synchronizer: ShowLibraryStatusSynchronizer,
    library_repository: Mock,
    progress_repository: Mock,
) -> None:
    """A never-started Show with no progress belongs in Planning."""

    user_id = uuid4()
    show_id = uuid4()

    entry = make_entry(
        status=LibraryStatus.WATCHING,
        started_at=None,
    )

    library_repository.get_by_user_and_show.return_value = entry
    progress_repository.count_watched_for_show.return_value = 0

    synchronizer.after_unwatch(
        user_id=user_id,
        show_id=show_id,
    )

    assert entry.status == LibraryStatus.PLANNING
    assert entry.started_at is None
    assert entry.completed_at is None
