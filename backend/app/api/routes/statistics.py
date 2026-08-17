from fastapi import APIRouter

from app.api.dependencies import (
    CurrentUserDependency,
    StatisticsServiceDependency,
)
from app.schemas.statistics import WeeklyStatisticsResponse


router = APIRouter(
    prefix="/statistics",
    tags=["Statistics"],
)


@router.get(
    "/weekly",
    response_model=WeeklyStatisticsResponse,
    summary="Get weekly viewing statistics",
    description=(
        "Return the current user's viewing summary for the current "
        "Monday-to-Sunday calendar week."
    ),
)
def get_weekly_statistics(
    current_user: CurrentUserDependency,
    service: StatisticsServiceDependency,
) -> WeeklyStatisticsResponse:
    """Return the current user's current-week viewing summary."""

    return service.get_weekly_summary(
        user_id=current_user.id,
    )