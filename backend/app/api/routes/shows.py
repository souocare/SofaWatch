from typing import Annotated

from app.schemas.tmdb_show import ShowDetailsResponse
from app.services.tmdb_show_details import TMDBShowDetailsService
from app.services.show_import import ShowImportService
from app.schemas.show import ShowResponse
from fastapi import APIRouter, Depends, HTTPException, Path, Query, status

from app.api.dependencies import get_show_details_service, get_show_import_service
from app.providers.tmdb.exceptions import (
    TMDBConfigurationError,
    TMDBNotFoundError,
    TMDBRequestError,
    TMDBResponseError,
)

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