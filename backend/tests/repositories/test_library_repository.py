from sqlalchemy.orm import Session
from datetime import UTC, datetime, timedelta

from app.models.enums import LibraryStatus
from app.models.library import LibraryEntry
from app.models.show import Show
from app.models.user import User
from app.models.movie import Movie
from app.repositories.library import LibraryRepository
import pytest
from sqlalchemy.exc import IntegrityError


def create_user(
    db_session: Session,
    *,
    display_name: str = "Test User",
) -> User:
    """Create a user for library repository tests."""

    user = User(
        display_name=display_name,
    )

    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)

    return user


def create_show(
    db_session: Session,
    *,
    tmdb_id: int,
    title: str,
) -> Show:
    """Create a locally stored TV series."""

    show = Show(
        tmdb_id=tmdb_id,
        title=title,
        original_title=title,
        original_language="en",
        metadata_language="en-US",
    )

    db_session.add(show)
    db_session.commit()
    db_session.refresh(show)

    return show

def create_movie(
    db_session: Session,
    *,
    tmdb_id: int,
    title: str,
) -> Movie:
    """Create a locally stored movie."""

    movie = Movie(
        tmdb_id=tmdb_id,
        title=title,
        original_title=title,
        original_language="en",
        runtime=120,
        status="Released",
        adult=False,
        video=False,
        popularity=10.0,
        vote_average=8.0,
        vote_count=100,
        metadata_language="en-US",
    )

    db_session.add(movie)
    db_session.commit()
    db_session.refresh(movie)

    return movie

def test_add_and_get_library_entry(
    db_session: Session,
) -> None:
    """Add and retrieve a library entry."""

    user = create_user(db_session)
    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    repository = LibraryRepository(db_session)

    entry = LibraryEntry(
        user_id=user.id,
        show_id=show.id,
        status=LibraryStatus.PLANNING,
    )

    repository.add(entry)
    db_session.commit()

    result = repository.get_by_user_and_show(
        user_id=user.id,
        show_id=show.id,
    )

    assert result is not None
    assert result.id == entry.id
    assert result.user_id == user.id
    assert result.show_id == show.id
    assert result.status == LibraryStatus.PLANNING


def test_get_library_entry_by_id(
    db_session: Session,
) -> None:
    """Retrieve a library entry by its identifier."""

    user = create_user(db_session)
    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    entry = LibraryEntry(
        user_id=user.id,
        show_id=show.id,
        status=LibraryStatus.WATCHING,
    )

    db_session.add(entry)
    db_session.commit()
    db_session.refresh(entry)

    repository = LibraryRepository(db_session)

    result = repository.get_by_id(entry.id)

    assert result is not None
    assert result.id == entry.id
    assert result.status == LibraryStatus.WATCHING


def test_get_missing_library_entry_returns_none(
    db_session: Session,
) -> None:
    """Return None when a show is not in the user's library."""

    user = create_user(db_session)
    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    repository = LibraryRepository(db_session)

    result = repository.get_by_user_and_show(
        user_id=user.id,
        show_id=show.id,
    )

    assert result is None


def test_list_library_entries_for_user(
    db_session: Session,
) -> None:
    """Return only entries belonging to the requested user."""

    user = create_user(
        db_session,
        display_name="User One",
    )
    other_user = create_user(
        db_session,
        display_name="User Two",
    )

    show_one = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )
    show_two = create_show(
        db_session,
        tmdb_id=1396,
        title="Breaking Bad",
    )
    other_show = create_show(
        db_session,
        tmdb_id=66732,
        title="Stranger Things",
    )

    db_session.add_all(
        [
            LibraryEntry(
                user_id=user.id,
                show_id=show_one.id,
                status=LibraryStatus.WATCHING,
            ),
            LibraryEntry(
                user_id=user.id,
                show_id=show_two.id,
                status=LibraryStatus.PLANNING,
            ),
            LibraryEntry(
                user_id=other_user.id,
                show_id=other_show.id,
                status=LibraryStatus.COMPLETED,
            ),
        ]
    )
    db_session.commit()

    repository = LibraryRepository(db_session)

    entries = repository.list_by_user(user.id)

    assert len(entries) == 2
    assert {entry.show_id for entry in entries} == {
        show_one.id,
        show_two.id,
    }


def test_list_library_entries_filters_by_status(
    db_session: Session,
) -> None:
    """Filter a user's library by tracking status."""

    user = create_user(db_session)

    watching_show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )
    planning_show = create_show(
        db_session,
        tmdb_id=1396,
        title="Breaking Bad",
    )

    db_session.add_all(
        [
            LibraryEntry(
                user_id=user.id,
                show_id=watching_show.id,
                status=LibraryStatus.WATCHING,
            ),
            LibraryEntry(
                user_id=user.id,
                show_id=planning_show.id,
                status=LibraryStatus.PLANNING,
            ),
        ]
    )
    db_session.commit()

    repository = LibraryRepository(db_session)

    entries = repository.list_by_user(
        user.id,
        status=LibraryStatus.WATCHING,
    )

    assert len(entries) == 1
    assert entries[0].show_id == watching_show.id
    assert entries[0].status == LibraryStatus.WATCHING


def test_delete_library_entry(
    db_session: Session,
) -> None:
    """Delete a library entry."""

    user = create_user(db_session)
    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    entry = LibraryEntry(
        user_id=user.id,
        show_id=show.id,
        status=LibraryStatus.PLANNING,
    )

    db_session.add(entry)
    db_session.commit()

    repository = LibraryRepository(db_session)

    repository.delete(entry)
    db_session.commit()

    result = repository.get_by_user_and_show(
        user_id=user.id,
        show_id=show.id,
    )

    assert result is None


def test_add_and_get_movie_library_entry(
    db_session: Session,
) -> None:
    """Add and retrieve a movie library entry."""

    user = create_user(db_session)

    movie = create_movie(
        db_session,
        tmdb_id=438631,
        title="Dune",
    )

    repository = LibraryRepository(
        db_session,
    )

    entry = LibraryEntry(
        user_id=user.id,
        movie_id=movie.id,
        status=LibraryStatus.PLANNING,
    )

    repository.add(entry)
    db_session.commit()

    result = repository.get_by_user_and_movie(
        user_id=user.id,
        movie_id=movie.id,
    )

    assert result is not None

    assert result.id == entry.id
    assert result.user_id == user.id

    assert result.show_id is None
    assert result.movie_id == movie.id

    assert result.status == LibraryStatus.PLANNING

def test_get_missing_movie_library_entry_returns_none(
    db_session: Session,
) -> None:
    """Return None when a movie is not in the user's library."""

    user = create_user(db_session)

    movie = create_movie(
        db_session,
        tmdb_id=438631,
        title="Dune",
    )

    repository = LibraryRepository(
        db_session,
    )

    result = repository.get_by_user_and_movie(
        user_id=user.id,
        movie_id=movie.id,
    )

    assert result is None



def test_library_entry_requires_media_target(
    db_session: Session,
) -> None:
    """Reject an entry without a Show or Movie."""

    user = create_user(
        db_session,
    )

    entry = LibraryEntry(
        user_id=user.id,
        status=LibraryStatus.PLANNING,
    )

    db_session.add(entry)

    with pytest.raises(IntegrityError):
        db_session.commit()

    db_session.rollback()


def test_library_entry_rejects_multiple_media_targets(
    db_session: Session,
) -> None:
    """Reject an entry referencing both a Show and Movie."""

    user = create_user(
        db_session,
    )

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    movie = create_movie(
        db_session,
        tmdb_id=438631,
        title="Dune",
    )

    entry = LibraryEntry(
        user_id=user.id,
        show_id=show.id,
        movie_id=movie.id,
        status=LibraryStatus.PLANNING,
    )

    db_session.add(entry)

    with pytest.raises(IntegrityError):
        db_session.commit()

    db_session.rollback()



def test_user_cannot_have_duplicate_movie_library_entry(
    db_session: Session,
) -> None:
    """Reject duplicate Movie entries for the same user."""

    user = create_user(
        db_session,
    )

    movie = create_movie(
        db_session,
        tmdb_id=438631,
        title="Dune",
    )

    db_session.add(
        LibraryEntry(
            user_id=user.id,
            movie_id=movie.id,
            status=LibraryStatus.PLANNING,
        )
    )

    db_session.commit()

    db_session.add(
        LibraryEntry(
            user_id=user.id,
            movie_id=movie.id,
            status=LibraryStatus.PLANNING,
        )
    )

    with pytest.raises(IntegrityError):
        db_session.commit()

    db_session.rollback()


def test_get_show_tmdb_ids_in_library(
    db_session: Session,
) -> None:
    user = create_user(db_session)

    severance = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    breaking_bad = create_show(
        db_session,
        tmdb_id=1396,
        title="Breaking Bad",
    )

    db_session.add(
        LibraryEntry(
            user_id=user.id,
            show_id=severance.id,
            status=LibraryStatus.PLANNING,
        )
    )

    db_session.commit()

    repository = LibraryRepository(
        db_session,
    )

    result = repository.get_show_tmdb_ids_in_library(
        user_id=user.id,
        tmdb_ids={
            95396,
            1396,
            999999,
        },
    )

    assert result == {
        95396,
    }

    assert breaking_bad.tmdb_id not in result

def test_get_movie_tmdb_ids_in_library(
    db_session: Session,
) -> None:
    user = create_user(db_session)

    dune = create_movie(
        db_session,
        tmdb_id=438631,
        title="Dune",
    )

    matrix = create_movie(
        db_session,
        tmdb_id=603,
        title="The Matrix",
    )

    db_session.add(
        LibraryEntry(
            user_id=user.id,
            movie_id=dune.id,
            status=LibraryStatus.PLANNING,
        )
    )

    db_session.commit()

    repository = LibraryRepository(
        db_session,
    )

    result = repository.get_movie_tmdb_ids_in_library(
        user_id=user.id,
        tmdb_ids={
            438631,
            603,
            999999,
        },
    )

    assert result == {
        438631,
    }

    assert matrix.tmdb_id not in result


def test_get_library_tmdb_ids_returns_empty_sets_for_empty_input(
    db_session: Session,
) -> None:
    user = create_user(db_session)

    repository = LibraryRepository(
        db_session,
    )

    assert repository.get_show_tmdb_ids_in_library(
        user_id=user.id,
        tmdb_ids=set(),
    ) == set()

    assert repository.get_movie_tmdb_ids_in_library(
        user_id=user.id,
        tmdb_ids=set(),
    ) == set()


def test_count_library_statistics_for_user(
    db_session: Session,
) -> None:
    """Count Shows, Movies and completed Shows for one user."""

    user = create_user(
        db_session,
    )

    watching_show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    completed_show = create_show(
        db_session,
        tmdb_id=1396,
        title="Breaking Bad",
    )

    planning_show = create_show(
        db_session,
        tmdb_id=66732,
        title="Stranger Things",
    )

    planning_movie = create_movie(
        db_session,
        tmdb_id=438631,
        title="Dune",
    )

    completed_movie = create_movie(
        db_session,
        tmdb_id=603,
        title="The Matrix",
    )

    db_session.add_all(
        [
            LibraryEntry(
                user_id=user.id,
                show_id=watching_show.id,
                status=LibraryStatus.WATCHING,
            ),
            LibraryEntry(
                user_id=user.id,
                show_id=completed_show.id,
                status=LibraryStatus.COMPLETED,
            ),
            LibraryEntry(
                user_id=user.id,
                show_id=planning_show.id,
                status=LibraryStatus.PLANNING,
            ),
            LibraryEntry(
                user_id=user.id,
                movie_id=planning_movie.id,
                status=LibraryStatus.PLANNING,
            ),
            LibraryEntry(
                user_id=user.id,
                movie_id=completed_movie.id,
                status=LibraryStatus.COMPLETED,
            ),
        ]
    )

    db_session.commit()

    repository = LibraryRepository(
        db_session,
    )

    assert repository.count_shows_by_user(
        user_id=user.id,
    ) == 3

    assert repository.count_movies_by_user(
        user_id=user.id,
    ) == 2

    assert repository.count_completed_shows_by_user(
        user_id=user.id,
    ) == 1


def test_count_library_statistics_is_isolated_by_user(
    db_session: Session,
) -> None:
    """Exclude another user's Library entries from statistics."""

    user = create_user(
        db_session,
        display_name="Requested User",
    )

    other_user = create_user(
        db_session,
        display_name="Other User",
    )

    user_show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    other_show = create_show(
        db_session,
        tmdb_id=1396,
        title="Breaking Bad",
    )

    other_movie = create_movie(
        db_session,
        tmdb_id=438631,
        title="Dune",
    )

    db_session.add_all(
        [
            LibraryEntry(
                user_id=user.id,
                show_id=user_show.id,
                status=LibraryStatus.COMPLETED,
            ),
            LibraryEntry(
                user_id=other_user.id,
                show_id=other_show.id,
                status=LibraryStatus.COMPLETED,
            ),
            LibraryEntry(
                user_id=other_user.id,
                movie_id=other_movie.id,
                status=LibraryStatus.COMPLETED,
            ),
        ]
    )

    db_session.commit()

    repository = LibraryRepository(
        db_session,
    )

    assert repository.count_shows_by_user(
        user_id=user.id,
    ) == 1

    assert repository.count_movies_by_user(
        user_id=user.id,
    ) == 0

    assert repository.count_completed_shows_by_user(
        user_id=user.id,
    ) == 1


def test_count_library_statistics_returns_zero_without_entries(
    db_session: Session,
) -> None:
    """Return zero counts when the user has an empty Library."""

    user = create_user(
        db_session,
    )

    repository = LibraryRepository(
        db_session,
    )

    assert repository.count_shows_by_user(
        user_id=user.id,
    ) == 0

    assert repository.count_movies_by_user(
        user_id=user.id,
    ) == 0

    assert repository.count_completed_shows_by_user(
        user_id=user.id,
    ) == 0


def test_list_recent_shows_by_user_returns_latest_added_first(
    db_session: Session,
) -> None:
    """Return recent Shows ordered by Library creation time."""

    user = create_user(
        db_session,
    )

    first_show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    second_show = create_show(
        db_session,
        tmdb_id=1396,
        title="Breaking Bad",
    )

    now = datetime.now(UTC)

    first_entry = LibraryEntry(
        user_id=user.id,
        show_id=first_show.id,
        status=LibraryStatus.WATCHING,
        created_at=now - timedelta(minutes=1),
    )

    db_session.add(first_entry)
    db_session.commit()

    second_entry = LibraryEntry(
        user_id=user.id,
        show_id=second_show.id,
        status=LibraryStatus.PLANNING,
        created_at=now,
    )

    db_session.add(second_entry)
    db_session.commit()

    repository = LibraryRepository(
        db_session,
    )

    result = repository.list_recent_shows_by_user(
        user_id=user.id,
        limit=10,
    )

    assert [
        entry.show_id
        for entry in result
    ] == [
        second_show.id,
        first_show.id,
    ]

    assert result[0].show is not None
    assert result[0].show.title == "Breaking Bad"


def test_list_recent_shows_by_user_respects_limit(
    db_session: Session,
) -> None:
    """Limit the number of recent Shows returned."""

    user = create_user(
        db_session,
    )

    shows = [
        create_show(
            db_session,
            tmdb_id=1000 + index,
            title=f"Show {index}",
        )
        for index in range(3)
    ]

    for show in shows:
        db_session.add(
            LibraryEntry(
                user_id=user.id,
                show_id=show.id,
                status=LibraryStatus.PLANNING,
            )
        )

        db_session.commit()

    repository = LibraryRepository(
        db_session,
    )

    result = repository.list_recent_shows_by_user(
        user_id=user.id,
        limit=2,
    )

    assert len(result) == 2


def test_list_recent_shows_by_user_is_isolated_by_user(
    db_session: Session,
) -> None:
    """Exclude Shows belonging to another user's Library."""

    user = create_user(
        db_session,
        display_name="Requested User",
    )

    other_user = create_user(
        db_session,
        display_name="Other User",
    )

    requested_show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    other_show = create_show(
        db_session,
        tmdb_id=1396,
        title="Breaking Bad",
    )

    db_session.add_all(
        [
            LibraryEntry(
                user_id=user.id,
                show_id=requested_show.id,
                status=LibraryStatus.WATCHING,
            ),
            LibraryEntry(
                user_id=other_user.id,
                show_id=other_show.id,
                status=LibraryStatus.WATCHING,
            ),
        ]
    )

    db_session.commit()

    repository = LibraryRepository(
        db_session,
    )

    result = repository.list_recent_shows_by_user(
        user_id=user.id,
    )

    assert [
        entry.show_id
        for entry in result
    ] == [
        requested_show.id,
    ]


def test_list_recent_movies_by_user_returns_latest_added_first(
    db_session: Session,
) -> None:
    """Return recent Movies ordered by Library creation time."""

    user = create_user(
        db_session,
    )

    now = datetime.now(UTC)

    first_movie = create_movie(
        db_session,
        tmdb_id=438631,
        title="Dune",
    )

    second_movie = create_movie(
        db_session,
        tmdb_id=603,
        title="The Matrix",
    )

    db_session.add(
        LibraryEntry(
            user_id=user.id,
            movie_id=first_movie.id,
            status=LibraryStatus.COMPLETED,
            created_at=now - timedelta(minutes=1),
        )
    )

    db_session.commit()

    db_session.add(
        LibraryEntry(
            user_id=user.id,
            movie_id=second_movie.id,
            status=LibraryStatus.PLANNING,
            created_at=now,
        )
    )

    db_session.commit()

    repository = LibraryRepository(
        db_session,
    )

    result = repository.list_recent_movies_by_user(
        user_id=user.id,
        limit=10,
    )

    assert [
        entry.movie_id
        for entry in result
    ] == [
        second_movie.id,
        first_movie.id,
    ]

    assert result[0].movie is not None
    assert result[0].movie.title == "The Matrix"


def test_list_recent_movies_by_user_respects_limit(
    db_session: Session,
) -> None:
    """Limit the number of recent Movies returned."""

    user = create_user(
        db_session,
    )

    movies = [
        create_movie(
            db_session,
            tmdb_id=5000 + index,
            title=f"Movie {index}",
        )
        for index in range(3)
    ]

    for movie in movies:
        db_session.add(
            LibraryEntry(
                user_id=user.id,
                movie_id=movie.id,
                status=LibraryStatus.PLANNING,
            )
        )

        db_session.commit()

    repository = LibraryRepository(
        db_session,
    )

    result = repository.list_recent_movies_by_user(
        user_id=user.id,
        limit=2,
    )

    assert len(result) == 2


def test_list_recent_library_methods_return_empty_for_non_positive_limit(
    db_session: Session,
) -> None:
    """Avoid database work for invalid preview limits."""

    user = create_user(
        db_session,
    )

    repository = LibraryRepository(
        db_session,
    )

    assert repository.list_recent_shows_by_user(
        user_id=user.id,
        limit=0,
    ) == []

    assert repository.list_recent_movies_by_user(
        user_id=user.id,
        limit=0,
    ) == []