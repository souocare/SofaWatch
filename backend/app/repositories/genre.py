from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models import Genre


class GenreRepository:
    """Database operations for genres."""

    def __init__(self, session: Session) -> None:
        self._session = session

    def list_all(self) -> list[Genre]:
        """Return all genres ordered by name."""

        statement = select(Genre).order_by(Genre.name)

        return list(
            self._session.scalars(statement).all()
        )