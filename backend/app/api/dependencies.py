from typing import Annotated

from fastapi import Depends

from app.db.dependencies import DatabaseSession
from app.repositories import GenreRepository
from app.services import GenreService


def get_genre_service(
    session: DatabaseSession,
) -> GenreService:
    """Provide a genre service for a single request."""

    repository = GenreRepository(session)

    return GenreService(repository)


GenreServiceDependency = Annotated[
    GenreService,
    Depends(get_genre_service),
]