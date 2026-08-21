from pydantic import BaseModel, Field


class LoginRequest(BaseModel):
    """Credentials used to authenticate a SofaWatch user."""

    username: str = Field(
        min_length=1,
        max_length=32,
    )
    password: str = Field(
        min_length=1,
    )


class AccessTokenResponse(BaseModel):
    """Short-lived access token returned after successful authentication."""

    access_token: str
    token_type: str = "bearer"
    expires_in: int


class SetupStatusResponse(BaseModel):
    """Public bootstrap state of the SofaWatch installation."""

    setup_required: bool

class InitialSetupRequest(BaseModel):
    """Credentials used to create the first SofaWatch administrator."""

    username: str = Field(
        min_length=3,
        max_length=32,
        pattern=r"^[a-zA-Z0-9._-]+$",
    )

    display_name: str = Field(
        min_length=1,
        max_length=100,
    )

    password: str = Field(
        min_length=8,
        max_length=128,
    )

    email: str | None = Field(
        default=None,
        max_length=320,
    )