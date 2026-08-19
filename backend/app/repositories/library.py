from collections.abc import Collection
from uuid import UUID

from sqlalchemy import func, select
from sqlalchemy.orm import Session, joinedload

from app.models.enums import LibraryStatus
from app.models.library import LibraryEntry
from app.models.movie import Movie
from app.models.show import Show


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

    def get_by_user_and_movie(
        self,
        *,
        user_id: UUID,
        movie_id: UUID,
    ) -> LibraryEntry | None:
        """Return a user's library entry for a movie."""

        return self._session.scalar(
            select(LibraryEntry).where(
                LibraryEntry.user_id == user_id,
                LibraryEntry.movie_id == movie_id,
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

        return list(
            self._session.scalars(statement).all()
        )

    def list_shows_by_user(
        self,
        user_id: UUID,
        *,
        status: LibraryStatus | None = None,
    ) -> list[LibraryEntry]:
        """Return TV series library entries belonging to a user."""

        statement = (
            select(LibraryEntry)
            .options(
                joinedload(LibraryEntry.show),
            )
            .where(
                LibraryEntry.user_id == user_id,
                LibraryEntry.show_id.is_not(None),
            )
        )

        if status is not None:
            statement = statement.where(
                LibraryEntry.status == status,
            )

        statement = statement.order_by(
            LibraryEntry.updated_at.desc(),
            LibraryEntry.created_at.desc(),
        )

        return list(
            self._session.scalars(statement).all()
        )


    def list_movies_by_user(
        self,
        user_id: UUID,
        *,
        status: LibraryStatus | None = None,
    ) -> list[LibraryEntry]:
        """Return Movie library entries belonging to a user."""

        statement = (
            select(LibraryEntry)
            .options(
                joinedload(LibraryEntry.movie),
            )
            .where(
                LibraryEntry.user_id == user_id,
                LibraryEntry.movie_id.is_not(None),
            )
        )

        if status is not None:
            statement = statement.where(
                LibraryEntry.status == status,
            )

        statement = statement.order_by(
            LibraryEntry.updated_at.desc(),
            LibraryEntry.created_at.desc(),
        )

        return list(
            self._session.scalars(statement).all()
        )

    def count_shows_by_user(
        self,
        *,
        user_id: UUID,
    ) -> int:
        """Return the number of Shows currently in a user's library."""

        statement = (
            select(
                func.count(),
            )
            .select_from(
                LibraryEntry,
            )
            .where(
                LibraryEntry.user_id == user_id,
                LibraryEntry.show_id.is_not(None),
            )
        )

        return self._session.scalar(statement) or 0

    def count_movies_by_user(
        self,
        *,
        user_id: UUID,
    ) -> int:
        """Return the number of Movies currently in a user's library."""

        statement = (
            select(
                func.count(),
            )
            .select_from(
                LibraryEntry,
            )
            .where(
                LibraryEntry.user_id == user_id,
                LibraryEntry.movie_id.is_not(None),
            )
        )

        return self._session.scalar(statement) or 0

    def count_completed_shows_by_user(
        self,
        *,
        user_id: UUID,
    ) -> int:
        """Return the number of completed Shows in a user's library."""

        statement = (
            select(
                func.count(),
            )
            .select_from(
                LibraryEntry,
            )
            .where(
                LibraryEntry.user_id == user_id,
                LibraryEntry.show_id.is_not(None),
                LibraryEntry.status == LibraryStatus.COMPLETED,
            )
        )

        return self._session.scalar(statement) or 0

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

    def get_show_tmdb_ids_in_library(
        self,
        *,
        user_id: UUID,
        tmdb_ids: Collection[int],
    ) -> set[int]:
        """Return the requested Show TMDB IDs present in a user's library."""

        if not tmdb_ids:
            return set()

        statement = (
            select(Show.tmdb_id)
            .join(
                LibraryEntry,
                LibraryEntry.show_id == Show.id,
            )
            .where(
                LibraryEntry.user_id == user_id,
                Show.tmdb_id.in_(tmdb_ids),
            )
        )

        return set(
            self._session.scalars(statement).all()
        )

    def get_movie_tmdb_ids_in_library(
        self,
        *,
        user_id: UUID,
        tmdb_ids: Collection[int],
    ) -> set[int]:
        """Return the requested Movie TMDB IDs present in a user's library."""

        if not tmdb_ids:
            return set()

        statement = (
            select(Movie.tmdb_id)
            .join(
                LibraryEntry,
                LibraryEntry.movie_id == Movie.id,
            )
            .where(
                LibraryEntry.user_id == user_id,
                Movie.tmdb_id.in_(tmdb_ids),
            )
        )

        return set(
            self._session.scalars(statement).all()
        )


    def get_backlog_show_ids_for_user(
        self,
        *,
        user_id: UUID,
    ) -> list[UUID]:
        """Return Show IDs that currently contribute to the user's backlog."""

        statement = select(
            LibraryEntry.show_id,
        ).where(
            LibraryEntry.user_id == user_id,
            LibraryEntry.show_id.is_not(None),
            LibraryEntry.status != LibraryStatus.DROPPED,
        )

        return [
            show_id
            for show_id in self._session.scalars(statement).all()
            if show_id is not None
        ]


    def get_planned_movie_statistics(
        self,
        *,
        user_id: UUID,
    ) -> tuple[int, int]:
        """Return Planned Movie count and total known runtime."""

        row = self._session.execute(
            select(
                func.count(LibraryEntry.id),
                func.coalesce(
                    func.sum(Movie.runtime),
                    0,
                ),
            )
            .select_from(LibraryEntry)
            .join(
                Movie,
                Movie.id == LibraryEntry.movie_id,
            )
            .where(
                LibraryEntry.user_id == user_id,
                LibraryEntry.movie_id.is_not(None),
                LibraryEntry.status == LibraryStatus.PLANNING,
            )
        ).one()

        return (
            int(row[0] or 0),
            int(row[1] or 0),
        )