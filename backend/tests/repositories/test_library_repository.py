from sqlalchemy.orm import Session

from app.models.enums import LibraryStatus
from app.models.library import LibraryEntry
from app.models.show import Show
from app.models.user import User
from app.repositories.library import LibraryRepository


def create_user(
    db_session: Session,
    *,
    display_name: str = "Test User",
) -> User:
    """Create a user for library repository tests."""

    user = User(
        display_name=display_name,
        is_local=False,
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
