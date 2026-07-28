import logging

from app.core.config import get_settings
from app.db.session import SessionLocal
from app.providers.tmdb import TMDBClient
from app.repositories.episode import EpisodeRepository
from app.repositories.genre import GenreRepository
from app.repositories.network import NetworkRepository
from app.repositories.season import SeasonRepository
from app.repositories.show import ShowRepository
from app.services.show_import import ShowImportService
from app.services.tmdb_season_details import TMDBSeasonDetailsService
from app.services.tmdb_show_details import TMDBShowDetailsService


logger = logging.getLogger(__name__)


def run_metadata_sync() -> None:
    """Synchronize metadata for all locally stored TV series."""

    settings = get_settings()

    with SessionLocal() as session:
        with TMDBClient(settings=settings) as tmdb_client:
            show_repository = ShowRepository(session)

            show_import_service = ShowImportService(
                session=session,
                settings=settings,
                show_repository=show_repository,
                genre_repository=GenreRepository(session),
                network_repository=NetworkRepository(session),
                season_repository=SeasonRepository(session),
                episode_repository=EpisodeRepository(session),
                tmdb_show_details_service=TMDBShowDetailsService(
                    settings=settings,
                    tmdb_client=tmdb_client,
                ),
                tmdb_season_details_service=TMDBSeasonDetailsService(
                    tmdb_client=tmdb_client,
                ),
            )

            shows = show_repository.list_all()

            logger.info(
                "Metadata sync started for %s TV series.",
                len(shows),
            )

            successful = 0
            failed = 0

            for show in shows:
                try:
                    logger.info(
                        "Refreshing '%s' (%s).",
                        show.title,
                        show.tmdb_id,
                    )

                    show_import_service.import_show(
                        tmdb_id=show.tmdb_id,
                        language=show.metadata_language,
                        force_refresh=False,
                    )

                    successful += 1

                except Exception:
                    failed += 1

                    logger.exception(
                        "Failed to refresh '%s' (%s).",
                        show.title,
                        show.tmdb_id,
                    )

            logger.info(
                (
                    "Metadata sync finished: "
                    "%s successful, %s failed."
                ),
                successful,
                failed,
            )

            if failed > 0:
                raise RuntimeError(
                    f"Metadata sync finished with {failed} failed "
                    f"TV series out of {len(shows)}."
                )