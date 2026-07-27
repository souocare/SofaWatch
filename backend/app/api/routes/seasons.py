from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, HTTPException, Path, status

from app.api.dependencies import EpisodeServiceDependency
from app.schemas.episode import EpisodeResponse


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