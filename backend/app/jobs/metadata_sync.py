import logging
from dataclasses import dataclass

from enum import StrEnum

from app.core.config import get_settings
from app.db.session import SessionLocal
from app.providers.tmdb import TMDBClient
from app.repositories.episode import EpisodeRepository
from app.repositories.genre import GenreRepository
from app.repositories.network import NetworkRepository
from app.repositories.season import SeasonRepository
from app.repositories.show import ShowRepository
from app.services.show_import import ShowImportService, ShowSyncOutcome
from app.services.tmdb_season_details import TMDBSeasonDetailsService
from app.services.tmdb_show_details import TMDBShowDetailsService

logger = logging.getLogger(__name__)


class MetadataSyncError(RuntimeError):
    """Raised when one or more TV series fail during metadata sync."""

    def __init__(
        self,
        message: str,
        *,
        result: dict[str, object],
    ) -> None:
        super().__init__(message)
        self.result = result


def run_metadata_sync() -> dict[str, object]:
    """Synchronize metadata for all locally stored TV series."""

    settings = get_settings()

    with SessionLocal() as session, TMDBClient(settings=settings) as tmdb_client:
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

        checked = 0
        refreshed = 0
        skipped = 0
        failed = 0

        for show in shows:
            checked += 1
            try:
                logger.info(
                    "Checking '%s' (%s).",
                    show.title,
                    show.tmdb_id,
                )
                result = show_import_service.sync_show(
                    tmdb_id=show.tmdb_id,
                    language=show.metadata_language,
                )
                if result.outcome is ShowSyncOutcome.REFRESHED:
                    refreshed += 1
                else:
                    skipped += 1
            except Exception:
                failed += 1

                logger.exception(
                    "Failed to refresh '%s' (%s).",
                    show.title,
                    show.tmdb_id,
                )

        result = {
            "checked": checked,
            "refreshed": refreshed,
            "skipped": skipped,
            "failed": failed,
        }

        logger.info(
            ("Metadata sync finished: %s checked, %s refreshed, %s skipped, %s failed."),
            checked,
            refreshed,
            skipped,
            failed,
        )

        if failed > 0:
            raise MetadataSyncError(
                (f"Metadata sync finished with {failed} failed TV series out of {checked}."),
                result=result,
            )

        return result
