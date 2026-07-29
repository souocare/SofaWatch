from types import SimpleNamespace
from unittest.mock import Mock
from uuid import UUID, uuid4

import pytest
from sqlalchemy.orm import Session

from app.models.enums import LibraryStatus
from app.models.library import LibraryEntry
from app.repositories.library import LibraryRepository
from app.repositories.show import ShowRepository
from app.services.exceptions import LibraryEntryAlreadyExistsError
from app.services.library import LibraryService


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
) -> LibraryService:
    """Provide a library service using mocked repositories."""

    return LibraryService(
        session=db_session,
        library_repository=library_repository,
        show_repository=show_repository,
    )


def make_show(
    *,
    show_id: UUID,
) -> SimpleNamespace:
    """Create a lightweight show object for service tests."""

    return SimpleNamespace(
        id=show_id,
    )


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


def test_add_show_raises_when_entry_already_exists(
    library_service: LibraryService,
    library_repository: Mock,
    show_repository: Mock,
) -> None:
    """Reject a duplicate library entry."""

    user_id = uuid4()
    show_id = uuid4()

    show_repository.get_by_id.return_value = make_show(
        show_id=show_id,
    )

    existing_entry = make_entry(
        user_id=user_id,
        show_id=show_id,
    )

    library_repository.get_by_user_and_show.return_value = existing_entry

    with pytest.raises(
        LibraryEntryAlreadyExistsError,
        match="already exists",
    ):
        library_service.add_show(
            user_id=user_id,
            show_id=show_id,
        )

    library_repository.add.assert_not_called()


def test_add_show_creates_planning_entry_by_default(
    db_session: Session,
    library_service: LibraryService,
    library_repository: Mock,
    show_repository: Mock,
) -> None:
    """Create a planning entry when no status is specified."""

    user_id = uuid4()
    show_id = uuid4()

    show_repository.get_by_id.return_value = make_show(
        show_id=show_id,
    )
    library_repository.get_by_user_and_show.return_value = None

    def add_entry(entry: LibraryEntry) -> LibraryEntry:
        db_session.add(entry)
        return entry

    library_repository.add.side_effect = add_entry

    result = library_service.add_show(
        user_id=user_id,
        show_id=show_id,
    )

    assert result is not None
    assert result.user_id == user_id
    assert result.show_id == show_id
    assert result.status == LibraryStatus.PLANNING

    library_repository.add.assert_called_once_with(result)


def test_add_show_uses_selected_status(
    db_session: Session,
    library_service: LibraryService,
    library_repository: Mock,
    show_repository: Mock,
) -> None:
    """Create an entry using the explicitly selected status."""

    user_id = uuid4()
    show_id = uuid4()

    show_repository.get_by_id.return_value = make_show(
        show_id=show_id,
    )
    library_repository.get_by_user_and_show.return_value = None

    def add_entry(entry: LibraryEntry) -> LibraryEntry:
        db_session.add(entry)
        return entry

    library_repository.add.side_effect = add_entry

    result = library_service.add_show(
        user_id=user_id,
        show_id=show_id,
        status=LibraryStatus.WATCHING,
    )

    assert result is not None
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

    user_id = uuid4()
    show_id = uuid4()

    entry = make_entry(
        user_id=user_id,
        show_id=show_id,
        status=LibraryStatus.PLANNING,
    )

    db_session.add(entry)

    library_repository.get_by_user_and_show.return_value = entry

    result = library_service.update_status(
        user_id=user_id,
        show_id=show_id,
        status=LibraryStatus.WATCHING,
    )

    assert result is entry
    assert result.status == LibraryStatus.WATCHING
