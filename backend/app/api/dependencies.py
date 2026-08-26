from collections.abc import Generator
from typing import Annotated

from app.repositories.genre_provider_mapping import GenreProviderMappingRepository
from app.services.genre_mapping import GenreMappingService
from fastapi import Depends, Request, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from app.core.exceptions import APIError

from app.core.config import Settings, get_settings
from app.db.dependencies import DatabaseSession
from app.jobs.executor import BackgroundJobExecutor
from app.models.user import User
from app.providers.tmdb import TMDBClient
from app.repositories import (
    EpisodeProgressRepository,
    EpisodeRepository,
    GenreRepository,
    LibraryRepository,
    SeasonRepository,
    ShowRepository,
    UserRepository,
    MovieRepository,
)
from app.repositories.authentication_settings import (
    AuthenticationSettingsRepository,
)
from app.repositories.background_job import BackgroundJobRepository
from app.repositories.network import NetworkRepository
from app.services import (
    EpisodeProgressService,
    EpisodeService,
    GenreService,
    LibraryService,
    SeasonService,
    UserService,
)
from app.services.authentication_settings import (
    AuthenticationSettingsService,
)
from app.services.show_import import ShowImportService
from app.services.tmdb_season_details import TMDBSeasonDetailsService
from app.services.tmdb_show_details import TMDBShowDetailsService
from app.services.tmdb_show_search import ShowSearchService
from app.services.tmdb_movie_details import TMDBMovieDetailsService
from app.services.media_search import MediaSearchService
from app.core.storage import ImageStorage
from app.services.image import ImageService
from app.services.image_cache import ImageCacheService
from app.repositories.movie import MovieRepository
from app.services.movie_import import MovieImportService
from app.services.tmdb_movie_details import (
    TMDBMovieDetailsService,
)
from app.services.explore import ExploreService
from app.services.season_episode_sync import SeasonEpisodeSyncService
from app.services.watch_next import WatchNextService
from app.services.stale_watching import StaleWatchingService
from app.services.watch_history import WatchHistoryService
from app.services.start_show import StartShowService
from app.repositories.episode_watch_event import EpisodeWatchEventRepository
from app.services.episode_watch_event import EpisodeWatchEventService
from app.services.havent_started import HaventStartedService
from app.services.upcoming import UpcomingService
from app.services.episode_details import EpisodeDetailsService
from app.repositories.movie_watch_event import MovieWatchEventRepository
from app.services.movie_watch_event import MovieWatchEventService
from app.services.statistics import StatisticsService
from app.services.missed_recently import MissedRecentlyService
from app.services.history import HistoryService
from app.services.server_health import ServerHealthService
from app.services.server_logs import ServerLogsService
from app.services.data_export import DataExportService
from app.services.data_import import DataImportService
from app.core.security.tokens import (
    AccessTokenService,
    InvalidAccessTokenError,
)
from app.services.authentication import AuthenticationService
from app.services.initial_setup import InitialSetupService
from app.repositories.auth_session import AuthSessionRepository
from app.services.auth_session import AuthSessionService
from app.models.auth_session import AuthSessionType
from app.repositories.auth_handoff import AuthHandoffRepository
from app.services.auth_handoff import AuthHandoffService
from app.repositories.authentication_settings import (
    AuthenticationSettingsRepository,
)
from app.services.authentication_settings import (
    AuthenticationSettingsService,
)
from app.services.registration import RegistrationService
from app.repositories.password_reset_token import (
    PasswordResetTokenRepository,
)
from app.services.password_reset_token import (
    PasswordResetTokenService,
)
from app.services.password_recovery import (
    PasswordRecoveryService,
)


def get_genre_service(
    session: DatabaseSession,
) -> GenreService:
    """Provide a genre service for a single request."""

    repository = GenreRepository(session)

    return GenreService(repository)


GenreServiceDependency = Annotated[
    GenreService,
    Depends(get_genre_service),
]


def get_tmdb_client(
    settings: Annotated[Settings, Depends(get_settings)],
) -> Generator[TMDBClient, None, None]:
    """Provide a TMDB client and close it after the request."""

    client = TMDBClient(settings=settings)

    try:
        yield client
    finally:
        client.close()


TMDBClientDependency = Annotated[
    TMDBClient,
    Depends(get_tmdb_client),
]


def get_media_search_service(
    session: DatabaseSession, # type: ignore
    settings: Annotated[
        Settings,
        Depends(get_settings),
    ],
    tmdb_client: Annotated[
        TMDBClient,
        Depends(get_tmdb_client),
    ],
) -> MediaSearchService:
    """Provide the general media search service."""

    return MediaSearchService(
        settings=settings,
        tmdb_client=tmdb_client,
        library_repository=LibraryRepository(
            session,
        ),
    )


MediaSearchServiceDependency = Annotated[
    MediaSearchService,
    Depends(get_media_search_service),
]


def get_show_search_service(
    settings: Annotated[Settings, Depends(get_settings)],
    tmdb_client: Annotated[TMDBClient, Depends(get_tmdb_client)],
) -> ShowSearchService:
    """Provide the TV series search service."""

    return ShowSearchService(
        settings=settings,
        tmdb_client=tmdb_client,
    )


ShowSearchServiceDependency = Annotated[
    ShowSearchService,
    Depends(get_show_search_service),
]


def get_show_details_service(
    settings: Annotated[Settings, Depends(get_settings)],
    tmdb_client: Annotated[TMDBClient, Depends(get_tmdb_client)],
) -> TMDBShowDetailsService:
    """Provide the TV series details service."""

    return TMDBShowDetailsService(
        settings=settings,
        tmdb_client=tmdb_client,
    )


TMDBShowDetailsServiceDependency = Annotated[
    TMDBShowDetailsService,
    Depends(get_show_details_service),
]


def get_tmdb_season_details_service(
    tmdb_client: Annotated[
        TMDBClient,
        Depends(get_tmdb_client),
    ],
) -> TMDBSeasonDetailsService:
    """Provide the TV season details service."""

    return TMDBSeasonDetailsService(
        tmdb_client=tmdb_client,
    )


TMDBSeasonDetailsServiceDependency = Annotated[
    TMDBSeasonDetailsService,
    Depends(get_tmdb_season_details_service),
]


def get_show_import_service(
    session: DatabaseSession,
    settings: Annotated[
        Settings,
        Depends(get_settings),
    ],
    show_details_service: Annotated[
        TMDBShowDetailsService,
        Depends(get_show_details_service),
    ],
    season_details_service: Annotated[
        TMDBSeasonDetailsService,
        Depends(get_tmdb_season_details_service),
    ],
) -> ShowImportService:
    """Provide the TV series import service."""

    genre_repository = GenreRepository(
        session,
    )

    return ShowImportService(
        session=session,
        settings=settings,
        show_repository=ShowRepository(session),
        genre_repository=genre_repository,
        network_repository=NetworkRepository(session),
        season_repository=SeasonRepository(session),
        episode_repository=EpisodeRepository(session),
        tmdb_show_details_service=show_details_service,
        tmdb_season_details_service=season_details_service,
    )


ShowImportServiceDependency = Annotated[
    ShowImportService,
    Depends(get_show_import_service),
]


def get_show_repository(
    session: DatabaseSession,
) -> ShowRepository:
    """Provide a show repository for a single request."""

    return ShowRepository(session)


ShowRepositoryDependency = Annotated[
    ShowRepository,
    Depends(get_show_repository),
]


def get_season_service(
    session: DatabaseSession,
) -> SeasonService:
    """Provide a season service for a single request."""

    return SeasonService(
        season_repository=SeasonRepository(session),
        show_repository=ShowRepository(session),
    )


SeasonServiceDependency = Annotated[
    SeasonService,
    Depends(get_season_service),
]


def get_episode_service(
    session: DatabaseSession,
) -> EpisodeService:
    """Provide an episode service for a single request."""

    return EpisodeService(
        episode_repository=EpisodeRepository(session),
        season_repository=SeasonRepository(session),
    )


EpisodeServiceDependency = Annotated[
    EpisodeService,
    Depends(get_episode_service),
]

def get_episode_details_service(
    session: DatabaseSession,
) -> EpisodeDetailsService:
    """Provide the Episode Details service for a single request."""

    return EpisodeDetailsService(
        episode_repository=EpisodeRepository(session),
        season_repository=SeasonRepository(session),
        show_repository=ShowRepository(session),
        progress_repository=EpisodeProgressRepository(session),
        watch_event_repository=EpisodeWatchEventRepository(session),
    )


EpisodeDetailsServiceDependency = Annotated[
    EpisodeDetailsService,
    Depends(get_episode_details_service),
]

def get_movie_details_service(
    settings: Annotated[
        Settings,
        Depends(get_settings),
    ],
    tmdb_client: Annotated[
        TMDBClient,
        Depends(get_tmdb_client),
    ],
) -> TMDBMovieDetailsService:
    """Provide the movie details service."""
    return TMDBMovieDetailsService(
        settings=settings,
        tmdb_client=tmdb_client,
    )


TMDBMovieDetailsServiceDependency = Annotated[
    TMDBMovieDetailsService,
    Depends(get_movie_details_service),
]


def get_movie_import_service(
    session: DatabaseSession,
    settings: Annotated[
        Settings,
        Depends(get_settings),
    ],
    movie_details_service: Annotated[
        TMDBMovieDetailsService,
        Depends(get_movie_details_service),
    ],
) -> MovieImportService:
    """Provide the movie import service."""

    return MovieImportService(
        session=session,
        settings=settings,
        movie_repository=MovieRepository(
            session,
        ),
        genre_repository=GenreRepository(
            session,
        ),
        tmdb_movie_details_service=movie_details_service,
    )


MovieImportServiceDependency = Annotated[
    MovieImportService,
    Depends(get_movie_import_service),
]



def get_movie_watch_event_service(
    session: DatabaseSession,
) -> MovieWatchEventService:
    """Provide historical Movie watch event operations."""

    return MovieWatchEventService(
        session=session,
        movie_repository=MovieRepository(session),
        library_repository=LibraryRepository(session),
        watch_event_repository=MovieWatchEventRepository(session),
    )


MovieWatchEventServiceDependency = Annotated[
    MovieWatchEventService,
    Depends(get_movie_watch_event_service),
]



def get_user_service(
    session: DatabaseSession,
) -> UserService:
    """Provide user operations for a single request."""

    return UserService(
        session=session,
        user_repository=UserRepository(session),
    )


UserServiceDependency = Annotated[
    UserService,
    Depends(get_user_service),
]


def get_authentication_service(
    session: DatabaseSession,
) -> AuthenticationService:
    """Provide an authentication service for a single request."""

    return AuthenticationService(
        user_repository=UserRepository(session),
    )


AuthenticationServiceDependency = Annotated[
    AuthenticationService,
    Depends(get_authentication_service),
]


def get_auth_session_service(
    session: DatabaseSession,
    settings: Annotated[
        Settings,
        Depends(get_settings),
    ],
) -> AuthSessionService:
    """Provide the persistent authentication session service."""

    return AuthSessionService(
        session=session,
        repository=AuthSessionRepository(session),
        idle_expire_days=settings.session_idle_expire_days,
    )


AuthSessionServiceDependency = Annotated[
    AuthSessionService,
    Depends(get_auth_session_service),
]

def get_auth_handoff_service(
    session: DatabaseSession,
) -> AuthHandoffService:
    """Provide the short-lived authentication handoff service."""

    return AuthHandoffService(
        session=session,
        repository=AuthHandoffRepository(session),
    )


AuthHandoffServiceDependency = Annotated[
    AuthHandoffService,
    Depends(get_auth_handoff_service),
]

def get_password_reset_token_service(
    session: DatabaseSession,
) -> PasswordResetTokenService:
    """Provide password reset token operations for a single request."""

    return PasswordResetTokenService(
        session=session,
        repository=PasswordResetTokenRepository(session),
    )


PasswordResetTokenServiceDependency = Annotated[
    PasswordResetTokenService,
    Depends(get_password_reset_token_service),
]


def get_password_recovery_service(
    session: DatabaseSession,
) -> PasswordRecoveryService:
    """Provide password recovery operations for a single request."""

    return PasswordRecoveryService(
        session=session,
        password_reset_token_repository=PasswordResetTokenRepository(
            session,
        ),
        user_repository=UserRepository(
            session,
        ),
        auth_session_repository=AuthSessionRepository(
            session,
        ),
    )


PasswordRecoveryServiceDependency = Annotated[
    PasswordRecoveryService,
    Depends(get_password_recovery_service),
]


def get_initial_setup_service(
    session: DatabaseSession,
) -> InitialSetupService:
    """Provide the initial authentication setup service."""

    return InitialSetupService(
        session=session,
        user_repository=UserRepository(session),
    )


InitialSetupServiceDependency = Annotated[
    InitialSetupService,
    Depends(get_initial_setup_service),
]


def get_access_token_service(
    settings: Annotated[
        Settings,
        Depends(get_settings),
    ],
) -> AccessTokenService:
    """Provide the SofaWatch access token service."""

    return AccessTokenService(
        secret_key=settings.secret_key.get_secret_value(),
        expire_minutes=settings.access_token_expire_minutes,
    )


AccessTokenServiceDependency = Annotated[
    AccessTokenService,
    Depends(get_access_token_service),
]

_bearer_scheme = HTTPBearer(
    auto_error=False,
)
_SESSION_COOKIE_NAME = "sofawatch_session"

def get_current_user(
    request: Request,
    user_service: UserServiceDependency,
    access_token_service: AccessTokenServiceDependency,
    auth_session_service: AuthSessionServiceDependency,
    credentials: Annotated[
        HTTPAuthorizationCredentials | None,
        Depends(_bearer_scheme),
    ],
) -> User:
    """Resolve the authenticated SofaWatch user for the current request.

    Bearer authentication takes precedence when explicitly supplied.
    Otherwise, Web clients may authenticate through their persistent
    HttpOnly session cookie.
    """

    if credentials is not None:
        return _resolve_bearer_user(
            credentials=credentials,
            user_service=user_service,
            access_token_service=access_token_service,
        )

    session_credential = request.cookies.get(
        _SESSION_COOKIE_NAME,
    )

    if session_credential is not None:
        return _resolve_web_session_user(
            session_credential=session_credential,
            user_service=user_service,
            auth_session_service=auth_session_service,
        )

    raise APIError(
        status_code=status.HTTP_401_UNAUTHORIZED,
        code="authentication_required",
        message="Authentication is required.",
    )


CurrentUserDependency = Annotated[
    User,
    Depends(get_current_user),
]


def _resolve_bearer_user(
    *,
    credentials: HTTPAuthorizationCredentials,
    user_service: UserService,
    access_token_service: AccessTokenService,
) -> User:
    """Resolve a user from an explicitly supplied Bearer access token."""

    try:
        claims = access_token_service.validate(
            credentials.credentials,
        )
    except InvalidAccessTokenError as error:
        raise APIError(
            status_code=status.HTTP_401_UNAUTHORIZED,
            code="invalid_access_token",
            message="The access token is invalid or expired.",
        ) from error

    user = user_service.get_by_id(
        claims.user_id,
    )

    if user is None or not user.is_active:
        raise APIError(
            status_code=status.HTTP_401_UNAUTHORIZED,
            code="invalid_access_token",
            message="The access token is invalid or expired.",
        )

    return user


def _resolve_web_session_user(
    *,
    session_credential: str,
    user_service: UserService,
    auth_session_service: AuthSessionService,
) -> User:
    """Resolve a user from a persistent Web authentication session."""

    auth_session = auth_session_service.resolve(
        session_credential,
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

    return user


def require_admin(
    current_user: CurrentUserDependency,
) -> User:
    """Require the current SofaWatch user to be an administrator."""

    if not current_user.is_admin:
        raise APIError(
            status_code=status.HTTP_403_FORBIDDEN,
            code="admin_required",
            message="Administrator access is required.",
        )

    return current_user


AdminUserDependency = Annotated[
    User,
    Depends(require_admin),
]


def get_authentication_settings_service(
    session: DatabaseSession,
) -> AuthenticationSettingsService:
    """Provide global authentication settings operations."""

    return AuthenticationSettingsService(
        session=session,
        repository=AuthenticationSettingsRepository(session),
    )


AuthenticationSettingsServiceDependency = Annotated[
    AuthenticationSettingsService,
    Depends(get_authentication_settings_service),
]

def get_registration_service(
    session: DatabaseSession,
    authentication_settings_service: AuthenticationSettingsServiceDependency,
) -> RegistrationService:
    """Provide public account-registration operations."""

    return RegistrationService(
        session=session,
        user_repository=UserRepository(session),
        authentication_settings_service=authentication_settings_service,
    )


RegistrationServiceDependency = Annotated[
    RegistrationService,
    Depends(get_registration_service),
]

def get_library_service(
    session: DatabaseSession,
) -> LibraryService:
    """Provide a library service for a single request."""

    return LibraryService(
        session=session,
        library_repository=LibraryRepository(session),
        show_repository=ShowRepository(session),
        movie_repository=MovieRepository(session),
        episode_repository=EpisodeRepository(session),
        episode_progress_repository=EpisodeProgressRepository(session),
    )


LibraryServiceDependency = Annotated[
    LibraryService,
    Depends(get_library_service),
]

def get_start_show_service(
    session: DatabaseSession,
) -> StartShowService:
    """Provide the service used to start a Library TV series."""

    return StartShowService(
        session=session,
        library_repository=LibraryRepository(session),
        episode_repository=EpisodeRepository(session),
        progress_repository=EpisodeProgressRepository(session),
        watch_event_repository=EpisodeWatchEventRepository(session),
    )


StartShowServiceDependency = Annotated[
    StartShowService,
    Depends(get_start_show_service),
]


def get_episode_progress_service(
    session: DatabaseSession,
) -> EpisodeProgressService:
    """Provide an episode progress service for a single request."""

    return EpisodeProgressService(
        session=session,
        progress_repository=EpisodeProgressRepository(session),
        episode_repository=EpisodeRepository(session),
        season_repository=SeasonRepository(session),
        show_repository=ShowRepository(session),
        watch_event_repository=EpisodeWatchEventRepository(session),
    )


EpisodeProgressServiceDependency = Annotated[
    EpisodeProgressService,
    Depends(get_episode_progress_service),
]

def get_episode_watch_event_service(
    session: DatabaseSession,
) -> EpisodeWatchEventService:
    """Provide historical Episode watch event operations."""

    return EpisodeWatchEventService(
        session=session,
        watch_event_repository=EpisodeWatchEventRepository(session),
        progress_repository=EpisodeProgressRepository(session),
    )


EpisodeWatchEventServiceDependency = Annotated[
    EpisodeWatchEventService,
    Depends(get_episode_watch_event_service),
]

def get_background_job_repository(
    session: DatabaseSession,
) -> BackgroundJobRepository:
    """Provide a background job repository for a single request."""

    return BackgroundJobRepository(session)


BackgroundJobRepositoryDependency = Annotated[
    BackgroundJobRepository,
    Depends(get_background_job_repository),
]


def get_background_job_executor(
    session: DatabaseSession,
) -> BackgroundJobExecutor:
    """Provide a background job executor for a single request."""

    return BackgroundJobExecutor(
        session=session,
        repository=BackgroundJobRepository(session),
    )


BackgroundJobExecutorDependency = Annotated[
    BackgroundJobExecutor,
    Depends(get_background_job_executor),
]


def get_image_service(
    session: DatabaseSession,
    settings: Annotated[
        Settings,
        Depends(get_settings),
    ],
) -> Generator[ImageService, None, None]:
    """Provide the image resolution service for one request."""

    storage = ImageStorage(
        settings=settings,
    )

    cache_service = ImageCacheService(
        settings=settings,
        storage=storage,
    )

    service = ImageService(
        session=session,
        storage=storage,
        cache_service=cache_service,
        show_repository=ShowRepository(session),
        season_repository=SeasonRepository(session),
        episode_repository=EpisodeRepository(session),
    )

    try:
        yield service
    finally:
        cache_service.close()


ImageServiceDependency = Annotated[
    ImageService,
    Depends(get_image_service),
]


def get_explore_service(
    session: DatabaseSession,
    settings: Annotated[
        Settings,
        Depends(get_settings),
    ],
    tmdb_client: Annotated[
        TMDBClient,
        Depends(get_tmdb_client),
    ],
) -> ExploreService:
    """Provide the Explore discovery service."""

    return ExploreService(
        settings=settings,
        tmdb_client=tmdb_client,
        library_repository=LibraryRepository(
            session,
        ),
    )


ExploreServiceDependency = Annotated[
    ExploreService,
    Depends(get_explore_service),
]

def get_season_episode_sync_service(
    session: DatabaseSession,
    season_details_service: Annotated[
        TMDBSeasonDetailsService,
        Depends(get_tmdb_season_details_service),
    ],
) -> SeasonEpisodeSyncService:
    """Provide the Season Episode synchronization service."""

    return SeasonEpisodeSyncService(
        session=session,
        show_repository=ShowRepository(session),
        season_repository=SeasonRepository(session),
        episode_repository=EpisodeRepository(session),
        tmdb_season_details_service=season_details_service,
    )

SeasonEpisodeSyncServiceDependency = Annotated[
    SeasonEpisodeSyncService,
    Depends(get_season_episode_sync_service),
]

def get_watch_next_service(
    session: DatabaseSession,
) -> WatchNextService:
    """Provide the Watch Next service for a single request."""

    return WatchNextService(
        library_repository=LibraryRepository(session),
        episode_repository=EpisodeRepository(session),
        progress_repository=EpisodeProgressRepository(session),
    )


WatchNextServiceDependency = Annotated[
    WatchNextService,
    Depends(get_watch_next_service),
]


def get_havent_started_service(
    session: DatabaseSession,
) -> HaventStartedService:
    """Provide the Haven't Started service for a single request."""

    return HaventStartedService(
        library_repository=LibraryRepository(session),
        episode_repository=EpisodeRepository(session),
    )


HaventStartedServiceDependency = Annotated[
    HaventStartedService,
    Depends(get_havent_started_service),
]

def get_upcoming_service(
    session: DatabaseSession,
) -> UpcomingService:
    """Provide the Upcoming service for a single request."""

    return UpcomingService(
        library_repository=LibraryRepository(session),
        episode_repository=EpisodeRepository(session),
        progress_repository=EpisodeProgressRepository(session),
    )


UpcomingServiceDependency = Annotated[
    UpcomingService,
    Depends(get_upcoming_service),
]

def get_missed_recently_service(
    session: DatabaseSession,
) -> MissedRecentlyService:
    """Provide the Home Missed Recently service for a single request."""

    return MissedRecentlyService(
        progress_repository=EpisodeProgressRepository(session),
    )


MissedRecentlyServiceDependency = Annotated[
    MissedRecentlyService,
    Depends(get_missed_recently_service),
]


def get_stale_watching_service(
    session: DatabaseSession,
) -> StaleWatchingService:
    """Provide the stale Watching service for a single request."""

    return StaleWatchingService(
        library_repository=LibraryRepository(session),
        progress_repository=EpisodeProgressRepository(session),
    )


StaleWatchingServiceDependency = Annotated[
    StaleWatchingService,
    Depends(get_stale_watching_service),
]

def get_watch_history_service(
    session: DatabaseSession,
) -> WatchHistoryService:
    """Provide the Watch History service for a single request."""

    return WatchHistoryService(
        watch_event_repository=EpisodeWatchEventRepository(session),
    )


WatchHistoryServiceDependency = Annotated[
    WatchHistoryService,
    Depends(get_watch_history_service),
]


def get_history_service(
    session: DatabaseSession,
) -> HistoryService:
    """Provide the combined viewing History service."""

    return HistoryService(
        episode_watch_event_repository=EpisodeWatchEventRepository(
            session,
        ),
        movie_watch_event_repository=MovieWatchEventRepository(
            session,
        ),
    )


HistoryServiceDependency = Annotated[
    HistoryService,
    Depends(get_history_service),
]


def get_statistics_service(
    session: DatabaseSession,
) -> StatisticsService:
    """Provide reusable viewing statistics for one request."""

    return StatisticsService(
        episode_watch_event_repository=EpisodeWatchEventRepository(
            session,
        ),
        movie_watch_event_repository=MovieWatchEventRepository(
            session,
        ),
        library_repository=LibraryRepository(
            session,
        ),
        episode_repository=EpisodeRepository(
            session,
        ),
        episode_progress_repository=EpisodeProgressRepository(
            session,
        ),
    )


StatisticsServiceDependency = Annotated[
    StatisticsService,
    Depends(get_statistics_service),
]

def get_server_health_service(
    request: Request,
    session: DatabaseSession,
    settings: Annotated[
        Settings,
        Depends(get_settings),
    ],
) -> ServerHealthService:
    """Provide administrative Server health operations."""

    started_at = getattr(
        request.app.state,
        "started_at",
        None,
    )

    if started_at is None:
        raise APIError(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            code="server_start_time_unavailable",
            message="Server start time is unavailable.",
        )

    return ServerHealthService(
        session=session,
        settings=settings,
        started_at=started_at,
    )


ServerHealthServiceDependency = Annotated[
    ServerHealthService,
    Depends(get_server_health_service),
]


def get_server_logs_service(
    settings: Annotated[
        Settings,
        Depends(get_settings),
    ],
) -> ServerLogsService:
    """Provide administrative Server log operations."""

    return ServerLogsService(
        settings=settings,
    )


ServerLogsServiceDependency = Annotated[
    ServerLogsService,
    Depends(get_server_logs_service),
]

def get_data_export_service(
    session: DatabaseSession,
) -> DataExportService:
    """Provide portable SofaWatch data export operations."""

    return DataExportService(
        library_repository=LibraryRepository(
            session,
        ),
        episode_watch_event_repository=EpisodeWatchEventRepository(
            session,
        ),
        movie_watch_event_repository=MovieWatchEventRepository(
            session,
        ),
    )


DataExportServiceDependency = Annotated[
    DataExportService,
    Depends(get_data_export_service),
]

def get_data_import_service(
    session: DatabaseSession,
    show_import_service: ShowImportServiceDependency,
    movie_import_service: MovieImportServiceDependency,
    season_episode_sync_service: SeasonEpisodeSyncServiceDependency,
) -> DataImportService:
    """Provide portable SofaWatch data import operations."""

    return DataImportService(
        session=session,
        library_repository=LibraryRepository(
            session,
        ),
        show_repository=ShowRepository(
            session,
        ),
        movie_repository=MovieRepository(
            session,
        ),
        show_import_service=show_import_service,
        movie_import_service=movie_import_service,
        movie_watch_event_repository=MovieWatchEventRepository(
            session,
        ),
        season_repository=SeasonRepository(
            session,
        ),
        episode_repository=EpisodeRepository(
            session,
        ),
        episode_watch_event_repository=EpisodeWatchEventRepository(
            session,
        ),
        episode_progress_repository=EpisodeProgressRepository(
            session,
        ),
        season_episode_sync_service=season_episode_sync_service,
    )


DataImportServiceDependency = Annotated[
    DataImportService,
    Depends(get_data_import_service),
]