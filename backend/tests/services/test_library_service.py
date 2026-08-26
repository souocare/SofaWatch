from types import SimpleNamespace
from unittest.mock import ANY, Mock
from uuid import UUID, uuid4
from datetime import UTC, datetime

import pytest
from app.repositories.episode_progress import EpisodeProgressRepository
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

from app.repositories.episode import EpisodeRepository

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
    episode_repository: Mock,
    episode_progress_repository: Mock,
) -> LibraryService:
    """Provide a library service using mocked repositories."""

    episode_repository.get_aired_counts_by_show_ids.return_value = {}
    episode_progress_repository.get_watched_aired_counts_by_show_ids.return_value = {}

    return LibraryService(
        session=db_session,
        library_repository=library_repository,
        show_repository=show_repository,
        movie_repository=movie_repository,
        episode_repository=episode_repository,
        episode_progress_repository=episode_progress_repository,
    )

@pytest.fixture
def movie_repository() -> Mock:
    """Provide a mocked Movie repository."""

    return Mock(
        spec=MovieRepository,
    )

@pytest.fixture
def episode_repository() -> Mock:
    """Provide a mocked Episode repository."""

    return Mock(spec=EpisodeRepository)

@pytest.fixture
def episode_progress_repository() -> Mock:
    """Provide a mocked Episode progress repository."""

    return Mock(spec=EpisodeProgressRepository)

def make_show(
    *,
    show_id: UUID,
    tmdb_id: int = 95396,
    title: str = "Severance",
) -> SimpleNamespace:
    """Create Show-like data required by LibraryService responses."""

    return SimpleNamespace(
        id=show_id,
        tmdb_id=tmdb_id,
        title=title,
        original_title=title,
        status="Returning Series",
        vote_average=8.4,
    )


def persist_user(
    db_session: Session,
) -> User:
    """Persist a user for service tests."""

    user = User(
        display_name="Test User",
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
    episode_repository: Mock,
    episode_progress_repository: Mock,
) -> None:
    """Create a new library entry for a locally stored Movie."""

    user = User(
        display_name="Local User",
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
        episode_repository=episode_repository,
        episode_progress_repository=episode_progress_repository,
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
    episode_repository: Mock,
    episode_progress_repository: Mock,
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
        episode_repository=episode_repository,
        episode_progress_repository=episode_progress_repository,
    )

    removed = service.remove_movie(
        user_id=user_id,
        movie_id=movie_id,
    )

    assert removed is True

    library_repository.delete.assert_called_once_with(
        entry
    )

def test_update_movie_status_returns_none_when_entry_does_not_exist(
    library_service: LibraryService,
    library_repository: Mock,
) -> None:
    """Return None when the Movie is not in the user's library."""

    user_id = uuid4()
    movie_id = uuid4()

    library_repository.get_by_user_and_movie.return_value = None

    result = library_service.update_movie_status(
        user_id=user_id,
        movie_id=movie_id,
        status=LibraryStatus.COMPLETED,
    )

    assert result is None

    library_repository.get_by_user_and_movie.assert_called_once_with(
        user_id=user_id,
        movie_id=movie_id,
    )

def test_update_movie_status_to_completed_sets_completed_at(
    db_session: Session,
    library_repository: Mock,
    show_repository: Mock,
    movie_repository: Mock,
    episode_repository: Mock,
    episode_progress_repository: Mock,
) -> None:
    """Mark a Movie as completed and store when it was watched."""

    user = User(
        display_name="Local User",
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

    entry = LibraryEntry(
        user=user,
        movie=movie,
        status=LibraryStatus.PLANNING,
    )

    db_session.add_all(
        [
            user,
            movie,
            entry,
        ]
    )
    db_session.commit()

    db_session.refresh(user)
    db_session.refresh(movie)
    db_session.refresh(entry)

    library_repository.get_by_user_and_movie.return_value = entry

    service = LibraryService(
        session=db_session,
        library_repository=library_repository,
        show_repository=show_repository,
        movie_repository=movie_repository,
        episode_repository=episode_repository,
        episode_progress_repository=episode_progress_repository,
    )

    result = service.update_movie_status(
        user_id=user.id,
        movie_id=movie.id,
        status=LibraryStatus.COMPLETED,
    )

    assert result is entry
    assert result.status == LibraryStatus.COMPLETED
    assert result.completed_at is not None

def test_update_movie_status_to_planning_clears_completed_at(
    db_session: Session,
    library_repository: Mock,
    show_repository: Mock,
    movie_repository: Mock,
    episode_repository: Mock,
    episode_progress_repository: Mock,
) -> None:
    """Mark a completed Movie as not watched and clear completed_at."""

    user = User(
        display_name="Local User",
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

    entry = LibraryEntry(
        user=user,
        movie=movie,
        status=LibraryStatus.COMPLETED,
        completed_at=datetime.now(UTC),
    )

    db_session.add_all(
        [
            user,
            movie,
            entry,
        ]
    )
    db_session.commit()

    db_session.refresh(entry)

    assert entry.completed_at is not None

    library_repository.get_by_user_and_movie.return_value = entry

    service = LibraryService(
        session=db_session,
        library_repository=library_repository,
        show_repository=show_repository,
        movie_repository=movie_repository,
        episode_repository=episode_repository,
        episode_progress_repository=episode_progress_repository,
    )

    result = service.update_movie_status(
        user_id=user.id,
        movie_id=movie.id,
        status=LibraryStatus.PLANNING,
    )

    assert result is entry
    assert result.status == LibraryStatus.PLANNING
    assert result.completed_at is None

def test_update_movie_status_keeps_existing_completed_at(
    db_session: Session,
    library_repository: Mock,
    show_repository: Mock,
    movie_repository: Mock,
    episode_repository: Mock,
    episode_progress_repository: Mock,
) -> None:
    """Preserve the original completion date when Movie is already completed."""

    user = User(
        display_name="Local User",
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

    original_completed_at = datetime(2026, 8, 1, 20, 30, tzinfo=UTC)

    entry = LibraryEntry(
        user=user,
        movie=movie,
        status=LibraryStatus.COMPLETED,
        completed_at=original_completed_at,
    )

    db_session.add_all(
        [
            user,
            movie,
            entry,
        ]
    )
    db_session.commit()

    db_session.refresh(entry)

    library_repository.get_by_user_and_movie.return_value = entry

    service = LibraryService(
        session=db_session,
        library_repository=library_repository,
        show_repository=show_repository,
        movie_repository=movie_repository,
        episode_repository=episode_repository,
        episode_progress_repository=episode_progress_repository,
    )

    result = service.update_movie_status(
        user_id=user.id,
        movie_id=movie.id,
        status=LibraryStatus.COMPLETED,
    )

    assert result is entry
    assert result.status == LibraryStatus.COMPLETED
    assert result.completed_at is not None

    assert result.completed_at == original_completed_at.replace(tzinfo=None)

def test_list_shows_for_user_includes_first_available_episode_for_planning_show(
    library_service: LibraryService,
    library_repository: Mock,
    episode_repository: Mock,
) -> None:
    """Expose the first aired regular Episode for a Planning Show."""

    user_id = uuid4()
    show_id = uuid4()
    episode_id = uuid4()

    show = make_show(
        show_id=show_id,
    )

    entry = SimpleNamespace(
        id=uuid4(),
        show_id=show_id,
        show=show,
        status=LibraryStatus.PLANNING,
        rating=None,
        started_at=None,
        completed_at=None,
        created_at=datetime.now(UTC),
        updated_at=datetime.now(UTC),
    )

    episode = SimpleNamespace(
        id=episode_id,
        tmdb_id=1947647,
        episode_number=1,
        title="Good News About Hell",
        air_date=None,
        runtime=52,
    )

    library_repository.list_shows_by_user.return_value = [entry]

    episode_repository.get_first_aired_regular_for_shows.return_value = {
        show_id: (
            episode,
            1,
        )
    }

    result = library_service.list_shows_for_user(
        user_id,
    )

    assert len(result) == 1

    item = result[0]

    assert item.first_available_episode is not None
    assert item.first_available_episode.id == episode_id
    assert item.first_available_episode.tmdb_id == 1947647
    assert item.first_available_episode.season_number == 1
    assert item.first_available_episode.episode_number == 1
    assert item.first_available_episode.title == "Good News About Hell"

    episode_repository.get_first_aired_regular_for_shows.assert_called_once()


def test_list_shows_for_user_only_requests_first_episode_for_planning_shows(
    library_service: LibraryService,
    library_repository: Mock,
    episode_repository: Mock,
) -> None:
    """Only Planning Shows need their first available Episode."""

    user_id = uuid4()

    planning_show_id = uuid4()
    watching_show_id = uuid4()

    planning_entry = SimpleNamespace(
        id=uuid4(),
        show_id=planning_show_id,
        show=make_show(
            show_id=planning_show_id,
            tmdb_id=1396,
            title="Breaking Bad",
        ),
        status=LibraryStatus.PLANNING,
        rating=None,
        started_at=None,
        completed_at=None,
        created_at=datetime.now(UTC),
        updated_at=datetime.now(UTC),
    )

    watching_entry = SimpleNamespace(
        id=uuid4(),
        show_id=watching_show_id,
        show=make_show(
            show_id=watching_show_id,
            tmdb_id=95396,
            title="Severance",
        ),
        status=LibraryStatus.WATCHING,
        rating=None,
        started_at=datetime.now(UTC),
        completed_at=None,
        created_at=datetime.now(UTC),
        updated_at=datetime.now(UTC),
    )

    library_repository.list_shows_by_user.return_value = [
        planning_entry,
        watching_entry,
    ]

    episode_repository.get_first_aired_regular_for_shows.return_value = {}

    result = library_service.list_shows_for_user(
        user_id,
    )

    assert len(result) == 2

    episode_repository.get_first_aired_regular_for_shows.assert_called_once()

    _, kwargs = (
        episode_repository
        .get_first_aired_regular_for_shows
        .call_args
    )

    assert kwargs["show_ids"] == [
        planning_show_id,
    ]

    assert result[0].first_available_episode is None
    assert result[1].first_available_episode is None



def test_get_preview_for_user_returns_recent_shows_movies_and_progress(
    library_service: LibraryService,
    library_repository: Mock,
    episode_repository: Mock,
    episode_progress_repository: Mock,
) -> None:
    """Return recent Library media with current aired Show progress."""

    user_id = uuid4()

    first_show_id = uuid4()
    second_show_id = uuid4()

    first_show = make_show(
        show_id=first_show_id,
        tmdb_id=95396,
        title="Severance",
    )

    second_show = make_show(
        show_id=second_show_id,
        tmdb_id=1396,
        title="Breaking Bad",
    )

    first_show_entry = SimpleNamespace(
        show_id=first_show_id,
        show=first_show,
    )

    second_show_entry = SimpleNamespace(
        show_id=second_show_id,
        show=second_show,
    )

    movie_id = uuid4()

    movie = SimpleNamespace(
        id=movie_id,
        tmdb_id=438631,
        title="Dune",
        original_title="Dune",
        release_date=None,
        tmdb_poster_path=None,
        local_poster_path=None,
        poster_url=None,
        backdrop_url=None,
        status="Released",
        vote_average=8.0,
    )

    movie_entry = SimpleNamespace(
        movie_id=movie_id,
        movie=movie,
    )

    library_repository.list_recent_shows_by_user.return_value = [
        first_show_entry,
        second_show_entry,
    ]

    library_repository.list_recent_movies_by_user.return_value = [
        movie_entry,
    ]

    episode_repository.get_aired_counts_by_show_ids.return_value = {
        first_show_id: 10,
        second_show_id: 62,
    }

    episode_progress_repository.get_watched_aired_counts_by_show_ids.return_value = {
        first_show_id: 4,
        second_show_id: 62,
    }

    result = library_service.get_preview_for_user(
        user_id=user_id,
    )

    assert len(result.shows) == 2
    assert len(result.movies) == 1

    assert result.shows[0].show.id == first_show_id
    assert result.shows[0].show.tmdb_id == 95396
    assert result.shows[0].show.title == "Severance"
    assert result.shows[0].watched_episodes == 4
    assert result.shows[0].aired_episodes == 10

    assert result.shows[1].show.id == second_show_id
    assert result.shows[1].show.tmdb_id == 1396
    assert result.shows[1].show.title == "Breaking Bad"
    assert result.shows[1].watched_episodes == 62
    assert result.shows[1].aired_episodes == 62

    assert result.movies[0].movie.id == movie_id
    assert result.movies[0].movie.tmdb_id == 438631
    assert result.movies[0].movie.title == "Dune"

    library_repository.list_recent_shows_by_user.assert_called_once_with(
        user_id=user_id,
        limit=10,
    )

    library_repository.list_recent_movies_by_user.assert_called_once_with(
        user_id=user_id,
        limit=10,
    )

    episode_repository.get_aired_counts_by_show_ids.assert_called_once()

    _, aired_kwargs = (
        episode_repository
        .get_aired_counts_by_show_ids
        .call_args
    )

    assert aired_kwargs["show_ids"] == [
        first_show_id,
        second_show_id,
    ]

    episode_progress_repository.get_watched_aired_counts_by_show_ids.assert_called_once()

    _, watched_kwargs = (
        episode_progress_repository
        .get_watched_aired_counts_by_show_ids
        .call_args
    )

    assert watched_kwargs["user_id"] == user_id
    assert watched_kwargs["show_ids"] == [
        first_show_id,
        second_show_id,
    ]


def test_get_preview_for_user_uses_zero_for_missing_show_progress(
    library_service: LibraryService,
    library_repository: Mock,
    episode_repository: Mock,
    episode_progress_repository: Mock,
) -> None:
    """Use explicit zero progress when no Episode aggregates exist."""

    user_id = uuid4()
    show_id = uuid4()

    library_repository.list_recent_shows_by_user.return_value = [
        SimpleNamespace(
            show_id=show_id,
            show=make_show(
                show_id=show_id,
            ),
        ),
    ]

    library_repository.list_recent_movies_by_user.return_value = []

    episode_repository.get_aired_counts_by_show_ids.return_value = {}
    episode_progress_repository.get_watched_aired_counts_by_show_ids.return_value = {}

    result = library_service.get_preview_for_user(
        user_id=user_id,
    )

    assert len(result.shows) == 1

    assert result.shows[0].watched_episodes == 0
    assert result.shows[0].aired_episodes == 0

    assert result.movies == []


def test_get_preview_for_user_supports_empty_library(
    library_service: LibraryService,
    library_repository: Mock,
    episode_repository: Mock,
    episode_progress_repository: Mock,
) -> None:
    """Return usable empty preview collections without Library media."""

    user_id = uuid4()

    library_repository.list_recent_shows_by_user.return_value = []
    library_repository.list_recent_movies_by_user.return_value = []

    result = library_service.get_preview_for_user(
        user_id=user_id,
    )

    assert result.shows == []
    assert result.movies == []

    library_repository.list_recent_shows_by_user.assert_called_once_with(
        user_id=user_id,
        limit=10,
    )

    library_repository.list_recent_movies_by_user.assert_called_once_with(
        user_id=user_id,
        limit=10,
    )

    episode_repository.get_aired_counts_by_show_ids.assert_called_once_with(
        show_ids=[],
        as_of=ANY,
    )

    episode_progress_repository.get_watched_aired_counts_by_show_ids.assert_called_once_with(
        user_id=user_id,
        show_ids=[],
        as_of=ANY,
    )