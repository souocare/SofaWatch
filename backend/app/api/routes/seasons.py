from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Path, status
from app.core.exceptions import APIError

from app.api.dependencies import (
    CurrentUserDependency,
    EpisodeProgressServiceDependency,
    EpisodeServiceDependency,
    SeasonEpisodeSyncServiceDependency,
)
from app.schemas.episode import EpisodeResponse
from app.schemas.episode_progress import (
    EpisodeProgressResponse,
    EpisodeProgressWithWatchCountResponse,
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
        raise APIError(
            status_code=status.HTTP_404_NOT_FOUND,
            code="season_not_found",
            message="TV season not found.",
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
        raise APIError(
            status_code=status.HTTP_404_NOT_FOUND,
            code="season_not_found",
            message="TV season not found.",
        )

    return progress

@router.post(
    "/{season_id}/sync",
    response_model=list[EpisodeResponse],
    summary="Synchronize TV season episodes",
    description=(
        "Synchronize episode metadata for one locally stored TV season "
        "and return its locally stored episodes."
    ),
)
def sync_season_episodes(
    season_id: Annotated[
        UUID,
        Path(
            description="Internal TV season identifier.",
        ),
    ],
    service: SeasonEpisodeSyncServiceDependency,
) -> list[EpisodeResponse]:
    """Synchronize episodes for one locally stored TV season."""

    episodes = service.sync(
        season_id=season_id,
    )

    if episodes is None:
        raise APIError(
            status_code=status.HTTP_404_NOT_FOUND,
            code="season_not_found",
            message="TV season not found.",
        )

    return episodes

@router.get(
    "/{season_id}/episodes/progress",
    response_model=list[EpisodeProgressWithWatchCountResponse],
    summary="Get episode progress for season",
    description=(
        "Return the current user's viewing progress and historical watch "
        "counts for Episodes belonging to a Season."
    ),
)
def get_season_episode_progress(
    season_id: Annotated[
        UUID,
        Path(
            description="Internal TV season identifier.",
        ),
    ],
    service: EpisodeProgressServiceDependency,
    current_user: CurrentUserDependency,
) -> list[EpisodeProgressWithWatchCountResponse]:
    """Return Episode-level viewing progress for a Season."""

    progress = service.get_episode_progress_for_season(
        user_id=current_user.id,
        season_id=season_id,
    )

    if progress is None:
        raise APIError(
            status_code=status.HTTP_404_NOT_FOUND,
            code="season_not_found",
            message="TV season not found.",
        )

    return progress