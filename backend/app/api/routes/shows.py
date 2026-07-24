from typing import Annotated
from uuid import UUID
from fastapi import APIRouter, HTTPException, status

from app.schemas.tmdb_show import ShowDetailsResponse
from app.services.tmdb_show_details import TMDBShowDetailsService
from app.services.show_import import ShowImportService
from app.schemas.show import ShowResponse
from app.schemas.pagination import PaginatedResponse
from fastapi import APIRouter, Depends, HTTPException, Path, Query, status

from app.api.dependencies import ShowRepositoryDependency, get_show_details_service, get_show_import_service
from app.providers.tmdb.exceptions import (
    TMDBConfigurationError,
    TMDBNotFoundError,
    TMDBRequestError,
    TMDBResponseError,
)

from app.api.dependencies import get_show_repository
from app.repositories.show import ShowRepository
from app.schemas.show import ShowSummaryResponse
from app.api.params.show import (
    ShowListParams,
    get_show_list_params,
)

from app.api.dependencies import ShowRepositoryDependency
from app.schemas.show import ShowResponse



router = APIRouter(
    prefix="/shows",
    tags=["Shows"],
)


@router.get(
    "/tmdb/{tmdb_id}",
    response_model=ShowDetailsResponse,
    summary="Get TV series details",
    description="Retrieve detailed information about a TV series from TMDB.",
)
def get_show_details(
    service: Annotated[
        TMDBShowDetailsService,
        Depends(get_show_details_service),
    ],
    tmdb_id: Annotated[
        int,
        Path(
            ge=1,
            description="TMDB TV series identifier.",
            examples=[95396],
        ),
    ],
    language: Annotated[
        str | None,
        Query(
            min_length=2,
            max_length=10,
            description="TMDB response language.",
            examples=["en-US", "pt-PT"],
        ),
    ] = None,
) -> ShowDetailsResponse:
    """Get detailed information about a TV series."""

    try:
        return service.get_details(
            tmdb_id=tmdb_id,
            language=language,
        )

    except TMDBNotFoundError as error:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="The requested TV series was not found.",
        ) from error

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


@router.post(
    "/import/tmdb/{tmdb_id}",
    response_model=ShowResponse,
    summary="Import TV series",
    description="Import a TV series from TMDB into the local database.",
    status_code=status.HTTP_201_CREATED,
)
def import_show(
    service: Annotated[
        ShowImportService,
        Depends(get_show_import_service),
    ],
    tmdb_id: Annotated[
        int,
        Path(
            ge=1,
            description="TMDB TV series identifier.",
            examples=[95396],
        ),
    ],
    language: Annotated[
        str | None,
        Query(
            min_length=2,
            max_length=10,
            description="Language used when importing TMDB metadata.",
            examples=["en-US", "pt-PT"],
        ),
    ] = None,
    force_refresh: Annotated[
        bool,
        Query(
            description=(
                "Force a metadata refresh even when the locally stored "
                "metadata is still considered recent."
            ),
        ),
    ] = False,
) -> ShowResponse:
    """Import a TV series from TMDB into the local database."""

    try:
        return service.import_show(
            tmdb_id=tmdb_id,
            language=language,
            force_refresh=force_refresh,
        )

    except TMDBNotFoundError as error:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="The requested TV series was not found.",
        ) from error

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
    

@router.get(
    "",
    response_model=PaginatedResponse[ShowSummaryResponse],
    summary="List locally stored TV series",
    description=(
        "Return locally stored TV series with pagination, ordering, "
        "title search, genre filtering, and status filtering."
    ),
)
def list_shows(
    repository: ShowRepositoryDependency,
    params: Annotated[
        ShowListParams,
        Depends(get_show_list_params),
    ],
) -> PaginatedResponse[ShowSummaryResponse]:
    """Return a paginated list of locally stored TV series."""

    items = repository.list(
        offset=params.offset,
        limit=params.limit,
        sort_by=params.sort_by,
        sort_direction=params.sort_direction,
        query=params.query,
        genre=params.genre,
        status=params.status,
    )

    total = repository.count(
        query=params.query,
        genre=params.genre,
        status=params.status,
    )

    return PaginatedResponse(
        items=items,
        total=total,
        offset=params.offset,
        limit=params.limit,
        has_next=params.offset + len(items) < total,
    )

@router.get(
    "/{show_id}",
    response_model=ShowResponse,
    summary="Get a locally stored TV series",
)
def get_show(
    show_id: Annotated[
        UUID,
        Path(
            description="Internal TV series identifier.",
        ),
    ],
    repository: ShowRepositoryDependency,
) -> ShowResponse:
    """Return a locally stored TV series by its internal identifier."""

    show = repository.get_by_id(show_id)

    if show is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="TV series not found.",
        )

    return show