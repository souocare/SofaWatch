from sqlalchemy import or_, select
from sqlalchemy.orm import Session

from app.models import Genre


class GenreRepository:
    """Database operations for genres."""

    def __init__(self, session: Session) -> None:
        self._session = session

    def list_all(self) -> list[Genre]:
        """Return all genres ordered by name."""

        statement = select(Genre).order_by(Genre.name)

        return list(self._session.scalars(statement).all())

    def get_by_name_or_slug(
        self,
        *,
        name: str,
        slug: str,
    ) -> Genre | None:
        """Return a genre with the given name or slug."""

        statement = select(Genre).where(
            or_(
                Genre.name == name,
                Genre.slug == slug,
            )
        )

        return self._session.scalar(statement)

    def add(self, genre: Genre) -> Genre:
        """Add and persist a genre."""

        self._session.add(genre)
        self._session.commit()
        self._session.refresh(genre)

        return genre
