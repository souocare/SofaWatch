from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.models.show import Show


class ShowRepository:
    """Data access operations for locally stored TV series."""

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
    ) -> list[Show]:
        """Return locally stored shows ordered alphabetically."""

        statement = (
            select(Show)
            .options(selectinload(Show.genres))
            .order_by(Show.title.asc())
            .offset(offset)
            .limit(limit)
        )

        return list(self._session.scalars(statement).all())

    def add(self, show: Show) -> Show:
        """Add a show to the current database session."""

        self._session.add(show)
        self._session.flush()

        return show
