from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Path, status
from app.core.exceptions import APIError

from app.api.dependencies import (
    CurrentUserDependency,
    EpisodeProgressServiceDependency,
    EpisodeServiceDependency,
    EpisodeWatchEventServiceDependency,
)
from app.schemas.episode import EpisodeResponse
from app.schemas.episode_watch_event import EpisodeWatchEventResponse
from app.schemas.episode_progress import (
    EpisodeProgressResponse,
    EpisodeWatchedRequest,
)
from app.services.episode_progress import EpisodeNotWatchableError

router = APIRouter(
    prefix="/episodes",
    tags=["Episodes"],
)


@router.get(
    "/{episode_id}",
    response_model=EpisodeResponse,
    summary="Get a locally stored TV episode",
    description="Return detailed information about a locally stored TV episode.",
)
def get_episode(
    episode_id: Annotated[
        UUID,
        Path(
            description="Internal TV episode identifier.",
        ),
    ],
    service: EpisodeServiceDependency,
) -> EpisodeResponse:
    """Return a locally stored TV episode."""

    episode = service.get_by_id(
        episode_id,
    )

    if episode is None:
        raise APIError(
            status_code=status.HTTP_404_NOT_FOUND,
            code="episode_not_found",
            message="TV episode not found.",
        )

    return episode


@router.post(
    "/{episode_id}/watched",
    response_model=EpisodeProgressResponse,
    summary="Mark episode as watched",
    description="Mark a TV episode as watched for the current user.",
)
def mark_episode_watched(
    episode_id: Annotated[
        UUID,
        Path(
            description="Internal TV episode identifier.",
        ),
    ],
    payload: EpisodeWatchedRequest,
    service: EpisodeProgressServiceDependency,
    current_user: CurrentUserDependency,
) -> EpisodeProgressResponse:
    """Mark an episode as watched for the current user."""

    try:
        progress = service.mark_watched(
            user_id=current_user.id,
            episode_id=episode_id,
            watched_at=payload.watched_at,
        )
    except EpisodeNotWatchableError as error:
        raise APIError(
            status_code=status.HTTP_409_CONFLICT,
            code="episode_cannot_be_watched",
            message="TV episode cannot be marked as watched yet.",
        ) from error

    if progress is None:
        raise APIError(
            status_code=status.HTTP_404_NOT_FOUND,
            code="episode_not_found",
            message="TV episode not found.",
        )

    return progress


@router.delete(
    "/{episode_id}/watched",
    response_model=EpisodeProgressResponse,
    summary="Mark episode as not watched",
    description="Mark a TV episode as not watched for the current user.",
)
def mark_episode_unwatched(
    episode_id: Annotated[
        UUID,
        Path(
            description="Internal TV episode identifier.",
        ),
    ],
    service: EpisodeProgressServiceDependency,
    current_user: CurrentUserDependency,
) -> EpisodeProgressResponse:
    """Mark an episode as not watched for the current user."""

    progress = service.mark_unwatched(
        user_id=current_user.id,
        episode_id=episode_id,
    )

    if progress is None:
        raise APIError(
            status_code=status.HTTP_404_NOT_FOUND,
            code="episode_not_found",
            message="TV episode not found.",
        )

    return progress

@router.get(
    "/{episode_id}/watch-events",
    response_model=list[EpisodeWatchEventResponse],
    summary="List Episode watch events",
    description=(
        "Return every recorded viewing of an Episode for the current user, "
        "ordered from newest to oldest."
    ),
)
def list_episode_watch_events(
    episode_id: Annotated[
        UUID,
        Path(
            description="Internal TV episode identifier.",
        ),
    ],
    service: EpisodeWatchEventServiceDependency,
    current_user: CurrentUserDependency,
) -> list[EpisodeWatchEventResponse]:
    """Return the user's historical viewing events for an Episode."""

    return service.list_for_episode(
        user_id=current_user.id,
        episode_id=episode_id,
    )

@router.delete(
    "/{episode_id}/watch-events",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete all Episode watch events",
    description=(
        "Delete every historical viewing of an Episode for the current user "
        "and mark the Episode as not watched."
    ),
)
def delete_all_episode_watch_events(
    episode_id: Annotated[
        UUID,
        Path(
            description="Internal TV episode identifier.",
        ),
    ],
    service: EpisodeWatchEventServiceDependency,
    current_user: CurrentUserDependency,
) -> None:
    """Delete every historical viewing for an Episode."""

    service.delete_all(
        user_id=current_user.id,
        episode_id=episode_id,
    )

@router.delete(
    "/{episode_id}/watch-events/{event_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete Episode watch event",
    description=(
        "Delete one historical Episode viewing event and synchronize "
        "the Episode's current watched state."
    ),
)
def delete_episode_watch_event(
    episode_id: Annotated[
        UUID,
        Path(
            description="Internal TV episode identifier.",
        ),
    ],
    event_id: Annotated[
        UUID,
        Path(
            description="Watch event identifier.",
        ),
    ],
    service: EpisodeWatchEventServiceDependency,
    current_user: CurrentUserDependency,
) -> None:
    """Delete one historical viewing event."""

    deleted = service.delete(
        user_id=current_user.id,
        episode_id=episode_id,
        event_id=event_id,
    )

    if not deleted:
        raise APIError(
            status_code=status.HTTP_404_NOT_FOUND,
            code="episode_watch_event_not_found",
            message="Episode watch event not found.",
        )