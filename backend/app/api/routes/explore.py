from typing import Annotated

from fastapi import APIRouter, Query, status

from app.api.dependencies import ExploreServiceDependency
from app.core.exceptions import APIError
from app.providers.tmdb.exceptions import (
    TMDBConfigurationError,
    TMDBRequestError,
    TMDBResponseError,
)
from app.schemas.explore import (
    ExploreMediaCollection,
    ExploreTrendingResponse,
    ExploreTrendingWindow,
)

router = APIRouter(
    prefix="/explore",
    tags=["Explore"],
)


@router.get(
    "/trending",
    response_model=ExploreTrendingResponse,
    summary="Get trending Movies and TV series",
)
def get_trending(
    service: ExploreServiceDependency,
    window: ExploreTrendingWindow = ExploreTrendingWindow.WEEK,
    language: Annotated[
        str | None,
        Query(
            min_length=2,
            max_length=10,
        ),
    ] = None,
) -> ExploreTrendingResponse:
    """Return trending discovery content."""

    try:
        return service.get_trending(
            window=window,
            language=language,
        )

    except TMDBConfigurationError as error:
        raise APIError(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            code="tmdb_not_configured",
            message="The TMDB provider is not configured.",
        ) from error

    except TMDBRequestError as error:
        raise APIError(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            code="tmdb_unavailable",
            message="The TMDB service is currently unavailable.",
        ) from error

    except TMDBResponseError as error:
        raise APIError(
            status_code=status.HTTP_502_BAD_GATEWAY,
            code="tmdb_invalid_response",
            message="TMDB returned an invalid response.",
        ) from error


@router.get(
    "/popular/shows",
    response_model=ExploreMediaCollection,
    summary="Get popular TV series",
)
def get_popular_shows(
    service: ExploreServiceDependency,
    language: Annotated[
        str | None,
        Query(
            min_length=2,
            max_length=10,
        ),
    ] = None,
) -> ExploreMediaCollection:
    """Return popular TV series for Explore."""

    try:
        return service.get_popular_shows(
            language=language,
        )

    except TMDBConfigurationError as error:
        raise APIError(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            code="tmdb_not_configured",
            message="The TMDB provider is not configured.",
        ) from error

    except TMDBRequestError as error:
        raise APIError(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            code="tmdb_unavailable",
            message="The TMDB service is currently unavailable.",
        ) from error

    except TMDBResponseError as error:
        raise APIError(
            status_code=status.HTTP_502_BAD_GATEWAY,
            code="tmdb_invalid_response",
            message="TMDB returned an invalid response.",
        ) from error


@router.get(
    "/popular/movies",
    response_model=ExploreMediaCollection,
    summary="Get popular Movies",
)
def get_popular_movies(
    service: ExploreServiceDependency,
    language: Annotated[
        str | None,
        Query(
            min_length=2,
            max_length=10,
        ),
    ] = None,
) -> ExploreMediaCollection:
    """Return popular Movies for Explore."""

    try:
        return service.get_popular_movies(
            language=language,
        )

    except TMDBConfigurationError as error:
        raise APIError(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            code="tmdb_not_configured",
            message="The TMDB provider is not configured.",
        ) from error

    except TMDBRequestError as error:
        raise APIError(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            code="tmdb_unavailable",
            message="The TMDB service is currently unavailable.",
        ) from error

    except TMDBResponseError as error:
        raise APIError(
            status_code=status.HTTP_502_BAD_GATEWAY,
            code="tmdb_invalid_response",
            message="TMDB returned an invalid response.",
        ) from error

