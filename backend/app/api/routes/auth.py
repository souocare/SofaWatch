from fastapi import APIRouter, status

from app.api.dependencies import (
    AccessTokenServiceDependency,
    AuthenticationServiceDependency,
    InitialSetupServiceDependency,
    UserServiceDependency,
)
from app.core.exceptions import APIError
from app.schemas.auth import (
    AccessTokenResponse,
    InitialSetupRequest,
    LoginRequest,
    SetupStatusResponse,
)
from app.services.initial_setup import InitialSetupAlreadyCompletedError


router = APIRouter(
    prefix="/auth",
    tags=["authentication"],
)


@router.get(
    "/setup",
    response_model=SetupStatusResponse,
    summary="Get authentication setup status",
    description=(
        "Return whether this SofaWatch installation still requires "
        "creation of its first user account."
    ),
)
def get_setup_status(
    user_service: UserServiceDependency,
) -> SetupStatusResponse:
    """Return the public bootstrap state of the installation."""

    return SetupStatusResponse(
        setup_required=user_service.requires_initial_setup(),
    )


@router.post(
    "/setup",
    response_model=AccessTokenResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create initial administrator",
    description=(
        "Create the first SofaWatch account. "
        "The first account automatically becomes an administrator."
    ),
)
def create_initial_admin(
    payload: InitialSetupRequest,
    setup_service: InitialSetupServiceDependency,
    access_token_service: AccessTokenServiceDependency,
) -> AccessTokenResponse:
    """Create the first administrator and authenticate it."""

    try:
        user = setup_service.create_first_admin(
            username=payload.username,
            display_name=payload.display_name,
            password=payload.password,
            email=payload.email,
        )
    except InitialSetupAlreadyCompletedError as error:
        raise APIError(
            status_code=status.HTTP_409_CONFLICT,
            code="initial_setup_completed",
            message="Initial SofaWatch setup has already been completed.",
        ) from error

    access_token = access_token_service.create(
        user_id=user.id,
    )

    return AccessTokenResponse(
        access_token=access_token,
        expires_in=int(
            access_token_service.expiration.total_seconds(),
        ),
    )


@router.post(
    "/login",
    response_model=AccessTokenResponse,
    summary="Authenticate user",
    description=(
        "Authenticate a SofaWatch user using local credentials "
        "and return a short-lived access token."
    ),
)
def login(
    credentials: LoginRequest,
    authentication_service: AuthenticationServiceDependency,
    access_token_service: AccessTokenServiceDependency,
) -> AccessTokenResponse:
    """Authenticate a user and issue a short-lived access token."""

    user = authentication_service.authenticate(
        username=credentials.username,
        password=credentials.password,
    )

    if user is None:
        raise APIError(
            status_code=status.HTTP_401_UNAUTHORIZED,
            code="invalid_credentials",
            message="The username or password is incorrect.",
        )

    access_token = access_token_service.create(
        user_id=user.id,
    )

    return AccessTokenResponse(
        access_token=access_token,
        expires_in=int(
            access_token_service.expiration.total_seconds(),
        ),
    )