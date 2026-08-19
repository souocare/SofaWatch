from datetime import date, datetime
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Path, Query, status

from app.api.dependencies import (
    CurrentUserDependency,
    HaventStartedServiceDependency,
    LibraryServiceDependency,
    MissedRecentlyServiceDependency,
    StaleWatchingServiceDependency,
    StartShowServiceDependency,
    UpcomingServiceDependency,
    WatchHistoryServiceDependency,
    WatchNextServiceDependency,
    MovieWatchEventServiceDependency,
)
from app.core.exceptions import APIError
from app.models.enums import LibraryStatus
from app.schemas.havent_started import HaventStartedShowResponse
from app.schemas.movie_watch_event import MovieWatchEventResponse
from app.schemas.library import (
    LibraryEntryResponse,
    LibraryMovieResponse,
    LibraryShowResponse,
    LibraryStatusUpdate,
    LibraryPreviewResponse,
)
from app.schemas.stale_watching import StaleWatchingShowResponse
from app.schemas.start_show import StartShowResponse
from app.schemas.upcoming import UpcomingItemResponse
from app.schemas.watch_history import WatchHistoryPageResponse
from app.schemas.watch_next import WatchNextShowResponse

router = APIRouter(
    prefix="/library",
    tags=["Library"],
)


@router.get(
    "/shows",
    response_model=list[LibraryShowResponse],
    summary="List TV series in library",
    description=(
        "Return TV series in the current user's personal library, "
        "optionally filtered by tracking status."
    ),
)
def list_library_shows(
    current_user: CurrentUserDependency,
    service: LibraryServiceDependency,
    library_status: Annotated[
        LibraryStatus | None,
        Query(
            alias="status",
            description="Filter TV series by tracking status.",
        ),
    ] = None,
) -> list[LibraryShowResponse]:
    """Return TV series in the current user's personal library."""

    return service.list_shows_for_user(
        current_user.id,
        status=library_status,
    )

@router.get(
    "/shows/havent-started",
    response_model=list[HaventStartedShowResponse],
    summary="List Haven't Started TV series",
    description=(
        "Return Planning TV series with their first aired regular Episode "
        "available to start."
    ),
)
def list_havent_started_shows(
    current_user: CurrentUserDependency,
    service: HaventStartedServiceDependency,
) -> list[HaventStartedShowResponse]:
    """Return the current user's Haven't Started collection."""

    return service.list_for_user(
        user_id=current_user.id,
    )


# @router.get(
#     "/shows/upcoming",
#     response_model=list[UpcomingItemResponse],
#     summary="List Upcoming TV episodes",
#     description=(
#         "Return known dated regular Episodes from eligible TV series "
#         "in the current user's Library, ordered chronologically."
#     ),
# )
# def list_upcoming_episodes(
#     current_user: CurrentUserDependency,
#     service: UpcomingServiceDependency,
# ) -> list[UpcomingItemResponse]:
#     """Return the current user's Upcoming Episode timeline."""

#     return service.list_for_user(
#         user_id=current_user.id,
#     )



@router.get(
    "/shows/upcoming",
    response_model=list[UpcomingItemResponse],
    summary="List Upcoming TV episodes",
    description=(
        "Return known dated regular Episodes from eligible TV series "
        "in the current user's Library, ordered chronologically."
    ),
)
def list_upcoming_episodes(
    current_user: CurrentUserDependency,
    service: UpcomingServiceDependency,
    from_date: Annotated[
        date | None,
        Query(
            description=(
                "Inclusive first air date to return. "
                "Defaults to today when omitted."
            ),
        ),
    ] = None,
    to_date: Annotated[
        date | None,
        Query(
            description="Inclusive last air date to return.",
        ),
    ] = None,
    limit: Annotated[
        int | None,
        Query(
            ge=1,
            le=100,
            description=(
                "Maximum number of Episodes to return. "
                "When omitted, the timeline is not explicitly limited."
            ),
        ),
    ] = None,
) -> list[UpcomingItemResponse]:
    """Return the current user's Upcoming Episode timeline."""

    if (
        from_date is not None
        and to_date is not None
        and from_date > to_date
    ):
        raise APIError(
            status_code=status.HTTP_400_BAD_REQUEST,
            code="invalid_upcoming_date_range",
            message="Upcoming date range is invalid.",
        )

    return service.list_for_user(
        user_id=current_user.id,
        from_date=from_date,
        to_date=to_date,
        limit=limit,
    )


@router.get(
    "/shows/missed-recently",
    response_model=list[UpcomingItemResponse],
    summary="List recently missed TV episodes",
    description=(
        "Return recent regular unwatched Episodes from TV series "
        "currently marked as Watching, excluding today."
    ),
)
def list_missed_recently_episodes(
    current_user: CurrentUserDependency,
    service: MissedRecentlyServiceDependency,
) -> list[UpcomingItemResponse]:
    """Return the Home Missed Recently collection."""

    return service.list_for_user(
        user_id=current_user.id,
    )


@router.get(
    "/shows/watch-next",
    response_model=list[WatchNextShowResponse],
    summary="List Watch Next TV series",
    description=(
        "Return the next aired unwatched regular Episode for each "
        "eligible TV series in the current user's Library."
    ),
)
def list_watch_next_shows(
    current_user: CurrentUserDependency,
    service: WatchNextServiceDependency,
    limit: Annotated[
        int | None,
        Query(
            ge=1,
            le=100,
            description=(
                "Maximum number of Watch Next items to return."
            ),
        ),
    ] = None,
) -> list[WatchNextShowResponse]:
    """Return the current user's Watch Next collection."""

    return service.list_for_user(
        user_id=current_user.id,
        limit=limit,
    )

@router.get(
    "/shows/stale-watching",
    response_model=list[StaleWatchingShowResponse],
    summary="List stale Watching TV series",
    description=(
        "Return Watching TV series whose most recent watched Episode "
        "was at least 60 days ago and that still have an aired "
        "unwatched Episode available."
    ),
)
def list_stale_watching_shows(
    current_user: CurrentUserDependency,
    service: StaleWatchingServiceDependency,
) -> list[StaleWatchingShowResponse]:
    """Return the current user's inactive Watching Shows."""

    return service.list_for_user(
        user_id=current_user.id,
    )


@router.get(
    "/shows/watch-history",
    response_model=WatchHistoryPageResponse,
    summary="List Watch History",
    description=(
        "Return recently watched regular TV Episodes for the current user, "
        "ordered from newest to oldest using cursor pagination."
    ),
)
def list_watch_history(
    current_user: CurrentUserDependency,
    service: WatchHistoryServiceDependency,
    limit: Annotated[
        int,
        Query(
            ge=1,
            le=100,
            description="Maximum number of Watch History entries to return.",
        ),
    ] = 30,
    cursor: Annotated[
        str | None,
        Query(
            description="Opaque cursor returned by the previous page.",
        ),
    ] = None,
) -> WatchHistoryPageResponse:
    """Return one cursor-paginated page of Watch History."""

    try:
        return service.list_for_user(
            user_id=current_user.id,
            limit=limit,
            cursor=cursor,
        )
    except ValueError as error:
        raise APIError(
            status_code=status.HTTP_400_BAD_REQUEST,
            code="invalid_watch_history_cursor",
            message="Invalid Watch History cursor.",
        ) from error


@router.get(
    "/preview",
    response_model=LibraryPreviewResponse,
    summary="Get Library preview",
    description=(
        "Return the most recently added Shows and Movies for the "
        "current user's Profile Library preview."
    ),
)
def get_library_preview(
    current_user: CurrentUserDependency,
    service: LibraryServiceDependency,
) -> LibraryPreviewResponse:
    """Return the compact Profile Library preview."""

    return service.get_preview_for_user(
        user_id=current_user.id,
        limit=10,
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

@router.get(
    "/shows/{show_id}",
    response_model=LibraryEntryResponse,
    summary="Get TV series library entry",
)
def get_show_library_entry(
    show_id: Annotated[
        UUID,
        Path(
            description="Internal TV series identifier.",
        ),
    ],
    service: LibraryServiceDependency,
    current_user: CurrentUserDependency,
) -> LibraryEntryResponse:
    """Return the current user's library entry for a TV series."""

    entry = service.get_show_entry(
        user_id=current_user.id,
        show_id=show_id,
    )

    if entry is None:
        raise APIError(
            status_code=status.HTTP_404_NOT_FOUND,
            code="library_entry_not_found",
            message="TV series is not in the library.",
        )

    return entry

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

@router.get(
    "/movies",
    response_model=list[LibraryMovieResponse],
    summary="List library movies",
    description=(
        "Return Movies in the current user's library, "
        "optionally filtered by tracking status."
    ),
)
def list_library_movies(
    current_user: CurrentUserDependency,
    service: LibraryServiceDependency,
    library_status: Annotated[
        LibraryStatus | None,
        Query(
            alias="status",
            description="Filter Movies by tracking status.",
        ),
    ] = None,
) -> list[LibraryMovieResponse]:
    """Return Movies belonging to the current user's library."""

    return service.list_movies_for_user(
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

@router.get(
    "/movies/{movie_id}",
    response_model=LibraryEntryResponse,
    summary="Get movie library entry",
)
def get_movie_library_entry(
    movie_id: UUID,
    current_user: CurrentUserDependency,
    service: LibraryServiceDependency,
) -> LibraryEntryResponse:
    """Return the current user's library entry for a Movie."""

    entry = service.get_movie_entry(
        user_id=current_user.id,
        movie_id=movie_id,
    )

    if entry is None:
        raise APIError(
            status_code=status.HTTP_404_NOT_FOUND,
            code="library_entry_not_found",
            message="The movie is not in the user's library.",
        )

    return entry


@router.patch(
    "/movies/{movie_id}/status",
    response_model=LibraryEntryResponse,
    summary="Update movie library status",
    description="Update the tracking status of a Movie in the current user's library.",
)
def update_movie_library_status(
    movie_id: UUID,
    payload: LibraryStatusUpdate,
    current_user: CurrentUserDependency,
    service: LibraryServiceDependency,
) -> LibraryEntryResponse:
    """Update the tracking status of a Movie in the library."""

    entry = service.update_movie_status(
        user_id=current_user.id,
        movie_id=movie_id,
        status=payload.status,
    )

    if entry is None:
        raise APIError(
            status_code=status.HTTP_404_NOT_FOUND,
            code="library_entry_not_found",
            message="The movie is not in the user's library.",
        )

    return entry


@router.post(
    "/movies/{movie_id}/watch-events",
    response_model=MovieWatchEventResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Record Movie viewing",
    description=(
        "Record one historical viewing of a Movie. "
        "Calling this for an already watched Movie represents a Rewatch."
    ),
)
def record_movie_watch_event(
    movie_id: UUID,
    current_user: CurrentUserDependency,
    service: MovieWatchEventServiceDependency,
) -> MovieWatchEventResponse:
    """Record a Movie watch or Rewatch."""

    event = service.watch(
        user_id=current_user.id,
        movie_id=movie_id,
    )

    if event is None:
        raise APIError(
            status_code=status.HTTP_404_NOT_FOUND,
            code="movie_not_available_for_watching",
            message="The requested movie cannot be watched.",
        )

    return event


@router.get(
    "/movies/{movie_id}/watch-events",
    response_model=list[MovieWatchEventResponse],
    summary="List Movie watch events",
    description=(
        "Return every recorded viewing of a Movie for the current user, "
        "ordered from newest to oldest."
    ),
)
def list_movie_watch_events(
    movie_id: UUID,
    current_user: CurrentUserDependency,
    service: MovieWatchEventServiceDependency,
) -> list[MovieWatchEventResponse]:
    """Return historical Movie viewings."""

    return service.list_for_movie(
        user_id=current_user.id,
        movie_id=movie_id,
    )


@router.delete(
    "/movies/{movie_id}/watch-events",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete all Movie watch events",
    description=(
        "Delete every historical viewing of a Movie and return it "
        "to the user's Watchlist."
    ),
)
def delete_all_movie_watch_events(
    movie_id: UUID,
    current_user: CurrentUserDependency,
    service: MovieWatchEventServiceDependency,
) -> None:
    """Delete every Movie viewing."""

    service.delete_all(
        user_id=current_user.id,
        movie_id=movie_id,
    )


@router.delete(
    "/movies/{movie_id}/watch-events/{event_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete Movie watch event",
    description=(
        "Delete one historical Movie viewing and synchronize "
        "the Movie's current Library state."
    ),
)
def delete_movie_watch_event(
    movie_id: UUID,
    event_id: UUID,
    current_user: CurrentUserDependency,
    service: MovieWatchEventServiceDependency,
) -> None:
    """Delete one historical Movie viewing."""

    deleted = service.delete(
        user_id=current_user.id,
        movie_id=movie_id,
        event_id=event_id,
    )

    if not deleted:
        raise APIError(
            status_code=status.HTTP_404_NOT_FOUND,
            code="movie_watch_event_not_found",
            message="Movie watch event not found.",
        )


@router.post(
    "/shows/{show_id}/start",
    response_model=StartShowResponse,
    status_code=status.HTTP_200_OK,
    summary="Start TV series",
    description=(
        "Start a TV series from the current user's Library by marking "
        "its first aired regular Episode as watched and changing the "
        "Library status to Watching."
    ),
)
def start_library_show(
    show_id: Annotated[
        UUID,
        Path(
            description="Internal TV series identifier.",
        ),
    ],
    service: StartShowServiceDependency,
    current_user: CurrentUserDependency,
) -> StartShowResponse:
    """Start a TV series from its first aired regular Episode."""

    result = service.start(
        user_id=current_user.id,
        show_id=show_id,
    )

    if result is None:
        raise APIError(
            status_code=status.HTTP_404_NOT_FOUND,
            code="show_cannot_be_started",
            message="TV series cannot be started.",
        )

    return result

