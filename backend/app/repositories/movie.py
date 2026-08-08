from __future__ import annotations

from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.models.movie import Movie


class MovieRepository:
    """Data access operations for locally stored movies."""

    def __init__(self, session: Session) -> None:
        self._session = session

    def get_by_id(
        self,
        movie_id: UUID,
    ) -> Movie | None:
        """Return a locally stored movie by its internal UUID."""

        statement = select(Movie).options(selectinload(Movie.genres)).where(Movie.id == movie_id)

        return self._session.scalar(statement)

    def get_by_tmdb_id(
        self,
        tmdb_id: int,
    ) -> Movie | None:
        """Return a locally stored movie by its TMDB identifier."""

        statement = (
            select(Movie).options(selectinload(Movie.genres)).where(Movie.tmdb_id == tmdb_id)
        )

        return self._session.scalar(statement)

    def exists_by_tmdb_id(
        self,
        tmdb_id: int,
    ) -> bool:
        """Return whether a movie with the given TMDB ID exists."""

        statement = select(Movie.id).where(Movie.tmdb_id == tmdb_id).limit(1)

        return self._session.scalar(statement) is not None

    def add(
        self,
        movie: Movie,
    ) -> Movie:
        """Add a movie to the current database session."""

        self._session.add(movie)
        self._session.flush()

        return movie

    def list_all(self) -> list[Movie]:
        """Return all locally stored movies."""

        statement = select(Movie).options(selectinload(Movie.genres)).order_by(Movie.id)

        return list(self._session.scalars(statement).all())
