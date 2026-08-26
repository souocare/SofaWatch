from uuid import UUID

from fastapi import APIRouter, Response, status

from app.api.dependencies import (
    CurrentUserDependency,
    DataExportServiceDependency,
    DataImportServiceDependency,
    UserServiceDependency,
    AdminUserDependency,
    PasswordResetTokenServiceDependency,
)
from app.schemas.data_export import SofaWatchExportResponse
from app.schemas.data_import import (
    DataImportPreviewResponse,
    DataImportResultResponse,
)
from app.schemas.user import (
    CurrentUserPasswordUpdateRequest,
    CurrentUserResponse,
    CurrentUserUpdateRequest,
    PasswordRecoveryResponse,
    AdminUserResponse,
)
from app.services.user import (
    CurrentPasswordInvalidError,
    PasswordUnavailableError,
)
from app.core.exceptions import APIError



router = APIRouter(
    prefix="/users",
    tags=["users"],
)


@router.get(
    "/me",
    response_model=CurrentUserResponse,
    summary="Get current user",
    description="Return the current SofaWatch user.",
)
def get_current_user_profile(
    current_user: CurrentUserDependency,
) -> CurrentUserResponse:
    """Return the user represented by the current request context."""

    return CurrentUserResponse.model_validate(current_user)




@router.patch(
    "/me",
    response_model=CurrentUserResponse,
    summary="Update current user",
    description=(
        "Update mutable profile information belonging to the "
        "current SofaWatch user."
    ),
)
def update_current_user_profile(
    payload: CurrentUserUpdateRequest,
    current_user: CurrentUserDependency,
    service: UserServiceDependency,
) -> CurrentUserResponse:
    """Update the current SofaWatch user's profile."""

    user = service.update_display_name(
        user=current_user,
        display_name=payload.display_name,
    )

    return CurrentUserResponse.model_validate(user)

@router.put(
    "/me/password",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Change current user password",
    description=(
        "Change the authenticated SofaWatch user's password after "
        "verifying the current password."
    ),
)
def change_current_user_password(
    payload: CurrentUserPasswordUpdateRequest,
    current_user: CurrentUserDependency,
    service: UserServiceDependency,
) -> None:
    """Change the authenticated user's password."""

    try:
        service.update_password(
            user=current_user,
            current_password=payload.current_password,
            new_password=payload.new_password,
        )
    except CurrentPasswordInvalidError as error:
        raise APIError(
            status_code=status.HTTP_400_BAD_REQUEST,
            code="current_password_invalid",
            message="The current password is incorrect.",
        ) from error
    except PasswordUnavailableError as error:
        raise APIError(
            status_code=status.HTTP_400_BAD_REQUEST,
            code="password_change_unavailable",
            message="Password change is not available for this account.",
        ) from error


@router.get(
    "",
    response_model=list[AdminUserResponse],
    summary="List users",
    description=(
        "Return SofaWatch user accounts for administrative management. "
        "Only administrators may access this operation."
    ),
)
def list_users(
    admin_user: AdminUserDependency,
    user_service: UserServiceDependency,
) -> list[AdminUserResponse]:
    """Return safe administrative information about SofaWatch users."""

    del admin_user

    users = user_service.list_users()

    return [
        AdminUserResponse.model_validate(user)
        for user in users
    ]


@router.post(
    "/{user_id}/password-recovery",
    response_model=PasswordRecoveryResponse,
    summary="Start user password recovery",
    description=(
        "Create a short-lived one-time password recovery credential "
        "for a regular SofaWatch user. Only administrators may perform "
        "this operation."
    ),
)
def start_user_password_recovery(
    user_id: UUID,
    admin_user: AdminUserDependency,
    user_service: UserServiceDependency,
    password_reset_service: PasswordResetTokenServiceDependency,
) -> PasswordRecoveryResponse:
    """Create a temporary password recovery credential for a user."""

    del admin_user

    user = user_service.get_by_id(
        user_id,
    )

    if user is None:
        raise APIError(
            status_code=status.HTTP_404_NOT_FOUND,
            code="user_not_found",
            message="The requested user could not be found.",
        )

    if user.is_admin:
        raise APIError(
            status_code=status.HTTP_400_BAD_REQUEST,
            code="administrator_password_recovery_unavailable",
            message=(
                "Administrator password recovery must be performed "
                "through the server recovery flow."
            ),
        )

    if not user.is_active:
        raise APIError(
            status_code=status.HTTP_400_BAD_REQUEST,
            code="inactive_user_password_recovery_unavailable",
            message=(
                "Password recovery is not available for an inactive account."
            ),
        )

    created = password_reset_service.create(
        user_id=user.id,
    )

    return PasswordRecoveryResponse(
        token=created.credential,
        expires_at=created.reset_token.expires_at,
    )



@router.get(
    "/me/export",
    summary="Export current user data",
    description=(
        "Download a portable versioned SofaWatch export containing "
        "the current user's Library and viewing History."
    ),
    responses={
        200: {
            "content": {
                "application/json": {},
            },
            "description": "Portable SofaWatch user data export.",
        },
    },
)
def export_current_user_data(
    current_user: CurrentUserDependency,
    service: DataExportServiceDependency,
) -> Response:
    """Download the current user's portable SofaWatch data export."""

    export = service.export_user_data(
        user=current_user,
    )

    filename = (
        "sofawatch-export-"
        f"{export.exported_at.strftime('%Y-%m-%d-%H%M%S')}"
        ".json"
    )

    return Response(
        content=export.model_dump_json(
            indent=2,
        ),
        media_type="application/json",
        headers={
            "Content-Disposition": (
                f'attachment; filename="{filename}"'
            ),
        },
    )

@router.post(
    "/me/import/preview",
    response_model=DataImportPreviewResponse,
    summary="Preview current user data import",
    description=(
        "Validate a versioned SofaWatch export and return a read-only "
        "summary of the data that would be imported."
    ),
)
def preview_current_user_data_import(
    current_user: CurrentUserDependency,
    service: DataImportServiceDependency,
    export: SofaWatchExportResponse,
) -> DataImportPreviewResponse:
    """Validate and preview a portable SofaWatch data import."""

    del current_user

    return service.preview(
        export=export,
    )

@router.post(
    "/me/import",
    response_model=DataImportResultResponse,
    summary="Import current user data",
    description=(
        "Import a validated versioned SofaWatch export into the current "
        "user's Library and viewing History."
    ),
)
def import_current_user_data(
    current_user: CurrentUserDependency,
    service: DataImportServiceDependency,
    export: SofaWatchExportResponse,
) -> DataImportResultResponse:
    """Import portable SofaWatch data for the current user."""

    return service.import_user_data(
        user_id=current_user.id,
        export=export,
    )