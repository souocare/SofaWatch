from fastapi import APIRouter

from app.api.dependencies import (
    AdminUserDependency,
    AuthenticationSettingsServiceDependency,
)
from app.schemas.security import (
    SecuritySettingsResponse,
    SecuritySettingsUpdateRequest,
)

router = APIRouter(
    prefix="/security",
    tags=["security"],
)


@router.get(
    "",
    response_model=SecuritySettingsResponse,
    summary="Get Security settings",
    description=(
        "Return administrative SofaWatch Security settings. "
        "Only administrators may access this configuration."
    ),
)
def get_security_settings(
    admin_user: AdminUserDependency,
    service: AuthenticationSettingsServiceDependency,
) -> SecuritySettingsResponse:
    """Return global Security settings for administrators."""

    del admin_user

    settings = service.get()

    return SecuritySettingsResponse(
        open_registration=settings.open_registration,
    )


@router.patch(
    "",
    response_model=SecuritySettingsResponse,
    summary="Update Security settings",
    description=(
        "Update administrative SofaWatch Security settings. "
        "Only administrators may modify this configuration."
    ),
)
def update_security_settings(
    payload: SecuritySettingsUpdateRequest,
    admin_user: AdminUserDependency,
    service: AuthenticationSettingsServiceDependency,
) -> SecuritySettingsResponse:
    """Update global Security settings."""

    del admin_user

    settings = service.set_open_registration(
        enabled=payload.open_registration,
    )

    return SecuritySettingsResponse(
        open_registration=settings.open_registration,
    )
