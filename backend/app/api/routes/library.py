from typing import Annotated
from uuid import UUID

from fastapi import (
    APIRouter,
    Path,
    Query,
    status,
)
from app.core.exceptions import APIError

from app.api.dependencies import (
    CurrentUserDependency,
    LibraryServiceDependency,
)
from app.models.enums import LibraryStatus
from app.schemas.library import (
    LibraryEntryResponse,
    LibraryStatusUpdate,
)

router = APIRouter(
    prefix="/library",
    tags=["Library"],
)


@router.post(
    "/shows/{show_id}",
    response_model=LibraryEntryResponse,
    status_code=status.HTTP_200_OK,
    summary="Add TV series to library",
    description="Add a locally stored TV series to the current user's library.",
)
def add_show_to_library(
    show_id: Annotated[
        UUID,
        Path(
            description="Internal TV series identifier.",
        ),
    ],
    service: LibraryServiceDependency,
    current_user: CurrentUserDependency,
) -> LibraryEntryResponse:
    """Add a TV series to the current user's personal library."""

    entry = service.add_show(
        user_id=current_user.id,
        show_id=show_id,
    )

    if entry is None:
        raise APIError(
            status_code=status.HTTP_404_NOT_FOUND,
            code="show_not_found",
            message="TV series not found.",
        )

    return entry




@router.delete(
    "/shows/{show_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Remove TV series from library",
    description="Remove a TV series from the current user's library.",
)
def remove_show_from_library(
    show_id: Annotated[
        UUID,
        Path(
            description="Internal TV series identifier.",
        ),
    ],
    service: LibraryServiceDependency,
    current_user: CurrentUserDependency,
) -> None:
    """Remove a TV series from the current user's personal library."""

    removed = service.remove_show(
        user_id=current_user.id,
        show_id=show_id,
    )

    if not removed:
        raise APIError(
            status_code=status.HTTP_404_NOT_FOUND,
            code="library_entry_not_found",
            message="TV series is not in the library.",
        )


@router.patch(
    "/shows/{show_id}/status",
    response_model=LibraryEntryResponse,
    summary="Update library tracking status",
    description="Update the tracking status of a TV series in the current user's library.",
)
def update_library_status(
    show_id: Annotated[
        UUID,
        Path(
            description="Internal TV series identifier.",
        ),
    ],
    payload: LibraryStatusUpdate,
    service: LibraryServiceDependency,
    current_user: CurrentUserDependency,
) -> LibraryEntryResponse:
    """Update the tracking status of a TV series in the library."""

    entry = service.update_status(
        user_id=current_user.id,
        show_id=show_id,
        status=payload.status,
    )

    if entry is None:
        raise APIError(
            status_code=status.HTTP_404_NOT_FOUND,
            code="library_entry_not_found",
            message="TV series is not in the library.",
        )

    return entry


@router.get(
    "",
    response_model=list[LibraryEntryResponse],
    summary="List library",
    description=(
        "Return the current user's personal TV library, optionally filtered by tracking status."
    ),
)
def list_library(
    current_user: CurrentUserDependency,
    service: LibraryServiceDependency,
    library_status: Annotated[
        LibraryStatus | None,
        Query(
            alias="status",
            description="Filter entries by tracking status.",
        ),
    ] = None,
) -> list[LibraryEntryResponse]:
    """Return the current user's personal TV library."""

    return service.list_for_user(
        current_user.id,
        status=library_status,
    )


@router.post(
    "/movies/{movie_id}",
    response_model=LibraryEntryResponse,
    status_code=status.HTTP_200_OK,
    summary="Add movie to library",
)
def add_movie_to_library(
    movie_id: UUID,
    current_user: CurrentUserDependency,
    service: LibraryServiceDependency,
) -> LibraryEntryResponse:
    """Ensure a locally stored Movie belongs to the user's library."""

    entry = service.add_movie(
        user_id=current_user.id,
        movie_id=movie_id,
        status=LibraryStatus.PLANNING,
    )

    if entry is None:
        raise APIError(
            status_code=status.HTTP_404_NOT_FOUND,
            code="movie_not_found",
            message="The requested movie was not found.",
        )

    return entry

@router.delete(
    "/movies/{movie_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Remove movie from library",
)
def remove_movie_from_library(
    movie_id: UUID,
    current_user: CurrentUserDependency,
    service: LibraryServiceDependency,
) -> None:
    """Remove a Movie from the user's library."""

    removed = service.remove_movie(
        user_id=current_user.id,
        movie_id=movie_id,
    )

    if not removed:
        raise APIError(
            status_code=status.HTTP_404_NOT_FOUND,
            code="library_entry_not_found",
            message="The movie is not in the user's library.",
        )