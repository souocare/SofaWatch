from app.core.exceptions import APIError
from fastapi import APIRouter
from typing import Annotated

from fastapi import APIRouter, Query, status
from app.api.dependencies import (
    CurrentUserDependency,
    StatisticsServiceDependency,
)
from app.schemas.statistics import (
    StatisticsActivityResponse,
    StatisticsSummaryResponse,
    WeeklyStatisticsResponse,
)


router = APIRouter(
    prefix="/statistics",
    tags=["Statistics"],
)


@router.get(
    "/summary",
    response_model=StatisticsSummaryResponse,
    summary="Get viewing statistics summary",
    description=(
        "Return the current user's lifetime viewing summary, including "
        "Shows, Movies, Episodes and total known watch time."
    ),
)
def get_statistics_summary(
    current_user: CurrentUserDependency,
    service: StatisticsServiceDependency,
) -> StatisticsSummaryResponse:
    """Return the current user's lifetime viewing summary."""

    return service.get_summary(
        user_id=current_user.id,
    )


@router.get(
    "/activity",
    response_model=StatisticsActivityResponse,
    summary="Get recent viewing activity",
    description=(
        "Return the current user's daily viewing activity for the "
        "previous 7 or 14 calendar days, including today."
    ),
)
def get_statistics_activity(
    current_user: CurrentUserDependency,
    service: StatisticsServiceDependency,
    days: Annotated[
        int,
        Query(
            description="Number of recent calendar days to return.",
            examples=[7, 14],
        ),
    ] = 7,
) -> StatisticsActivityResponse:
    """Return recent daily viewing activity."""

    if days not in {
        7,
        14,
    }:
        raise APIError(
            status_code=status.HTTP_400_BAD_REQUEST,
            code="invalid_statistics_activity_range",
            message="Statistics activity supports only 7 or 14 days.",
        )

    return service.get_activity(
        user_id=current_user.id,
        days=days,
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