from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, HTTPException, Path, status

from app.api.dependencies import EpisodeServiceDependency
from app.schemas.episode import EpisodeResponse


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