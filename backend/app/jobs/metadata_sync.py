import logging

from app.core.config import get_settings
from app.db.session import SessionLocal
from app.providers.tmdb import TMDBClient
from app.repositories.episode import EpisodeRepository
from app.repositories.genre import GenreRepository
from app.repositories.network import NetworkRepository
from app.repositories.season import SeasonRepository
from app.repositories.show import ShowRepository
from app.services.season_episode_sync import SeasonEpisodeSyncService
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

        season_repository = SeasonRepository(session)
        episode_repository = EpisodeRepository(session)

        tmdb_season_details_service = TMDBSeasonDetailsService(
            tmdb_client=tmdb_client,
        )

        show_import_service = ShowImportService(
            session=session,
            settings=settings,
            show_repository=show_repository,
            genre_repository=GenreRepository(session),
            network_repository=NetworkRepository(session),
            season_repository=season_repository,
            episode_repository=episode_repository,
            tmdb_show_details_service=TMDBShowDetailsService(
                settings=settings,
                tmdb_client=tmdb_client,
            ),
            tmdb_season_details_service=tmdb_season_details_service,
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


def run_metadata_force_sync() -> dict[str, object]:
    """Force-refresh show, season and episode metadata."""

    settings = get_settings()

    with SessionLocal() as session, TMDBClient(settings=settings) as tmdb_client:
        show_repository = ShowRepository(session)
        season_repository = SeasonRepository(session)
        episode_repository = EpisodeRepository(session)

        tmdb_season_details_service = TMDBSeasonDetailsService(
            tmdb_client=tmdb_client,
        )

        show_import_service = ShowImportService(
            session=session,
            settings=settings,
            show_repository=show_repository,
            genre_repository=GenreRepository(session),
            network_repository=NetworkRepository(session),
            season_repository=season_repository,
            episode_repository=episode_repository,
            tmdb_show_details_service=TMDBShowDetailsService(
                settings=settings,
                tmdb_client=tmdb_client,
            ),
            tmdb_season_details_service=tmdb_season_details_service,
        )

        episode_sync_service = SeasonEpisodeSyncService(
            session=session,
            show_repository=show_repository,
            season_repository=season_repository,
            episode_repository=episode_repository,
            tmdb_season_details_service=tmdb_season_details_service,
        )

        shows = show_repository.list_all()

        checked = 0
        refreshed = 0
        skipped = 0
        failed = 0
        seasons_synced = 0
        episodes_refreshed = 0

        logger.info(
            "Forced metadata sync started for %s TV series.",
            len(shows),
        )

        for show in shows:
            checked += 1

            try:
                refreshed_show = show_import_service.refresh_show(
                    tmdb_id=show.tmdb_id,
                    language=show.metadata_language,
                )

                refreshed += 1

                seasons = season_repository.list_by_show_id(
                    refreshed_show.id,
                )

                for season in seasons:
                    episodes = episode_sync_service.sync(
                        season_id=season.id,
                        language=refreshed_show.metadata_language,
                        force_refresh=True,
                    )

                    seasons_synced += 1

                    if episodes is not None:
                        episodes_refreshed += len(episodes)

            except Exception:
                failed += 1

                logger.exception(
                    "Failed to force-refresh '%s' (%s).",
                    show.title,
                    show.tmdb_id,
                )

        result = {
            "checked": checked,
            "refreshed": refreshed,
            "skipped": skipped,
            "failed": failed,
            "seasons_synced": seasons_synced,
            "episodes_refreshed": episodes_refreshed,
        }

        logger.info(
            (
                "Forced metadata sync finished: "
                "%s checked, %s refreshed, %s seasons synced, "
                "%s episodes refreshed, %s failed."
            ),
            checked,
            refreshed,
            seasons_synced,
            episodes_refreshed,
            failed,
        )

        if failed > 0:
            raise MetadataSyncError(
                (
                    f"Forced metadata sync finished with {failed} "
                    f"failed TV series out of {checked}."
                ),
                result=result,
            )

        return result