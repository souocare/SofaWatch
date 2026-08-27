from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, Path, Query, status

from app.api.dependencies import (
    CurrentUserDependency,
    EpisodeProgressServiceDependency,
    SeasonServiceDependency,
    ShowImportServiceDependency,
    ShowRepositoryDependency,
    get_show_details_service,
    get_show_import_service,
)
from app.api.params.show import (
    ShowListParams,
    get_show_list_params,
)
from app.core.exceptions import APIError
from app.providers.tmdb.exceptions import (
    TMDBConfigurationError,
    TMDBNotFoundError,
    TMDBRequestError,
    TMDBResponseError,
)
from app.schemas.pagination import PaginatedResponse
from app.schemas.progress import (
    NextEpisodeResponse,
    NextUpcomingEpisodeResponse,
    SeasonProgressResponse,
    ShowProgressResponse,
)
from app.schemas.season import SeasonResponse
from app.schemas.show import ShowResponse, ShowSummaryResponse
from app.schemas.tmdb_show import ShowDetailsResponse
from app.services.show_import import ShowImportService
from app.services.tmdb_show_details import TMDBShowDetailsService

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
        raise APIError(
            status_code=status.HTTP_404_NOT_FOUND,
            code="tmdb_not_found",
            message="The requested TV series was not found.",
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
    response_model=ShowResponse,
    summary="Import TV series",
    description=(
        "Ensure a TV series from TMDB exists in the local database "
        "and return the locally stored series."
    ),
    status_code=status.HTTP_200_OK,
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
        raise APIError(
            status_code=status.HTTP_404_NOT_FOUND,
            code="tmdb_not_found",
            message="The requested TV series was not found.",
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
        raise APIError(
            status_code=status.HTTP_404_NOT_FOUND,
            code="show_not_found",
            message="TV series not found.",
        )

    return show


@router.get(
    "/{show_id}/seasons",
    response_model=list[SeasonResponse],
    summary="List TV series seasons",
    description="Return the locally stored seasons for a TV series.",
)
def list_show_seasons(
    show_id: Annotated[
        UUID,
        Path(
            description="Internal TV series identifier.",
        ),
    ],
    service: SeasonServiceDependency,
) -> list[SeasonResponse]:
    """Return the locally stored seasons for a TV series."""

    seasons = service.list_for_show(show_id)

    if seasons is None:
        raise APIError(
            status_code=status.HTTP_404_NOT_FOUND,
            code="show_not_found",
            message="TV series not found.",
        )

    return seasons


@router.get(
    "/{show_id}/progress",
    response_model=ShowProgressResponse,
    summary="Get TV series viewing progress",
    description="Return viewing progress for a TV series for the current user.",
)
def get_show_progress(
    show_id: Annotated[
        UUID,
        Path(
            description="Internal TV series identifier.",
        ),
    ],
    service: EpisodeProgressServiceDependency,
    current_user: CurrentUserDependency,
) -> ShowProgressResponse:
    """Return viewing progress for a TV series."""

    progress = service.get_show_progress(
        user_id=current_user.id,
        show_id=show_id,
    )

    if progress is None:
        raise APIError(
            status_code=status.HTTP_404_NOT_FOUND,
            code="show_not_found",
            message="TV series not found.",
        )

    return progress


@router.get(
    "/{show_id}/next-episode",
    response_model=NextEpisodeResponse,
    summary="Get next episode",
    description=("Return the next aired unwatched regular episode for the current user."),
)
def get_next_episode(
    show_id: Annotated[
        UUID,
        Path(
            description="Internal TV series identifier.",
        ),
    ],
    service: EpisodeProgressServiceDependency,
    current_user: CurrentUserDependency,
) -> NextEpisodeResponse:
    """Return the next unwatched episode of a TV series."""

    result = service.get_next_episode(
        user_id=current_user.id,
        show_id=show_id,
    )

    if result is None:
        raise APIError(
            status_code=status.HTTP_404_NOT_FOUND,
            code="show_not_found",
            message="TV series not found.",
        )

    return result


@router.get(
    "/{show_id}/next-upcoming",
    response_model=NextUpcomingEpisodeResponse,
    summary="Get next upcoming episode",
    description=("Return the next known future regular episode of a TV series."),
)
def get_next_upcoming_episode(
    show_id: Annotated[
        UUID,
        Path(
            description="Internal TV series identifier.",
        ),
    ],
    service: EpisodeProgressServiceDependency,
) -> NextUpcomingEpisodeResponse:
    """Return the next future regular episode of a TV series."""

    result = service.get_next_upcoming_episode(
        show_id=show_id,
    )

    if result is None:
        raise APIError(
            status_code=status.HTTP_404_NOT_FOUND,
            code="show_not_found",
            message="TV series not found.",
        )

    return result


@router.post(
    "/{show_id}/refresh",
    response_model=ShowResponse,
    summary="Refresh TV series metadata",
    description=("Force a metadata refresh for a locally stored TV series using TMDB."),
)
def refresh_show(
    show_id: Annotated[
        UUID,
        Path(
            description="Internal TV series identifier.",
        ),
    ],
    repository: ShowRepositoryDependency,
    service: ShowImportServiceDependency,
    language: Annotated[
        str | None,
        Query(
            min_length=2,
            max_length=10,
            description="Language used when refreshing TMDB metadata.",
            examples=["en-US", "pt-PT"],
        ),
    ] = None,
) -> ShowResponse:
    """Force a metadata refresh for a locally stored TV series."""

    show = repository.get_by_id(
        show_id,
    )

    if show is None:
        raise APIError(
            status_code=status.HTTP_404_NOT_FOUND,
            code="show_not_found",
            message="TV series not found.",
        )

    try:
        return service.refresh_show(
            tmdb_id=show.tmdb_id,
            language=language,
        )

    except TMDBNotFoundError as error:
        raise APIError(
            status_code=status.HTTP_404_NOT_FOUND,
            code="tmdb_not_found",
            message="The requested TV series was not found.",
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


@router.get(
    "/{show_id}/seasons/progress",
    response_model=list[SeasonProgressResponse],
    summary="Get TV series season progress",
    description=(
        "Return viewing progress for every locally stored season "
        "of a TV series for the current user."
    ),
)
def get_show_seasons_progress(
    show_id: Annotated[
        UUID,
        Path(
            description="Internal TV series identifier.",
        ),
    ],
    service: EpisodeProgressServiceDependency,
    current_user: CurrentUserDependency,
) -> list[SeasonProgressResponse]:
    """Return viewing progress for all seasons of a TV series."""

    progress = service.get_show_seasons_progress(
        user_id=current_user.id,
        show_id=show_id,
    )

    if progress is None:
        raise APIError(
            status_code=status.HTTP_404_NOT_FOUND,
            code="show_not_found",
            message="TV series not found.",
        )

    return progress
