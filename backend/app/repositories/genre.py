from sqlalchemy import or_, select
from sqlalchemy.orm import Session

from app.models.genre import Genre
from app.utils.slug import slugify

class GenreRepository:
    """Database operations for genres."""

    def __init__(self, session: Session) -> None:
        self._session = session

    def list_all(self) -> list[Genre]:
        """Return all genres ordered by name."""

        statement = select(Genre).order_by(Genre.name.asc())

        return list(self._session.scalars(statement).all())

    def get_by_tmdb_id(self, tmdb_id: int) -> Genre | None:
        """Return a genre by its TMDB identifier."""

        statement = select(Genre).where(Genre.tmdb_id == tmdb_id)

        return self._session.scalar(statement)

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
        """Add a genre to the current database session."""

        self._session.add(genre)
        self._session.flush()

        return genre
    
    def get_or_create(
        self,
        *,
        tmdb_id: int,
        name: str,
    ) -> Genre:
        """Return an existing TMDB genre or create it."""

        genre = self.get_by_tmdb_id(tmdb_id)

        if genre is not None:
            return genre

        genre = Genre(
            tmdb_id=tmdb_id,
            name=name,
            slug=slugify(name),
        )

        return self.add(genre)