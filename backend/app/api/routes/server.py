from typing import Annotated

from fastapi import APIRouter, Query

from app.api.dependencies import (
    AdminUserDependency,
    ServerHealthServiceDependency,
    ServerLogsServiceDependency,
)
from app.schemas.server import (
    ServerHealthResponse,
    ServerLogLevel,
    ServerLogsResponse,
)


router = APIRouter(
    prefix="/server",
    tags=["server"],
)


@router.get(
    "/health",
    response_model=ServerHealthResponse,
    summary="Get Server health",
    description=(
        "Return administrative SofaWatch Server health information, "
        "including database and TMDB connectivity."
    ),
)
def get_server_health(
    admin_user: AdminUserDependency,
    service: ServerHealthServiceDependency,
) -> ServerHealthResponse:
    """Return detailed operational health for administrators."""

    del admin_user

    return service.get_health()


@router.get(
    "/logs",
    response_model=ServerLogsResponse,
    summary="Get Server logs",
    description=(
        "Return recent safe SofaWatch Server logs for administrators."
    ),
)
def get_server_logs(
    admin_user: AdminUserDependency,
    service: ServerLogsServiceDependency,
    level: Annotated[
        ServerLogLevel | None,
        Query(
            description="Optional log level filter.",
        ),
    ] = None,
    offset: Annotated[
        int,
        Query(
            ge=0,
        ),
    ] = 0,
    limit: Annotated[
        int,
        Query(
            ge=1,
            le=200,
        ),
    ] = 50,
) -> ServerLogsResponse:
    """Return paginated administrative Server logs."""

    del admin_user

    return service.list_logs(
        level=level,
        offset=offset,
        limit=limit,
    )