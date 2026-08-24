from fastapi import APIRouter, Response

from app.api.dependencies import (
    CurrentUserDependency,
    DataExportServiceDependency,
    DataImportServiceDependency,
    UserServiceDependency,
)
from app.schemas.data_export import SofaWatchExportResponse
from app.schemas.data_import import (
    DataImportPreviewResponse,
    DataImportResultResponse,
)
from app.schemas.user import (
    CurrentUserResponse,
    CurrentUserUpdateRequest,
)


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