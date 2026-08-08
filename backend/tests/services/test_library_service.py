from types import SimpleNamespace
from unittest.mock import Mock
from uuid import UUID, uuid4

import pytest
from sqlalchemy.orm import Session

from app.models.enums import LibraryStatus
from app.models.library import LibraryEntry
from app.repositories.library import LibraryRepository
from app.repositories.show import ShowRepository
from app.services.library import LibraryService
from app.repositories.movie import MovieRepository

from app.models.show import Show
from app.models.user import User
from app.models.movie import Movie


@pytest.fixture
def library_repository() -> Mock:
    """Provide a mocked library repository."""

    return Mock(spec=LibraryRepository)


@pytest.fixture
def show_repository() -> Mock:
    """Provide a mocked show repository."""

    return Mock(spec=ShowRepository)


@pytest.fixture
def library_service(
    db_session: Session,
    library_repository: Mock,
    show_repository: Mock,
    movie_repository: Mock,
) -> LibraryService:
    """Provide a library service using mocked repositories."""

    return LibraryService(
        session=db_session,
        library_repository=library_repository,
        show_repository=show_repository,
        movie_repository=movie_repository,
    )

@pytest.fixture
def movie_repository() -> Mock:
    """Provide a mocked Movie repository."""

    return Mock(
        spec=MovieRepository,
    )

def make_show(
    *,
    show_id: UUID,
) -> SimpleNamespace:
    """Create a lightweight show object for service tests."""

    return SimpleNamespace(
        id=show_id,
    )


def persist_user(
    db_session: Session,
) -> User:
    """Persist a user for service tests."""

    user = User(
        display_name="Test User",
        is_local=False,
    )

    db_session.add(user)
    db_session.flush()

    return user


def persist_show(
    db_session: Session,
    *,
    tmdb_id: int = 95396,
    title: str = "Severance",
) -> Show:
    """Persist a TV series for service tests."""

    show = Show(
        tmdb_id=tmdb_id,
        title=title,
        original_title=title,
        original_language="en",
        metadata_language="en-US",
    )

    db_session.add(show)
    db_session.flush()

    return show


def make_entry(
    *,
    user_id: UUID,
    show_id: UUID,
    status: LibraryStatus = LibraryStatus.PLANNING,
) -> LibraryEntry:
    """Create a library entry for service tests."""

    return LibraryEntry(
        user_id=user_id,
        show_id=show_id,
        status=status,
    )

def make_movie(
    *,
    movie_id: UUID,
) -> SimpleNamespace:
    """Create a lightweight Movie object for service tests."""

    return SimpleNamespace(
        id=movie_id,
    )


def test_list_for_user_returns_repository_entries(
    library_service: LibraryService,
    library_repository: Mock,
) -> None:
    """Return the library entries provided by the repository."""

    user_id = uuid4()

    entries = [
        make_entry(
            user_id=user_id,
            show_id=uuid4(),
            status=LibraryStatus.WATCHING,
        ),
        make_entry(
            user_id=user_id,
            show_id=uuid4(),
            status=LibraryStatus.PLANNING,
        ),
    ]

    library_repository.list_by_user.return_value = entries

    result = library_service.list_for_user(
        user_id,
    )

    assert result is entries

    library_repository.list_by_user.assert_called_once_with(
        user_id,
        status=None,
    )


def test_list_for_user_forwards_status_filter(
    library_service: LibraryService,
    library_repository: Mock,
) -> None:
    """Forward the requested tracking status to the repository."""

    user_id = uuid4()

    library_repository.list_by_user.return_value = []

    result = library_service.list_for_user(
        user_id,
        status=LibraryStatus.WATCHING,
    )

    assert result == []

    library_repository.list_by_user.assert_called_once_with(
        user_id,
        status=LibraryStatus.WATCHING,
    )


def test_get_entry_returns_library_entry(
    library_service: LibraryService,
    library_repository: Mock,
) -> None:
    """Return a user's library entry for a TV series."""

    user_id = uuid4()
    show_id = uuid4()

    entry = make_entry(
        user_id=user_id,
        show_id=show_id,
    )

    library_repository.get_by_user_and_show.return_value = entry

    result = library_service.get_entry(
        user_id=user_id,
        show_id=show_id,
    )

    assert result is entry

    library_repository.get_by_user_and_show.assert_called_once_with(
        user_id=user_id,
        show_id=show_id,
    )


def test_get_entry_returns_none_when_missing(
    library_service: LibraryService,
    library_repository: Mock,
) -> None:
    """Return None when the show is not in the user's library."""

    user_id = uuid4()
    show_id = uuid4()

    library_repository.get_by_user_and_show.return_value = None

    result = library_service.get_entry(
        user_id=user_id,
        show_id=show_id,
    )

    assert result is None


def test_add_show_returns_none_when_show_does_not_exist(
    library_service: LibraryService,
    library_repository: Mock,
    show_repository: Mock,
) -> None:
    """Do not add a TV series that does not exist locally."""

    user_id = uuid4()
    show_id = uuid4()

    show_repository.get_by_id.return_value = None

    result = library_service.add_show(
        user_id=user_id,
        show_id=show_id,
    )

    assert result is None

    show_repository.get_by_id.assert_called_once_with(
        show_id,
    )
    library_repository.get_by_user_and_show.assert_not_called()
    library_repository.add.assert_not_called()


def test_add_show_returns_existing_entry_when_already_in_library(
    library_service: LibraryService,
    library_repository: Mock,
    show_repository: Mock,
) -> None:
    """Return the existing Show library entry instead of duplicating it."""

    user_id = uuid4()
    show_id = uuid4()

    show_repository.get_by_id.return_value = SimpleNamespace(
        id=show_id,
    )

    existing_entry = LibraryEntry(
        user_id=user_id,
        show_id=show_id,
        status=LibraryStatus.PLANNING,
    )

    library_repository.get_by_user_and_show.return_value = (
        existing_entry
    )

    result = library_service.add_show(
        user_id=user_id,
        show_id=show_id,
    )

    assert result is existing_entry

    library_repository.add.assert_not_called()


def test_add_show_creates_planning_entry_by_default(
    db_session: Session,
    library_service: LibraryService,
    library_repository: Mock,
    show_repository: Mock,
) -> None:
    """Create a planning entry when no status is specified."""

    user = persist_user(
        db_session,
    )

    show = persist_show(
        db_session,
    )

    show_repository.get_by_id.return_value = show
    library_repository.get_by_user_and_show.return_value = None

    def add_entry(entry: LibraryEntry) -> LibraryEntry:
        db_session.add(entry)
        return entry

    library_repository.add.side_effect = add_entry

    result = library_service.add_show(
        user_id=user.id,
        show_id=show.id,
    )

    assert result is not None
    assert result.user_id == user.id
    assert result.show_id == show.id
    assert result.status == LibraryStatus.PLANNING

    library_repository.add.assert_called_once_with(
        result,
    )


def test_add_show_uses_selected_status(
    db_session: Session,
    library_service: LibraryService,
    library_repository: Mock,
    show_repository: Mock,
) -> None:
    """Create an entry using the explicitly selected status."""

    user = persist_user(
        db_session,
    )

    show = persist_show(
        db_session,
    )

    show_repository.get_by_id.return_value = show
    library_repository.get_by_user_and_show.return_value = None

    def add_entry(entry: LibraryEntry) -> LibraryEntry:
        db_session.add(entry)
        return entry

    library_repository.add.side_effect = add_entry

    result = library_service.add_show(
        user_id=user.id,
        show_id=show.id,
        status=LibraryStatus.WATCHING,
    )

    assert result is not None
    assert result.user_id == user.id
    assert result.show_id == show.id
    assert result.status == LibraryStatus.WATCHING


def test_remove_show_returns_false_when_entry_does_not_exist(
    library_service: LibraryService,
    library_repository: Mock,
) -> None:
    """Return False when the TV series is not in the library."""

    user_id = uuid4()
    show_id = uuid4()

    library_repository.get_by_user_and_show.return_value = None

    result = library_service.remove_show(
        user_id=user_id,
        show_id=show_id,
    )

    assert result is False
    library_repository.delete.assert_not_called()


def test_remove_show_deletes_existing_entry(
    library_service: LibraryService,
    library_repository: Mock,
) -> None:
    """Remove an existing library entry."""

    user_id = uuid4()
    show_id = uuid4()

    entry = make_entry(
        user_id=user_id,
        show_id=show_id,
    )

    library_repository.get_by_user_and_show.return_value = entry

    result = library_service.remove_show(
        user_id=user_id,
        show_id=show_id,
    )

    assert result is True

    library_repository.delete.assert_called_once_with(
        entry,
    )


def test_update_status_returns_none_when_entry_does_not_exist(
    library_service: LibraryService,
    library_repository: Mock,
) -> None:
    """Return None when updating a missing library entry."""

    user_id = uuid4()
    show_id = uuid4()

    library_repository.get_by_user_and_show.return_value = None

    result = library_service.update_status(
        user_id=user_id,
        show_id=show_id,
        status=LibraryStatus.COMPLETED,
    )

    assert result is None


def test_update_status_updates_existing_entry(
    db_session: Session,
    library_service: LibraryService,
    library_repository: Mock,
) -> None:
    """Update the tracking status of an existing library entry."""

    user = persist_user(
        db_session,
    )

    show = persist_show(
        db_session,
    )

    entry = make_entry(
        user_id=user.id,
        show_id=show.id,
        status=LibraryStatus.PLANNING,
    )

    db_session.add(entry)
    db_session.flush()

    library_repository.get_by_user_and_show.return_value = entry

    result = library_service.update_status(
        user_id=user.id,
        show_id=show.id,
        status=LibraryStatus.WATCHING,
    )

    assert result is entry
    assert result.status == LibraryStatus.WATCHING

def test_get_movie_entry_returns_library_entry(
    library_service: LibraryService,
    library_repository: Mock,
) -> None:
    """Return a user's library entry for a movie."""

    user_id = uuid4()
    movie_id = uuid4()

    entry = LibraryEntry(
        user_id=user_id,
        movie_id=movie_id,
        status=LibraryStatus.PLANNING,
    )

    library_repository.get_by_user_and_movie.return_value = (
        entry
    )

    result = library_service.get_movie_entry(
        user_id=user_id,
        movie_id=movie_id,
    )

    assert result is entry

    library_repository.get_by_user_and_movie.assert_called_once_with(
        user_id=user_id,
        movie_id=movie_id,
    )


def test_add_movie_returns_none_when_movie_does_not_exist(
    library_service: LibraryService,
    library_repository: Mock,
    movie_repository: Mock,
) -> None:
    """Do not add a movie that does not exist locally."""

    user_id = uuid4()
    movie_id = uuid4()

    movie_repository.get_by_id.return_value = None

    result = library_service.add_movie(
        user_id=user_id,
        movie_id=movie_id,
    )

    assert result is None

    movie_repository.get_by_id.assert_called_once_with(
        movie_id,
    )

    library_repository.get_by_user_and_movie.assert_not_called()
    library_repository.add.assert_not_called()



def test_add_movie_returns_existing_entry_when_already_in_library(
    library_service: LibraryService,
    library_repository: Mock,
    movie_repository: Mock,
) -> None:
    """Return the existing Movie library entry instead of duplicating it."""

    user_id = uuid4()
    movie_id = uuid4()

    movie_repository.get_by_id.return_value = SimpleNamespace(
        id=movie_id,
    )

    existing_entry = LibraryEntry(
        user_id=user_id,
        movie_id=movie_id,
        status=LibraryStatus.PLANNING,
    )

    library_repository.get_by_user_and_movie.return_value = (
        existing_entry
    )

    result = library_service.add_movie(
        user_id=user_id,
        movie_id=movie_id,
    )

    assert result is existing_entry

    library_repository.add.assert_not_called()

def test_add_movie_creates_library_entry(
    db_session: Session,
    library_repository: Mock,
    show_repository: Mock,
    movie_repository: Mock,
) -> None:
    """Create a new library entry for a locally stored Movie."""

    user = User(
        display_name="Local User",
        is_local=True,
    )

    movie = Movie(
        tmdb_id=438631,
        title="Dune",
        original_title="Dune",
        original_language="en",
        runtime=155,
        status="Released",
        adult=False,
        video=False,
        popularity=10.0,
        vote_average=8.0,
        vote_count=100,
        metadata_language="en-US",
    )

    db_session.add_all(
        [
            user,
            movie,
        ]
    )
    db_session.commit()

    db_session.refresh(user)
    db_session.refresh(movie)

    movie_repository.get_by_id.return_value = movie
    library_repository.get_by_user_and_movie.return_value = None
    library_repository.add.side_effect = db_session.add

    service = LibraryService(
        session=db_session,
        library_repository=library_repository,
        show_repository=show_repository,
        movie_repository=movie_repository,
    )

    result = service.add_movie(
        user_id=user.id,
        movie_id=movie.id,
    )

    assert result is not None
    assert result.user_id == user.id
    assert result.show_id is None
    assert result.movie_id == movie.id
    assert result.status == LibraryStatus.PLANNING

    library_repository.add.assert_called_once_with(result)

def test_remove_movie_deletes_existing_entry(
    db_session: Session,
    library_repository: Mock,
    show_repository: Mock,
    movie_repository: Mock,
) -> None:
    """Remove a Movie library entry."""

    user_id = uuid4()
    movie_id = uuid4()

    entry = LibraryEntry(
        user_id=user_id,
        movie_id=movie_id,
        status=LibraryStatus.PLANNING,
    )

    library_repository.get_by_user_and_movie.return_value = entry

    service = LibraryService(
        session=db_session,
        library_repository=library_repository,
        show_repository=show_repository,
        movie_repository=movie_repository,
    )

    removed = service.remove_movie(
        user_id=user_id,
        movie_id=movie_id,
    )

    assert removed is True

    library_repository.delete.assert_called_once_with(
        entry
    )