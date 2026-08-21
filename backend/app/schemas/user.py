from uuid import UUID

from pydantic import BaseModel, ConfigDict


class CurrentUserResponse(BaseModel):
    """Public information about the current SofaWatch user."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    username: str | None
    email: str | None
    display_name: str
    is_active: bool
    is_local: bool
    is_admin: bool