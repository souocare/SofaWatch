from __future__ import annotations

from uuid import UUID

from sqlalchemy import asc, desc, distinct, func, or_, select
from sqlalchemy.orm import Session, selectinload

from app.api.params.show import ShowSortField, ShowStatus, SortDirection
from app.models.genre import Genre
from app.models.show import Show


class ShowRepository:
    """Data access operations for locally stored TV series."""

    _SORT_FIELDS = {
        ShowSortField.TITLE: Show.title,
        ShowSortField.FIRST_AIR_DATE: Show.first_air_date,
        ShowSortField.VOTE_AVERAGE: Show.vote_average,
        ShowSortField.POPULARITY: Show.popularity,
        ShowSortField.CREATED_AT: Show.created_at,
        ShowSortField.UPDATED_AT: Show.updated_at,
    }

    def __init__(self, session: Session) -> None:
        self._session = session

    def get_by_id(self, show_id: UUID) -> Show | None:
        """Return a locally stored show by its internal UUID."""

        statement = select(Show).options(selectinload(Show.genres)).where(Show.id == show_id)

        return self._session.scalar(statement)

    def get_by_tmdb_id(self, tmdb_id: int) -> Show | None:
        """Return a locally stored show by its TMDB identifier."""

        statement = select(Show).options(selectinload(Show.genres)).where(Show.tmdb_id == tmdb_id)

        return self._session.scalar(statement)

    def exists_by_tmdb_id(self, tmdb_id: int) -> bool:
        """Return whether a show with the given TMDB ID already exists."""

        statement = select(Show.id).where(Show.tmdb_id == tmdb_id).limit(1)

        return self._session.scalar(statement) is not None

    def list(
        self,
        *,
        offset: int = 0,
        limit: int = 50,
        sort_by: ShowSortField = ShowSortField.TITLE,
        sort_direction: SortDirection = SortDirection.ASC,
        query: str | None = None,
        genre: str | None = None,
        status: ShowStatus | None = None,
    ) -> list[Show]:
        """Return locally stored TV series matching the supplied filters."""

        statement = select(Show).options(selectinload(Show.genres))

        if query:
            statement = statement.where(
                or_(
                    Show.title.ilike(f"%{query}%"),
                    Show.original_title.ilike(f"%{query}%"),
                )
            )

        if genre:
            statement = statement.join(Show.genres).where(Genre.slug == genre)

        if status is not None:
            statement = statement.where(Show.status == status.value)

        statement = statement.order_by(
            self._build_order_by(
                sort_by,
                sort_direction,
            )
        )

        statement = statement.offset(offset).limit(limit)

        return list(self._session.scalars(statement).all())

    def add(self, show: Show) -> Show:
        """Add a show to the current database session."""

        self._session.add(show)
        self._session.flush()

        return show

    def count(
        self,
        *,
        query: str | None = None,
        genre: str | None = None,
        status: ShowStatus | None = None,
    ) -> int:
        """Count locally stored TV series matching the supplied filters."""

        statement = select(func.count(distinct(Show.id)))

        if query:
            statement = statement.where(
                or_(
                    Show.title.ilike(f"%{query}%"),
                    Show.original_title.ilike(f"%{query}%"),
                )
            )

        if genre:
            statement = statement.join(Show.genres).where(Genre.slug == genre)

        if status is not None:
            statement = statement.where(Show.status == status.value)

        return self._session.scalar(statement) or 0

    def list_all(
        self,
    ) -> list[Show]:
        """Return all locally stored TV series."""

        return list(
            self._session.scalars(
                select(Show).order_by(
                    Show.id,
                )
            ).all()
        )

    @staticmethod
    def _build_order_by(
        sort_by: ShowSortField,
        sort_direction: SortDirection,
    ):
        column = ShowRepository._SORT_FIELDS[sort_by]

        if sort_direction is SortDirection.DESC:
            return desc(column)

        return asc(column)
