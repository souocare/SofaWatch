from fastapi import APIRouter

from app.api.dependencies import CurrentUserDependency
from app.schemas.user import CurrentUserResponse


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