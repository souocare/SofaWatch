from uuid import UUID
from datetime import datetime
from pydantic import BaseModel, ConfigDict, Field, field_validator


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


class CurrentUserUpdateRequest(BaseModel):
    """Mutable profile information for the current SofaWatch user."""

    display_name: str = Field(
        min_length=1,
        max_length=100,
    )

    @field_validator("display_name")
    @classmethod
    def normalize_display_name(
        cls,
        value: str,
    ) -> str:
        """Normalize and reject blank display names."""

        normalized = value.strip()

        if not normalized:
            raise ValueError(
                "Display name must not be blank.",
            )

        return normalized


class CurrentUserPasswordUpdateRequest(BaseModel):
    """Credentials required to change the current user's password."""

    current_password: str = Field(
        min_length=1,
        max_length=128,
    )

    new_password: str = Field(
        min_length=8,
        max_length=128,
    )

class PasswordRecoveryResponse(BaseModel):
    """Temporary credential created by an administrator for password recovery."""

    token: str
    expires_at: datetime


class AdminUserResponse(BaseModel):
    """Safe administrative representation of a SofaWatch user."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    username: str | None
    email: str | None
    display_name: str
    is_active: bool
    is_local: bool
    is_admin: bool