from typing import Annotated

from fastapi import APIRouter, Depends, Path, Query, status

from app.api.dependencies import (
    get_movie_details_service,
    get_movie_import_service,
)
from app.core.exceptions import APIError
from app.providers.tmdb.exceptions import (
    TMDBConfigurationError,
    TMDBNotFoundError,
    TMDBRequestError,
    TMDBResponseError,
)
from app.schemas.movie import MovieResponse
from app.schemas.tmdb_movie import MovieDetailsResponse
from app.services.movie_import import MovieImportService
from app.services.tmdb_movie_details import TMDBMovieDetailsService

router = APIRouter(
    prefix="/movies",
    tags=["Movies"],
)


@router.get(
    "/tmdb/{tmdb_id}",
    response_model=MovieDetailsResponse,
    summary="Get movie details",
    description="Retrieve detailed information about a movie from TMDB.",
)
def get_movie_details(
    service: Annotated[
        TMDBMovieDetailsService,
        Depends(get_movie_details_service),
    ],
    tmdb_id: Annotated[
        int,
        Path(
            ge=1,
            description="TMDB movie identifier.",
            examples=[438631],
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
) -> MovieDetailsResponse:
    """Get detailed information about a movie."""

    try:
        return service.get_details(
            tmdb_id=tmdb_id,
            language=language,
        )

    except TMDBNotFoundError as error:
        raise APIError(
            status_code=status.HTTP_404_NOT_FOUND,
            code="tmdb_not_found",
            message="The requested movie was not found.",
        ) from error

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


@router.post(
    "/import/tmdb/{tmdb_id}",
    response_model=MovieResponse,
    summary="Import movie",
    description=(
        "Ensure a movie from TMDB exists in the local database and return the locally stored movie."
    ),
    status_code=status.HTTP_200_OK,
)
def import_movie(
    service: Annotated[
        MovieImportService,
        Depends(get_movie_import_service),
    ],
    tmdb_id: Annotated[
        int,
        Path(
            ge=1,
            description="TMDB movie identifier.",
            examples=[438631],
        ),
    ],
    language: Annotated[
        str | None,
        Query(
            min_length=2,
            max_length=10,
            description=("Language used when importing TMDB metadata."),
            examples=[
                "en-US",
                "pt-PT",
            ],
        ),
    ] = None,
    force_refresh: Annotated[
        bool,
        Query(
            description=(
                "Force a metadata refresh even when the locally "
                "stored metadata is still considered recent."
            ),
        ),
    ] = False,
) -> MovieResponse:
    """Import a movie from TMDB into the local database."""

    try:
        return service.import_movie(
            tmdb_id=tmdb_id,
            language=language,
            force_refresh=force_refresh,
        )

    except TMDBNotFoundError as error:
        raise APIError(
            status_code=status.HTTP_404_NOT_FOUND,
            code="tmdb_not_found",
            message="The requested movie was not found.",
        ) from error

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
