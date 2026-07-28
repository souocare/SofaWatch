from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, HTTPException, Path, status

from app.schemas.episode import EpisodeResponse
from app.api.dependencies import (
    CurrentUserDependency,
    EpisodeProgressServiceDependency,
    EpisodeServiceDependency
)
from app.schemas.progress import SeasonProgressResponse


router = APIRouter(
    prefix="/seasons",
    tags=["Seasons"],
)


@router.get(
    "/{season_id}/episodes",
    response_model=list[EpisodeResponse],
    summary="List TV season episodes",
    description="Return the locally stored episodes for a TV season.",
)
def list_season_episodes(
    season_id: Annotated[
        UUID,
        Path(
            description="Internal TV season identifier.",
        ),
    ],
    service: EpisodeServiceDependency,
) -> list[EpisodeResponse]:
    """Return the locally stored episodes for a TV season."""

    episodes = service.list_for_season(season_id)

    if episodes is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="TV season not found.",
        )

    return episodes


@router.get(
    "/{season_id}/progress",
    response_model=SeasonProgressResponse,
    summary="Get season viewing progress",
    description="Return viewing progress for a TV season for the current user.",
)
def get_season_progress(
    season_id: Annotated[
        UUID,
        Path(
            description="Internal TV season identifier.",
        ),
    ],
    service: EpisodeProgressServiceDependency,
    current_user: CurrentUserDependency,
) -> SeasonProgressResponse:
    """Return viewing progress for a TV season."""

    progress = service.get_season_progress(
        user_id=current_user.id,
        season_id=season_id,
    )

    if progress is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="TV season not found.",
        )

    return progress