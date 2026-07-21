from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Query, status

from app.api.dependencies import get_show_search_service
from app.providers.tmdb.exceptions import (
    TMDBConfigurationError,
    TMDBRequestError,
    TMDBResponseError,
)
from app.schemas.show import ShowSearchResponse
from app.services.show_search import ShowSearchService

router = APIRouter(
    prefix="/search",
    tags=["Search"],
)


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
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="The TMDB provider is not configured.",
        ) from error

    except TMDBRequestError as error:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="The TMDB service is currently unavailable.",
        ) from error

    except TMDBResponseError as error:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="TMDB returned an invalid response.",
        ) from error
