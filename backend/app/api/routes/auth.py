from typing import Annotated

from fastapi import APIRouter, Depends, Request, Response, status

from app.api.dependencies import (
    AccessTokenServiceDependency,
    AuthenticationServiceDependency,
    AuthHandoffServiceDependency,
    AuthSessionServiceDependency,
    CurrentUserDependency,
    InitialSetupServiceDependency,
    UserServiceDependency,
    AuthenticationSettingsServiceDependency,
    RegistrationServiceDependency,
    PasswordRecoveryServiceDependency,
)
from app.core.exceptions import APIError
from app.schemas.auth import (
    AccessTokenResponse,
    AuthHandoffExchangeRequest,
    AuthHandoffResponse,
    InitialSetupRequest,
    LoginRequest,
    MobileAuthenticationResponse,
    MobileRefreshRequest,
    SetupStatusResponse,
    RegistrationRequest,
    RegistrationStatusResponse,
    PasswordRecoveryCompleteRequest,
)
from app.services.initial_setup import InitialSetupAlreadyCompletedError
from app.core.config import Settings, get_settings
from app.models.auth_session import AuthSessionType
from app.services.registration import (
    EmailAlreadyExistsError,
    RegistrationClosedError,
    UsernameAlreadyExistsError,
)
from app.services.password_recovery import (
    PasswordRecoveryInvalidError,
)

router = APIRouter(
    prefix="/auth",
    tags=["authentication"],
)


_SESSION_COOKIE_NAME = "sofawatch_session"
_SECONDS_PER_DAY = 24 * 60 * 60


def _set_web_session_cookie(
    *,
    response: Response,
    credential: str,
    settings: Settings,
) -> None:
    """Store the persistent Web session credential in an HttpOnly cookie."""

    response.set_cookie(
        key=_SESSION_COOKIE_NAME,
        value=credential,
        max_age=(
            settings.session_idle_expire_days
            * _SECONDS_PER_DAY
        ),
        httponly=True,
        secure=settings.is_production,
        samesite="lax",
        path="/",
    )


def _clear_web_session_cookie(
    *,
    response: Response,
    settings: Settings,
) -> None:
    """Remove the persistent Web session cookie."""

    response.delete_cookie(
        key=_SESSION_COOKIE_NAME,
        httponly=True,
        secure=settings.is_production,
        samesite="lax",
        path="/",
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
    response: Response,
    setup_service: InitialSetupServiceDependency,
    access_token_service: AccessTokenServiceDependency,
    auth_session_service: AuthSessionServiceDependency,
    settings: Annotated[
        Settings,
        Depends(get_settings),
    ],
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

    auth_session = auth_session_service.create(
        user_id=user.id,
        session_type=AuthSessionType.WEB,
    )

    _set_web_session_cookie(
        response=response,
        credential=auth_session.credential,
        settings=settings,
    )

    return AccessTokenResponse(
        access_token=access_token,
        expires_in=int(
            access_token_service.expiration.total_seconds(),
        ),
    )


@router.get(
    "/registration",
    response_model=RegistrationStatusResponse,
    summary="Get registration availability",
    description=(
        "Return whether this SofaWatch installation currently allows "
        "public account registration."
    ),
)
def get_registration_status(
    authentication_settings_service: AuthenticationSettingsServiceDependency,
) -> RegistrationStatusResponse:
    """Return whether public account registration is enabled."""

    settings = authentication_settings_service.get()

    return RegistrationStatusResponse(
        open_registration=settings.open_registration,
    )

@router.post(
    "/register",
    response_model=AccessTokenResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Register user",
    description=(
        "Create a regular SofaWatch account when public registration "
        "is enabled and authenticate the new user."
    ),
)
def register(
    payload: RegistrationRequest,
    response: Response,
    registration_service: RegistrationServiceDependency,
    access_token_service: AccessTokenServiceDependency,
    auth_session_service: AuthSessionServiceDependency,
    settings: Annotated[
        Settings,
        Depends(get_settings),
    ],
) -> AccessTokenResponse:
    """Register and authenticate a regular SofaWatch user."""

    try:
        user = registration_service.register(
            username=payload.username,
            display_name=payload.display_name,
            password=payload.password,
            email=payload.email,
        )
    except RegistrationClosedError as error:
        raise APIError(
            status_code=status.HTTP_403_FORBIDDEN,
            code="registration_closed",
            message="Account registration is currently closed.",
        ) from error
    except UsernameAlreadyExistsError as error:
        raise APIError(
            status_code=status.HTTP_409_CONFLICT,
            code="username_already_exists",
            message="That username is already in use.",
        ) from error
    except EmailAlreadyExistsError as error:
        raise APIError(
            status_code=status.HTTP_409_CONFLICT,
            code="email_already_exists",
            message="That email address is already in use.",
        ) from error

    auth_session = auth_session_service.create(
        user_id=user.id,
        session_type=AuthSessionType.WEB,
    )

    _set_web_session_cookie(
        response=response,
        credential=auth_session.credential,
        settings=settings,
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


@router.post(
    "/password-recovery/complete",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Complete password recovery",
    description=(
        "Set a new password using a valid short-lived one-time "
        "password recovery credential."
    ),
)
def complete_password_recovery(
    payload: PasswordRecoveryCompleteRequest,
    password_recovery_service: PasswordRecoveryServiceDependency,
) -> None:
    """Complete password recovery and invalidate existing sessions."""

    try:
        password_recovery_service.complete(
            credential=payload.token,
            new_password=payload.new_password,
        )
    except PasswordRecoveryInvalidError as error:
        raise APIError(
            status_code=status.HTTP_400_BAD_REQUEST,
            code="password_recovery_invalid",
            message=(
                "This password recovery link is invalid or has expired."
            ),
        ) from error


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
    response: Response,
    authentication_service: AuthenticationServiceDependency,
    access_token_service: AccessTokenServiceDependency,
    auth_session_service: AuthSessionServiceDependency,
    settings: Annotated[
        Settings,
        Depends(get_settings),
    ],
) -> AccessTokenResponse:
    """Authenticate a user and issue a short-lived access token."""

    user = authentication_service.authenticate(
        identifier=credentials.username,
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

    auth_session = auth_session_service.create(
        user_id=user.id,
        session_type=AuthSessionType.WEB,
    )

    _set_web_session_cookie(
        response=response,
        credential=auth_session.credential,
        settings=settings,
    )

    return AccessTokenResponse(
        access_token=access_token,
        expires_in=int(
            access_token_service.expiration.total_seconds(),
        ),
    )

@router.post(
    "/mobile/login",
    response_model=MobileAuthenticationResponse,
    summary="Authenticate Mobile user",
    description=(
        "Authenticate a SofaWatch user for a native Mobile client "
        "and create a persistent refresh session."
    ),
)
def mobile_login(
    credentials: LoginRequest,
    authentication_service: AuthenticationServiceDependency,
    access_token_service: AccessTokenServiceDependency,
    auth_session_service: AuthSessionServiceDependency,
) -> MobileAuthenticationResponse:
    """Authenticate a native client and create its persistent session."""

    user = authentication_service.authenticate(
        identifier=credentials.username,
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

    auth_session = auth_session_service.create(
        user_id=user.id,
        session_type=AuthSessionType.MOBILE,
    )

    return MobileAuthenticationResponse(
        access_token=access_token,
        expires_in=int(
            access_token_service.expiration.total_seconds(),
        ),
        refresh_token=auth_session.credential,
    )


@router.post(
    "/mobile/logout",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Log out current Mobile session",
    description=(
        "Revoke the persistent SofaWatch Mobile session represented "
        "by the supplied refresh credential."
    ),
)
def mobile_logout(
    payload: MobileRefreshRequest,
    auth_session_service: AuthSessionServiceDependency,
) -> None:
    """Revoke the current Mobile authentication session."""

    auth_session_service.revoke_by_credential(
        payload.refresh_token,
    )


@router.post(
    "/handoff",
    response_model=AuthHandoffResponse,
    summary="Create authentication handoff",
    description=(
        "Create a short-lived one-time credential that allows an "
        "authenticated SofaWatch client to open SofaWatch Web without "
        "exposing its persistent authentication credentials."
    ),
)
def create_auth_handoff(
    current_user: CurrentUserDependency,
    auth_handoff_service: AuthHandoffServiceDependency,
) -> AuthHandoffResponse:
    """Create a short-lived authentication handoff for the current user."""

    created = auth_handoff_service.create(
        user_id=current_user.id,
    )

    return AuthHandoffResponse(
        handoff_token=created.credential,
        expires_in=int(
            auth_handoff_service.expiration.total_seconds(),
        ),
    )


@router.post(
    "/handoff/exchange",
    response_model=AccessTokenResponse,
    summary="Exchange authentication handoff",
    description=(
        "Consume a short-lived one-time authentication handoff and "
        "create an authenticated SofaWatch Web session."
    ),
)
def exchange_auth_handoff(
    payload: AuthHandoffExchangeRequest,
    response: Response,
    auth_handoff_service: AuthHandoffServiceDependency,
    user_service: UserServiceDependency,
    access_token_service: AccessTokenServiceDependency,
    auth_session_service: AuthSessionServiceDependency,
    settings: Annotated[
        Settings,
        Depends(get_settings),
    ],
) -> AccessTokenResponse:
    """Consume a handoff and create an authenticated Web session."""

    handoff = auth_handoff_service.consume(
        payload.handoff_token,
    )

    if handoff is None:
        raise APIError(
            status_code=status.HTTP_401_UNAUTHORIZED,
            code="invalid_auth_handoff",
            message="The authentication handoff is invalid or expired.",
        )

    user = user_service.get_by_id(
        handoff.user_id,
    )

    if user is None or not user.is_active:
        raise APIError(
            status_code=status.HTTP_401_UNAUTHORIZED,
            code="invalid_auth_handoff",
            message="The authentication handoff is invalid or expired.",
        )

    auth_session = auth_session_service.create(
        user_id=user.id,
        session_type=AuthSessionType.WEB,
    )

    _set_web_session_cookie(
        response=response,
        credential=auth_session.credential,
        settings=settings,
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

@router.post(
    "/refresh",
    response_model=MobileAuthenticationResponse,
    summary="Refresh Mobile authentication",
    description=(
        "Exchange a valid Mobile refresh credential for a new short-lived "
        "access token and a rotated refresh credential."
    ),
)
def refresh_mobile_authentication(
    payload: MobileRefreshRequest,
    auth_session_service: AuthSessionServiceDependency,
    user_service: UserServiceDependency,
    access_token_service: AccessTokenServiceDependency,
) -> MobileAuthenticationResponse:
    """Rotate a Mobile refresh credential and issue a new access token."""

    rotated_session = auth_session_service.rotate_mobile_credential(
        payload.refresh_token,
    )

    if rotated_session is None:
        raise APIError(
            status_code=status.HTTP_401_UNAUTHORIZED,
            code="invalid_refresh_token",
            message="The refresh token is invalid or expired.",
        )

    user = user_service.get_by_id(
        rotated_session.session.user_id,
    )

    if user is None or not user.is_active:
        auth_session_service.revoke(
            session_id=rotated_session.session.id,
        )

        raise APIError(
            status_code=status.HTTP_401_UNAUTHORIZED,
            code="invalid_refresh_token",
            message="The refresh token is invalid or expired.",
        )

    access_token = access_token_service.create(
        user_id=user.id,
    )

    return MobileAuthenticationResponse(
        access_token=access_token,
        expires_in=int(
            access_token_service.expiration.total_seconds(),
        ),
        refresh_token=rotated_session.credential,
    )


@router.post(
    "/session",
    response_model=AccessTokenResponse,
    summary="Restore authenticated Web session",
    description=(
        "Restore an authenticated SofaWatch Web session from the "
        "persistent HttpOnly session cookie and issue a new short-lived "
        "access token."
    ),
)
def restore_web_session(
    request: Request,
    auth_session_service: AuthSessionServiceDependency,
    user_service: UserServiceDependency,
    access_token_service: AccessTokenServiceDependency,
) -> AccessTokenResponse:
    """Restore a persistent Web session and issue a new access token."""

    credential = request.cookies.get(
        _SESSION_COOKIE_NAME,
    )

    if credential is None:
        raise APIError(
            status_code=status.HTTP_401_UNAUTHORIZED,
            code="session_required",
            message="An authenticated session is required.",
        )

    auth_session = auth_session_service.resolve(
        credential,
    )

    if (
        auth_session is None
        or auth_session.session_type != AuthSessionType.WEB
    ):
        raise APIError(
            status_code=status.HTTP_401_UNAUTHORIZED,
            code="invalid_session",
            message="The authentication session is invalid or expired.",
        )

    user = user_service.get_by_id(
        auth_session.user_id,
    )

    if user is None or not user.is_active:
        raise APIError(
            status_code=status.HTTP_401_UNAUTHORIZED,
            code="invalid_session",
            message="The authentication session is invalid or expired.",
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


@router.post(
    "/logout",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Log out current Web session",
    description=(
        "Revoke the current persistent SofaWatch Web session "
        "and remove its authentication cookie."
    ),
)
def logout(
    request: Request,
    response: Response,
    auth_session_service: AuthSessionServiceDependency,
    settings: Annotated[
        Settings,
        Depends(get_settings),
    ],
) -> None:
    """Revoke the current Web session and remove its cookie."""

    credential = request.cookies.get(
        _SESSION_COOKIE_NAME,
    )

    if credential is not None:
        auth_session_service.revoke_by_credential(
            credential,
        )

    _clear_web_session_cookie(
        response=response,
        settings=settings,
    )


@router.post(
    "/logout-all",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Log out all authenticated sessions",
    description=(
        "Revoke every persistent SofaWatch authentication session "
        "belonging to the current user and remove the current Web "
        "session cookie."
    ),
)
def logout_all(
    response: Response,
    current_user: CurrentUserDependency,
    auth_session_service: AuthSessionServiceDependency,
    settings: Annotated[
        Settings,
        Depends(get_settings),
    ],
) -> None:
    """Revoke every authentication session belonging to the current user."""

    auth_session_service.revoke_all_for_user(
        user_id=current_user.id,
    )

    _clear_web_session_cookie(
        response=response,
        settings=settings,
    )