from collections.abc import Generator
from typing import Annotated

from fastapi import Depends

from app.core.config import Settings, get_settings
from app.db.dependencies import DatabaseSession
from app.providers.tmdb import TMDBClient
from app.repositories import GenreRepository
from app.services import GenreService
from app.services.show_search import ShowSearchService


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


def get_tmdb_client(
    settings: Annotated[Settings, Depends(get_settings)],
) -> Generator[TMDBClient, None, None]:
    """Provide a TMDB client and close it after the request."""

    client = TMDBClient(settings=settings)

    try:
        yield client
    finally:
        client.close()


TMDBClientDependency = Annotated[
    TMDBClient,
    Depends(get_tmdb_client),
]


def get_show_search_service(
    settings: Annotated[Settings, Depends(get_settings)],
    tmdb_client: Annotated[TMDBClient, Depends(get_tmdb_client)],
) -> ShowSearchService:
    """Provide the TV series search service."""

    return ShowSearchService(
        settings=settings,
        tmdb_client=tmdb_client,
    )


ShowSearchServiceDependency = Annotated[
    ShowSearchService,
    Depends(get_show_search_service),
]
