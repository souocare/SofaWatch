from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.genre import Genre


class GenreRepository:
    def __init__(
        self,
        session: Session,
    ) -> None:
        self._session = session

    def list_all(
        self,
    ) -> list[Genre]:
        statement = select(Genre).order_by(
            Genre.name.asc(),
        )

        return list(
            self._session.scalars(
                statement,
            ).all()
        )

    def get_by_name(
        self,
        name: str,
    ) -> Genre | None:
        statement = select(Genre).where(
            Genre.name == name,
        )

        return self._session.scalar(
            statement,
        )

    def add(
        self,
        genre: Genre,
    ) -> Genre:
        self._session.add(
            genre,
        )

        self._session.flush()

        return genre

    def get_or_create(
        self,
        *,
        name: str,
    ) -> Genre:
        existing = self.get_by_name(
            name,
        )

        if existing is not None:
            return existing

        slug = name.strip().lower().replace(" ", "-")

        genre = Genre(
            name=name,
            slug=slug,
        )

        return self.add(
            genre,
        )
