from datetime import UTC, datetime
from types import SimpleNamespace
from unittest.mock import Mock
from uuid import uuid4

import pytest
from sqlalchemy.orm import Session

from app.models.enums import LibraryStatus
from app.repositories.library import LibraryRepository
from app.repositories.movie import MovieRepository
from app.repositories.movie_watch_event import MovieWatchEventRepository
from app.services.movie_watch_event import MovieWatchEventService


@pytest.fixture
def session() -> Mock:
    """Provide a mocked database session."""

    return Mock(spec=Session)


@pytest.fixture
def movie_repository() -> Mock:
    """Provide a mocked Movie repository."""

    return Mock(spec=MovieRepository)


@pytest.fixture
def library_repository() -> Mock:
    """Provide a mocked Library repository."""

    return Mock(spec=LibraryRepository)


@pytest.fixture
def watch_event_repository() -> Mock:
    """Provide a mocked Movie watch event repository."""

    return Mock(spec=MovieWatchEventRepository)


@pytest.fixture
def service(
    session: Mock,
    movie_repository: Mock,
    library_repository: Mock,
    watch_event_repository: Mock,
) -> MovieWatchEventService:
    """Provide the Movie watch event service."""

    return MovieWatchEventService(
        session=session,
        movie_repository=movie_repository,
        library_repository=library_repository,
        watch_event_repository=watch_event_repository,
    )


def test_watch_returns_none_when_movie_does_not_exist(
    service: MovieWatchEventService,
    session: Mock,
    movie_repository: Mock,
    library_repository: Mock,
    watch_event_repository: Mock,
) -> None:
    """Do not create history for an unknown Movie."""

    user_id = uuid4()
    movie_id = uuid4()

    movie_repository.get_by_id.return_value = None

    result = service.watch(
        user_id=user_id,
        movie_id=movie_id,
    )

    assert result is None

    movie_repository.get_by_id.assert_called_once_with(
        movie_id,
    )

    library_repository.get_by_user_and_movie.assert_not_called()
    watch_event_repository.add.assert_not_called()

    session.commit.assert_not_called()


def test_watch_returns_none_when_movie_is_not_in_user_library(
    service: MovieWatchEventService,
    session: Mock,
    movie_repository: Mock,
    library_repository: Mock,
    watch_event_repository: Mock,
) -> None:
    """A locally stored Movie must belong to the user's Library."""

    user_id = uuid4()
    movie_id = uuid4()

    movie_repository.get_by_id.return_value = SimpleNamespace(
        id=movie_id,
    )

    library_repository.get_by_user_and_movie.return_value = None

    result = service.watch(
        user_id=user_id,
        movie_id=movie_id,
    )

    assert result is None

    library_repository.get_by_user_and_movie.assert_called_once_with(
        user_id=user_id,
        movie_id=movie_id,
    )

    watch_event_repository.add.assert_not_called()
    session.commit.assert_not_called()


def test_first_watch_records_event_and_marks_movie_completed(
    service: MovieWatchEventService,
    session: Mock,
    movie_repository: Mock,
    library_repository: Mock,
    watch_event_repository: Mock,
) -> None:
    """The first real viewing moves a planning Movie to Completed."""

    user_id = uuid4()
    movie_id = uuid4()

    watched_at = datetime(
        2026,
        8,
        14,
        21,
        30,
        tzinfo=UTC,
    )

    movie_repository.get_by_id.return_value = SimpleNamespace(
        id=movie_id,
    )

    entry = SimpleNamespace(
        user_id=user_id,
        movie_id=movie_id,
        status=LibraryStatus.PLANNING,
        completed_at=None,
    )

    library_repository.get_by_user_and_movie.return_value = entry

    result = service.watch(
        user_id=user_id,
        movie_id=movie_id,
        watched_at=watched_at,
    )

    assert result is not None

    assert result.user_id == user_id
    assert result.movie_id == movie_id
    assert result.watched_at == watched_at

    watch_event_repository.add.assert_called_once_with(
        result,
    )

    assert entry.status == LibraryStatus.COMPLETED
    assert entry.completed_at == watched_at

    session.commit.assert_called_once_with()
    session.refresh.assert_called_once_with(result)


def test_rewatch_creates_event_without_moving_original_completed_at(
    service: MovieWatchEventService,
    session: Mock,
    movie_repository: Mock,
    library_repository: Mock,
    watch_event_repository: Mock,
) -> None:
    """Rewatching a completed Movie preserves its original completion date."""

    user_id = uuid4()
    movie_id = uuid4()

    original_completed_at = datetime(
        2026,
        7,
        20,
        20,
        0,
        tzinfo=UTC,
    )

    rewatched_at = datetime(
        2026,
        8,
        14,
        21,
        30,
        tzinfo=UTC,
    )

    movie_repository.get_by_id.return_value = SimpleNamespace(
        id=movie_id,
    )

    entry = SimpleNamespace(
        user_id=user_id,
        movie_id=movie_id,
        status=LibraryStatus.COMPLETED,
        completed_at=original_completed_at,
    )

    library_repository.get_by_user_and_movie.return_value = entry

    result = service.watch(
        user_id=user_id,
        movie_id=movie_id,
        watched_at=rewatched_at,
    )

    assert result is not None
    assert result.watched_at == rewatched_at

    assert entry.status == LibraryStatus.COMPLETED
    assert entry.completed_at == original_completed_at

    watch_event_repository.add.assert_called_once_with(
        result,
    )

    session.commit.assert_called_once_with()


def test_watch_repairs_missing_completed_at(
    service: MovieWatchEventService,
    movie_repository: Mock,
    library_repository: Mock,
) -> None:
    """A completed Movie with missing completed_at is repaired by a real viewing."""

    user_id = uuid4()
    movie_id = uuid4()

    watched_at = datetime(
        2026,
        8,
        14,
        21,
        30,
        tzinfo=UTC,
    )

    movie_repository.get_by_id.return_value = SimpleNamespace(
        id=movie_id,
    )

    entry = SimpleNamespace(
        user_id=user_id,
        movie_id=movie_id,
        status=LibraryStatus.COMPLETED,
        completed_at=None,
    )

    library_repository.get_by_user_and_movie.return_value = entry

    result = service.watch(
        user_id=user_id,
        movie_id=movie_id,
        watched_at=watched_at,
    )

    assert result is not None

    assert entry.status == LibraryStatus.COMPLETED
    assert entry.completed_at == watched_at


def test_list_for_movie_returns_all_viewings(
    service: MovieWatchEventService,
    watch_event_repository: Mock,
) -> None:
    """Return every historical viewing for a Movie."""

    user_id = uuid4()
    movie_id = uuid4()

    first_event = SimpleNamespace(
        id=uuid4(),
    )

    second_event = SimpleNamespace(
        id=uuid4(),
    )

    watch_event_repository.list_by_user_and_movie.return_value = [
        first_event,
        second_event,
    ]

    result = service.list_for_movie(
        user_id=user_id,
        movie_id=movie_id,
    )

    assert result == [
        first_event,
        second_event,
    ]

    watch_event_repository.list_by_user_and_movie.assert_called_once_with(
        user_id=user_id,
        movie_id=movie_id,
    )


def test_delete_returns_false_when_event_does_not_exist(
    service: MovieWatchEventService,
    session: Mock,
    library_repository: Mock,
    watch_event_repository: Mock,
) -> None:
    """Do not mutate Library state for an unknown viewing event."""

    user_id = uuid4()
    movie_id = uuid4()
    event_id = uuid4()

    watch_event_repository.get_by_id_for_user_and_movie.return_value = None

    result = service.delete(
        user_id=user_id,
        movie_id=movie_id,
        event_id=event_id,
    )

    assert result is False

    watch_event_repository.delete.assert_not_called()

    library_repository.get_by_user_and_movie.assert_not_called()

    session.flush.assert_not_called()
    session.commit.assert_not_called()


def test_delete_viewing_keeps_movie_completed_when_history_remains(
    service: MovieWatchEventService,
    session: Mock,
    library_repository: Mock,
    watch_event_repository: Mock,
) -> None:
    """Deleting one viewing keeps the Movie completed when history remains."""

    user_id = uuid4()
    movie_id = uuid4()

    deleted_event = SimpleNamespace(
        id=uuid4(),
        watched_at=datetime(
            2026,
            8,
            14,
            21,
            30,
            tzinfo=UTC,
        ),
    )

    earliest_watched_at = datetime(
        2026,
        7,
        20,
        20,
        0,
        tzinfo=UTC,
    )

    remaining_event = SimpleNamespace(
        id=uuid4(),
        watched_at=earliest_watched_at,
    )

    entry = SimpleNamespace(
        status=LibraryStatus.COMPLETED,
        completed_at=datetime(
            2026,
            7,
            20,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    watch_event_repository.get_by_id_for_user_and_movie.return_value = deleted_event

    watch_event_repository.get_latest_for_user_and_movie.return_value = remaining_event

    watch_event_repository.get_earliest_for_user_and_movie.return_value = remaining_event

    library_repository.get_by_user_and_movie.return_value = entry

    result = service.delete(
        user_id=user_id,
        movie_id=movie_id,
        event_id=deleted_event.id,
    )

    assert result is True

    watch_event_repository.delete.assert_called_once_with(
        deleted_event,
    )

    session.flush.assert_called_once_with()

    assert entry.status == LibraryStatus.COMPLETED
    assert entry.completed_at == earliest_watched_at

    session.commit.assert_called_once_with()


def test_delete_original_viewing_moves_completed_at_to_oldest_remaining_event(
    service: MovieWatchEventService,
    library_repository: Mock,
    watch_event_repository: Mock,
) -> None:
    """Deleting the original viewing moves completed_at to remaining history."""

    user_id = uuid4()
    movie_id = uuid4()

    original_event = SimpleNamespace(
        id=uuid4(),
        watched_at=datetime(
            2026,
            7,
            1,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    remaining_oldest = SimpleNamespace(
        id=uuid4(),
        watched_at=datetime(
            2026,
            7,
            20,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    remaining_latest = SimpleNamespace(
        id=uuid4(),
        watched_at=datetime(
            2026,
            8,
            14,
            21,
            30,
            tzinfo=UTC,
        ),
    )

    entry = SimpleNamespace(
        status=LibraryStatus.COMPLETED,
        completed_at=original_event.watched_at,
    )

    watch_event_repository.get_by_id_for_user_and_movie.return_value = original_event

    watch_event_repository.get_latest_for_user_and_movie.return_value = remaining_latest

    watch_event_repository.get_earliest_for_user_and_movie.return_value = remaining_oldest

    library_repository.get_by_user_and_movie.return_value = entry

    result = service.delete(
        user_id=user_id,
        movie_id=movie_id,
        event_id=original_event.id,
    )

    assert result is True

    assert entry.status == LibraryStatus.COMPLETED
    assert entry.completed_at == remaining_oldest.watched_at


def test_delete_only_viewing_returns_movie_to_planning(
    service: MovieWatchEventService,
    session: Mock,
    library_repository: Mock,
    watch_event_repository: Mock,
) -> None:
    """Deleting the final viewing returns the Movie to the Watchlist."""

    user_id = uuid4()
    movie_id = uuid4()

    event = SimpleNamespace(
        id=uuid4(),
    )

    entry = SimpleNamespace(
        status=LibraryStatus.COMPLETED,
        completed_at=datetime(
            2026,
            8,
            14,
            21,
            30,
            tzinfo=UTC,
        ),
    )

    watch_event_repository.get_by_id_for_user_and_movie.return_value = event
    watch_event_repository.get_latest_for_user_and_movie.return_value = None

    library_repository.get_by_user_and_movie.return_value = entry

    result = service.delete(
        user_id=user_id,
        movie_id=movie_id,
        event_id=event.id,
    )

    assert result is True

    assert entry.status == LibraryStatus.PLANNING
    assert entry.completed_at is None

    watch_event_repository.get_earliest_for_user_and_movie.assert_not_called()

    session.commit.assert_called_once_with()


def test_delete_succeeds_when_library_entry_is_missing(
    service: MovieWatchEventService,
    session: Mock,
    library_repository: Mock,
    watch_event_repository: Mock,
) -> None:
    """Historical cleanup still succeeds when the Library entry is gone."""

    user_id = uuid4()
    movie_id = uuid4()

    event = SimpleNamespace(
        id=uuid4(),
    )

    watch_event_repository.get_by_id_for_user_and_movie.return_value = event
    watch_event_repository.get_latest_for_user_and_movie.return_value = None

    library_repository.get_by_user_and_movie.return_value = None

    result = service.delete(
        user_id=user_id,
        movie_id=movie_id,
        event_id=event.id,
    )

    assert result is True

    watch_event_repository.delete.assert_called_once_with(
        event,
    )

    session.flush.assert_called_once_with()
    session.commit.assert_called_once_with()


def test_delete_all_removes_history_and_returns_movie_to_planning(
    service: MovieWatchEventService,
    session: Mock,
    library_repository: Mock,
    watch_event_repository: Mock,
) -> None:
    """Deleting all viewings clears Movie watched state."""

    user_id = uuid4()
    movie_id = uuid4()

    entry = SimpleNamespace(
        status=LibraryStatus.COMPLETED,
        completed_at=datetime(
            2026,
            8,
            14,
            21,
            30,
            tzinfo=UTC,
        ),
    )

    watch_event_repository.delete_all_for_user_and_movie.return_value = 3

    library_repository.get_by_user_and_movie.return_value = entry

    deleted_count = service.delete_all(
        user_id=user_id,
        movie_id=movie_id,
    )

    assert deleted_count == 3

    watch_event_repository.delete_all_for_user_and_movie.assert_called_once_with(
        user_id=user_id,
        movie_id=movie_id,
    )

    assert entry.status == LibraryStatus.PLANNING
    assert entry.completed_at is None

    session.commit.assert_called_once_with()


def test_delete_all_is_idempotent_when_history_is_already_empty(
    service: MovieWatchEventService,
    session: Mock,
    library_repository: Mock,
    watch_event_repository: Mock,
) -> None:
    """Repeated delete-all calls keep Movie state consistent."""

    user_id = uuid4()
    movie_id = uuid4()

    entry = SimpleNamespace(
        status=LibraryStatus.PLANNING,
        completed_at=None,
    )

    watch_event_repository.delete_all_for_user_and_movie.return_value = 0

    library_repository.get_by_user_and_movie.return_value = entry

    deleted_count = service.delete_all(
        user_id=user_id,
        movie_id=movie_id,
    )

    assert deleted_count == 0

    assert entry.status == LibraryStatus.PLANNING
    assert entry.completed_at is None

    session.commit.assert_called_once_with()


def test_delete_all_succeeds_without_library_entry(
    service: MovieWatchEventService,
    session: Mock,
    library_repository: Mock,
    watch_event_repository: Mock,
) -> None:
    """Historical cleanup must not depend on the current Library entry."""

    user_id = uuid4()
    movie_id = uuid4()

    watch_event_repository.delete_all_for_user_and_movie.return_value = 2
    library_repository.get_by_user_and_movie.return_value = None

    deleted_count = service.delete_all(
        user_id=user_id,
        movie_id=movie_id,
    )

    assert deleted_count == 2

    session.commit.assert_called_once_with()
