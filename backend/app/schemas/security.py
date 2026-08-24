from pydantic import BaseModel


class SecuritySettingsResponse(BaseModel):
    """Administrative SofaWatch Security settings."""

    open_registration: bool


class SecuritySettingsUpdateRequest(BaseModel):
    """Mutable administrative SofaWatch Security settings."""

    open_registration: bool