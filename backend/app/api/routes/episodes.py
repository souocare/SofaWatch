from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, HTTPException, Path, status

from app.api.dependencies import (
    CurrentUserDependency,
    EpisodeProgressServiceDependency,
    EpisodeServiceDependency,
)
from app.schemas.episode import EpisodeResponse
from app.schemas.episode_progress import (
    EpisodeProgressResponse,
    EpisodeWatchedRequest,
)


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
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="TV episode not found.",
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

    progress = service.mark_watched(
        user_id=current_user.id,
        episode_id=episode_id,
        watched_at=payload.watched_at,
    )

    if progress is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="TV episode not found.",
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
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="TV episode not found.",
        )

    return progress