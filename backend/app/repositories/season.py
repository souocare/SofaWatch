from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.season import Season


class SeasonRepository:
    """Database operations for locally stored TV seasons."""

    def __init__(self, session: Session) -> None:
        self._session = session

    def get_by_tmdb_id(
        self,
        *,
        show_id: UUID,
        tmdb_id: int,
    ) -> Season | None:
        """Return a season by show and TMDB identifier."""

        statement = select(Season).where(
            Season.show_id == show_id,
            Season.tmdb_id == tmdb_id,
        )

        return self._session.scalar(statement)

    def get_by_id(
        self,
        season_id: UUID,
    ) -> Season | None:
        """Return a season by its internal identifier."""

        return self._session.get(
            Season,
            season_id,
        )

    def get_by_number(
        self,
        *,
        show_id: UUID,
        season_number: int,
    ) -> Season | None:
        """Return a season by show and season number."""

        statement = select(Season).where(
            Season.show_id == show_id,
            Season.season_number == season_number,
        )

        return self._session.scalar(statement)

    def add(self, season: Season) -> Season:
        """Add a season to the current database session."""

        self._session.add(season)
        self._session.flush()

        return season

    def list_by_show_id(
        self,
        show_id: UUID,
    ) -> list[Season]:
        """Return all seasons belonging to a TV series."""

        statement = (
            select(Season).where(Season.show_id == show_id).order_by(Season.season_number.asc())
        )

        return list(self._session.scalars(statement).all())
