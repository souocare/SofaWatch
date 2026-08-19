from typing import Annotated

from fastapi import APIRouter, Query

from app.api.dependencies import (
    CurrentUserDependency,
    StatisticsServiceDependency,
)
from app.schemas.statistics import (
    StatisticsActivityPeriod,
    StatisticsActivityResponse,
    StatisticsContentInsightsResponse,
    StatisticsHabitsResponse,
    StatisticsSummaryResponse,
    WeeklyStatisticsResponse,
    StatisticsLibraryResponse,
    StatisticsBacklogResponse,
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
    "/habits",
    response_model=StatisticsHabitsResponse,
    summary="Get viewing habits",
    description=(
        "Return the current user's all-time viewing habits, including "
        "current and longest watching streaks."
    ),
)
def get_statistics_habits(
    current_user: CurrentUserDependency,
    service: StatisticsServiceDependency,
) -> StatisticsHabitsResponse:
    """Return all-time viewing habits for the current user."""

    return service.get_habits(
        user_id=current_user.id,
    )


@router.get(
    "/content-insights",
    response_model=StatisticsContentInsightsResponse,
    summary="Get content insights",
    description=(
        "Return the current user's ranked all-time content insights, "
        "including most watched and rewatched content and top genres."
    ),
)
def get_statistics_content_insights(
    current_user: CurrentUserDependency,
    service: StatisticsServiceDependency,
) -> StatisticsContentInsightsResponse:
    """Return ranked all-time content insights for the current user."""

    return service.get_content_insights(
        user_id=current_user.id,
    )


@router.get(
    "/library",
    response_model=StatisticsLibraryResponse,
    summary="Get Library statistics",
    description=(
        "Return the current user's Library statistics, including "
        "Shows added, Movies added and completed Shows."
    ),
)
def get_statistics_library(
    current_user: CurrentUserDependency,
    service: StatisticsServiceDependency,
) -> StatisticsLibraryResponse:
    """Return current Library statistics for the current user."""

    return service.get_library_statistics(
        user_id=current_user.id,
    )

@router.get(
    "/backlog",
    response_model=StatisticsBacklogResponse,
    summary="Get backlog statistics",
    description=(
        "Return the current user's backlog and future viewing statistics, "
        "including unwatched aired Episodes, Planned Movies, future known "
        "watch time, recent catch-up speed and backlog trend."
    ),
)
def get_statistics_backlog(
    current_user: CurrentUserDependency,
    service: StatisticsServiceDependency,
) -> StatisticsBacklogResponse:
    """Return backlog statistics for the current user."""

    return service.get_backlog_statistics(
        user_id=current_user.id,
    )

@router.get(
    "/activity",
    response_model=StatisticsActivityResponse,
    summary="Get viewing activity",
    description=(
        "Return the current user's daily viewing activity for the "
        "selected time period, including today."
    ),
)
def get_statistics_activity(
    current_user: CurrentUserDependency,
    service: StatisticsServiceDependency,
    period: Annotated[
        StatisticsActivityPeriod,
        Query(
            alias="range",
            description="Viewing activity time period.",
            examples=["7d", "14d", "30d", "90d", "1y", "all"],
        ),
    ] = StatisticsActivityPeriod.DAYS_7,
) -> StatisticsActivityResponse:
    """Return daily viewing activity for the selected period."""

    return service.get_activity(
        user_id=current_user.id,
        period=period,
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