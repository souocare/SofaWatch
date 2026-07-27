from collections.abc import Generator
from typing import Annotated

from app.services.episode import EpisodeService
from app.services.season import SeasonService
from fastapi import Depends

from app.core.config import Settings, get_settings
from app.db.dependencies import DatabaseSession
from app.providers.tmdb import TMDBClient
from app.repositories import GenreRepository
from app.services import GenreService
from app.services.tmdb_show_details import TMDBShowDetailsService
from app.services.tmdb_show_search import ShowSearchService
from app.repositories import (
    EpisodeRepository,
    GenreRepository,
    SeasonRepository,
    ShowRepository,
)
from app.services.show_import import ShowImportService
from app.repositories import (
    EpisodeRepository,
    GenreRepository,
    SeasonRepository,
    ShowRepository,
    UserRepository,
    LibraryRepository
)
from app.services.tmdb_season_details import TMDBSeasonDetailsService
from app.services import (
    EpisodeService,
    GenreService,
    SeasonService,
    UserService,
    LibraryService
)

from fastapi import Depends, HTTPException, status
from app.models.user import User

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


def get_show_details_service(
    settings: Annotated[Settings, Depends(get_settings)],
    tmdb_client: Annotated[TMDBClient, Depends(get_tmdb_client)],
) -> TMDBShowDetailsService:
    """Provide the TV series details service."""

    return TMDBShowDetailsService(
        settings=settings,
        tmdb_client=tmdb_client,
    )


TMDBShowDetailsServiceDependency = Annotated[
    TMDBShowDetailsService,
    Depends(get_show_details_service),
]


def get_tmdb_season_details_service(
    tmdb_client: Annotated[
        TMDBClient,
        Depends(get_tmdb_client),
    ],
) -> TMDBSeasonDetailsService:
    """Provide the TV season details service."""

    return TMDBSeasonDetailsService(
        tmdb_client=tmdb_client,
    )


TMDBSeasonDetailsServiceDependency = Annotated[
    TMDBSeasonDetailsService,
    Depends(get_tmdb_season_details_service),
]

def get_show_import_service(
    session: DatabaseSession,
    settings: Annotated[
        Settings,
        Depends(get_settings),
    ],
    show_details_service: Annotated[
        TMDBShowDetailsService,
        Depends(get_show_details_service),
    ],
    season_details_service: Annotated[
        TMDBSeasonDetailsService,
        Depends(get_tmdb_season_details_service),
    ],
) -> ShowImportService:
    """Provide the TV series import service."""

    return ShowImportService(
        session=session,
        settings=settings,
        show_repository=ShowRepository(session),
        genre_repository=GenreRepository(session),
        season_repository=SeasonRepository(session),
        episode_repository=EpisodeRepository(session),
        tmdb_show_details_service=show_details_service,
        tmdb_season_details_service=season_details_service,
    )


ShowImportServiceDependency = Annotated[
    ShowImportService,
    Depends(get_show_import_service),
]


def get_show_repository(
    session: DatabaseSession,
) -> ShowRepository:
    """Provide a show repository for a single request."""

    return ShowRepository(session)


ShowRepositoryDependency = Annotated[
    ShowRepository,
    Depends(get_show_repository),
]

def get_season_service(
    session: DatabaseSession,
) -> SeasonService:
    """Provide a season service for a single request."""

    return SeasonService(
        season_repository=SeasonRepository(session),
        show_repository=ShowRepository(session),
    )


SeasonServiceDependency = Annotated[
    SeasonService,
    Depends(get_season_service),
]


def get_episode_service(
    session: DatabaseSession,
) -> EpisodeService:
    """Provide an episode service for a single request."""

    return EpisodeService(
        episode_repository=EpisodeRepository(session),
        season_repository=SeasonRepository(session),
    )


EpisodeServiceDependency = Annotated[
    EpisodeService,
    Depends(get_episode_service),
]


def get_user_service(
    session: DatabaseSession,
) -> UserService:
    """Provide a user service for a single request."""

    return UserService(
        user_repository=UserRepository(session),
    )


UserServiceDependency = Annotated[
    UserService,
    Depends(get_user_service),
]

def get_current_user(
    user_service: UserServiceDependency,
) -> User:
    """Return the current SofaWatch user.

    The single local user acts as the current user until
    authentication and multi-user support are introduced.
    """

    user = user_service.get_local()

    if user is None:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Local user is not configured.",
        )

    return user


CurrentUserDependency = Annotated[
    User,
    Depends(get_current_user),
]

def get_library_service(
    session: DatabaseSession,
) -> LibraryService:
    """Provide a library service for a single request."""

    return LibraryService(
        session=session,
        library_repository=LibraryRepository(session),
        show_repository=ShowRepository(session),
    )


LibraryServiceDependency = Annotated[
    LibraryService,
    Depends(get_library_service),
]