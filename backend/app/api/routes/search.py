from typing import Annotated

from fastapi import APIRouter, Depends, Query, status

from app.api.dependencies import (
    get_media_search_service,
    get_show_search_service,
    CurrentUserDependency,
)
from app.core.exceptions import APIError
from app.providers.tmdb.exceptions import (
    TMDBConfigurationError,
    TMDBRequestError,
    TMDBResponseError,
)
from app.schemas.search import (
    SearchMediaTypeFilter,
    SearchResponse,
)
from app.schemas.tmdb_show import ShowSearchResponse
from app.services.media_search import MediaSearchService
from app.services.tmdb_show_search import ShowSearchService

router = APIRouter(
    prefix="/search",
    tags=["Search"],
)


@router.get(
    "",
    response_model=SearchResponse,
    summary="Search movies and TV series",
    description=(
        "Search for movies, TV series, or both using TMDB. "
        "Person results returned by TMDB multi-search are excluded."
    ),
)
def search_media(
    current_user: CurrentUserDependency,
    service: Annotated[
        MediaSearchService,
        Depends(get_media_search_service),
    ],
    query: Annotated[
        str,
        Query(
            min_length=1,
            max_length=200,
            description="Movie or TV series title to search for.",
            examples=["Dune", "Severance"],
        ),
    ],
    page: Annotated[
        int,
        Query(
            ge=1,
            description="Results page number.",
        ),
    ] = 1,
    language: Annotated[
        str | None,
        Query(
            min_length=2,
            max_length=10,
            description="TMDB response language.",
            examples=["en-US", "pt-PT"],
        ),
    ] = None,
    media_type: Annotated[
        SearchMediaTypeFilter,
        Query(
            description="Media type to include in the search.",
        ),
    ] = SearchMediaTypeFilter.ALL,
) -> SearchResponse:
    """Search movies and TV series."""

    try:
        return service.search(
            user_id=current_user.id,
            query=query,
            page=page,
            language=language,
            media_type=media_type,
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
    "/shows",
    response_model=ShowSearchResponse,
    summary="Search TV series",
    description="Search for TV series using TMDB.",
)
def search_shows(
    service: Annotated[
        ShowSearchService,
        Depends(get_show_search_service),
    ],
    query: Annotated[
        str,
        Query(
            min_length=1,
            max_length=200,
            description="TV series name to search for.",
            examples=["Severance"],
        ),
    ],
    page: Annotated[
        int,
        Query(
            ge=1,
            description="Results page number.",
        ),
    ] = 1,
    language: Annotated[
        str | None,
        Query(
            min_length=2,
            max_length=10,
            description="TMDB response language.",
            examples=["en-US", "pt-PT"],
        ),
    ] = None,
) -> ShowSearchResponse:
    """Search for TV series."""

    try:
        return service.search(
            query=query,
            page=page,
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
