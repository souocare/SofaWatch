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

class MobileRefreshRequest(BaseModel):
    """Persistent credential used to renew Mobile authentication."""

    refresh_token: str = Field(
        min_length=1,
    )

class AuthHandoffResponse(BaseModel):
    """Short-lived credential used to authenticate SofaWatch Web."""

    handoff_token: str
    expires_in: int


class AuthHandoffExchangeRequest(BaseModel):
    """One-time Mobile-to-Web authentication handoff credential."""

    handoff_token: str = Field(
        min_length=1,
    )

class AccessTokenResponse(BaseModel):
    """Short-lived access token returned after successful authentication."""

    access_token: str
    token_type: str = "bearer"
    expires_in: int

class MobileAuthenticationResponse(AccessTokenResponse):
    """Authentication credentials returned to a native Mobile client."""

    refresh_token: str

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

class RegistrationStatusResponse(BaseModel):
    """Public account-registration availability."""

    open_registration: bool


class RegistrationRequest(BaseModel):
    """Credentials used to create a regular SofaWatch account."""

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

class PasswordRecoveryCompleteRequest(BaseModel):
    """Credentials required to complete password recovery."""

    token: str = Field(
        min_length=1,
        max_length=256,
    )

    new_password: str = Field(
        min_length=8,
        max_length=128,
    )