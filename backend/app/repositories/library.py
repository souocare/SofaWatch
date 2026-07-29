from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.enums import LibraryStatus
from app.models.library import LibraryEntry


class LibraryRepository:
    """Persistence operations for personal library entries."""

    def __init__(
        self,
        session: Session,
    ) -> None:
        self._session = session

    def get_by_id(
        self,
        entry_id: UUID,
    ) -> LibraryEntry | None:
        """Return a library entry by its internal identifier."""

        return self._session.get(
            LibraryEntry,
            entry_id,
        )

    def get_by_user_and_show(
        self,
        *,
        user_id: UUID,
        show_id: UUID,
    ) -> LibraryEntry | None:
        """Return a user's library entry for a TV series."""

        return self._session.scalar(
            select(LibraryEntry).where(
                LibraryEntry.user_id == user_id,
                LibraryEntry.show_id == show_id,
            )
        )

    def list_by_user(
        self,
        user_id: UUID,
        *,
        status: LibraryStatus | None = None,
    ) -> list[LibraryEntry]:
        """Return the library entries belonging to a user."""

        statement = select(LibraryEntry).where(
            LibraryEntry.user_id == user_id,
        )

        if status is not None:
            statement = statement.where(
                LibraryEntry.status == status,
            )

        statement = statement.order_by(
            LibraryEntry.updated_at.desc(),
            LibraryEntry.created_at.desc(),
        )

        return list(self._session.scalars(statement).all())

    def add(
        self,
        entry: LibraryEntry,
    ) -> LibraryEntry:
        """Add a library entry to the current unit of work."""

        self._session.add(entry)

        return entry

    def delete(
        self,
        entry: LibraryEntry,
    ) -> None:
        """Delete a library entry from the current unit of work."""

        self._session.delete(entry)
