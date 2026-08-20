from fastapi import APIRouter

from app.api.dependencies import (
    AdminUserDependency,
    ServerHealthServiceDependency,
)
from app.schemas.server import ServerHealthResponse


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