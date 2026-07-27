from uuid import UUID

from sqlalchemy.orm import Session

from app.models.enums import LibraryStatus
from app.models.library import LibraryEntry
from app.repositories.library import LibraryRepository
from app.repositories.show import ShowRepository
from app.services.exceptions import LibraryEntryAlreadyExistsError


class LibraryService:
    """Business logic for a user's personal TV library."""

    def __init__(
        self,
        *,
        session: Session,
        library_repository: LibraryRepository,
        show_repository: ShowRepository,
    ) -> None:
        self._session = session
        self._library_repository = library_repository
        self._show_repository = show_repository

    def list_for_user(
        self,
        user_id: UUID,
        *,
        status: LibraryStatus | None = None,
    ) -> list[LibraryEntry]:
        """Return a user's library entries."""

        return self._library_repository.list_by_user(
            user_id,
            status=status,
        )

    def get_entry(
        self,
        *,
        user_id: UUID,
        show_id: UUID,
    ) -> LibraryEntry | None:
        """Return the user's library entry for a TV series."""

        return self._library_repository.get_by_user_and_show(
            user_id=user_id,
            show_id=show_id,
        )

    def add_show(
        self,
        *,
        user_id: UUID,
        show_id: UUID,
        status: LibraryStatus = LibraryStatus.PLANNING,
    ) -> LibraryEntry | None:
        """Add a locally stored TV series to a user's library.

        Returns None when the TV series does not exist locally.
        """

        show = self._show_repository.get_by_id(show_id)

        if show is None:
            return None

        existing_entry = self._library_repository.get_by_user_and_show(
            user_id=user_id,
            show_id=show_id,
        )

        if existing_entry is not None:
            raise LibraryEntryAlreadyExistsError(
                "TV series already exists in the user's library."
            )

        entry = LibraryEntry(
            user_id=user_id,
            show_id=show_id,
            status=status,
        )

        self._library_repository.add(entry)

        self._session.commit()
        self._session.refresh(entry)

        return entry

    def remove_show(
        self,
        *,
        user_id: UUID,
        show_id: UUID,
    ) -> bool:
        """Remove a TV series from a user's library."""

        entry = self._library_repository.get_by_user_and_show(
            user_id=user_id,
            show_id=show_id,
        )

        if entry is None:
            return False

        self._library_repository.delete(entry)
        self._session.commit()

        return True

    def update_status(
        self,
        *,
        user_id: UUID,
        show_id: UUID,
        status: LibraryStatus,
    ) -> LibraryEntry | None:
        """Update the tracking status of a library entry."""

        entry = self._library_repository.get_by_user_and_show(
            user_id=user_id,
            show_id=show_id,
        )

        if entry is None:
            return None

        entry.status = status

        self._session.commit()
        self._session.refresh(entry)

        return entry