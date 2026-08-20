from uuid import UUID

from pydantic import BaseModel, ConfigDict


class CurrentUserResponse(BaseModel):
    """Public information about the current SofaWatch user."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    display_name: str
    is_local: bool
    is_admin: bool