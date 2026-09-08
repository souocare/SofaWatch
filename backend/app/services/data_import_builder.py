from sqlalchemy.orm import Session

from app.core.config import Settings
from app.providers.tmdb import TMDBClient
from app.repositories.episode import EpisodeRepository
from app.repositories.episode_progress import EpisodeProgressRepository
from app.repositories.episode_watch_event import EpisodeWatchEventRepository
from app.repositories.genre import GenreRepository
from app.repositories.library import LibraryRepository
from app.repositories.movie import MovieRepository
from app.repositories.movie_watch_event import MovieWatchEventRepository
from app.repositories.network import NetworkRepository
from app.repositories.season import SeasonRepository
from app.repositories.show import ShowRepository
from app.services.data_import import DataImportService
from app.services.movie_import import MovieImportService
from app.services.season_episode_sync import SeasonEpisodeSyncService
from app.services.show_import import ShowImportService
from app.services.tmdb_movie_details import TMDBMovieDetailsService
from app.services.tmdb_season_details import TMDBSeasonDetailsService
from app.services.tmdb_show_details import TMDBShowDetailsService


def build_data_import_service(
    *,
    session: Session,
    settings: Settings,
    tmdb_client: TMDBClient,
) -> DataImportService:
    """Build the complete portable data-import service graph."""

    show_repository = ShowRepository(session)
    movie_repository = MovieRepository(session)
    season_repository = SeasonRepository(session)
    episode_repository = EpisodeRepository(session)
    genre_repository = GenreRepository(session)

    show_details_service = TMDBShowDetailsService(
        settings=settings,
        tmdb_client=tmdb_client,
    )

    movie_details_service = TMDBMovieDetailsService(
        settings=settings,
        tmdb_client=tmdb_client,
    )

    season_details_service = TMDBSeasonDetailsService(
        tmdb_client=tmdb_client,
    )

    show_import_service = ShowImportService(
        session=session,
        settings=settings,
        show_repository=show_repository,
        genre_repository=genre_repository,
        network_repository=NetworkRepository(session),
        season_repository=season_repository,
        episode_repository=episode_repository,
        tmdb_show_details_service=show_details_service,
        tmdb_season_details_service=season_details_service,
    )

    movie_import_service = MovieImportService(
        session=session,
        settings=settings,
        movie_repository=movie_repository,
        genre_repository=genre_repository,
        tmdb_movie_details_service=movie_details_service,
    )

    season_episode_sync_service = SeasonEpisodeSyncService(
        session=session,
        show_repository=show_repository,
        season_repository=season_repository,
        episode_repository=episode_repository,
        tmdb_season_details_service=season_details_service,
    )

    return DataImportService(
        session=session,
        library_repository=LibraryRepository(session),
        show_repository=show_repository,
        movie_repository=movie_repository,
        show_import_service=show_import_service,
        movie_import_service=movie_import_service,
        movie_watch_event_repository=MovieWatchEventRepository(
            session,
        ),
        season_repository=season_repository,
        episode_repository=episode_repository,
        episode_watch_event_repository=EpisodeWatchEventRepository(
            session,
        ),
        episode_progress_repository=EpisodeProgressRepository(
            session,
        ),
        season_episode_sync_service=season_episode_sync_service,
    )