from datetime import datetime
from uuid import UUID
import logging

from sqlalchemy.orm import Session

from app.models.enums import LibraryStatus
from app.models.library import LibraryEntry
from app.repositories.library import LibraryRepository
from app.repositories.movie import MovieRepository
from app.repositories.show import ShowRepository
from app.schemas.data_export import (
    ExportEpisodeWatchEventResponse,
    ExportLibraryMovieResponse,
    ExportLibraryShowResponse,
    ExportMovieWatchEventResponse,
    SofaWatchExportResponse,
)
from app.models.episode_watch_event import EpisodeWatchEvent
from app.schemas.data_import import (
    DataImportHistoryMediaSummaryResponse,
    DataImportHistoryResultResponse,
    DataImportLibraryResultResponse,
    DataImportMediaSummaryResponse,
    DataImportPreviewResponse,
    DataImportPreviewSummaryResponse,
    DataImportResultResponse,
)
from app.services.movie_import import MovieImportService
from app.services.show_import import ShowImportService
from app.models.movie_watch_event import MovieWatchEvent
from app.repositories.movie_watch_event import MovieWatchEventRepository
from app.repositories.episode import EpisodeRepository
from app.repositories.episode_progress import EpisodeProgressRepository
from app.repositories.episode_watch_event import EpisodeWatchEventRepository
from app.repositories.season import SeasonRepository
from app.services.season_episode_sync import SeasonEpisodeSyncService
from app.models.episode_progress import EpisodeProgress

logger = logging.getLogger(__name__)

class DataImportService:
    """Validate and import portable SofaWatch user data."""

    def __init__(
        self,
        *,
        session: Session,
        library_repository: LibraryRepository,
        show_repository: ShowRepository,
        movie_repository: MovieRepository,
        show_import_service: ShowImportService,
        movie_import_service: MovieImportService,
        movie_watch_event_repository: MovieWatchEventRepository,
        season_repository: SeasonRepository,
        episode_repository: EpisodeRepository,
        episode_watch_event_repository: EpisodeWatchEventRepository,
        episode_progress_repository: EpisodeProgressRepository,
        season_episode_sync_service: SeasonEpisodeSyncService,
    ) -> None:
        self._session = session
        self._library_repository = library_repository
        self._show_repository = show_repository
        self._movie_repository = movie_repository
        self._show_import_service = show_import_service
        self._movie_import_service = movie_import_service
        self._movie_watch_event_repository = movie_watch_event_repository
        self._season_repository = season_repository
        self._episode_repository = episode_repository
        self._episode_watch_event_repository = episode_watch_event_repository
        self._episode_progress_repository = episode_progress_repository
        self._season_episode_sync_service = season_episode_sync_service

    def preview(
        self,
        *,
        export: SofaWatchExportResponse,
    ) -> DataImportPreviewResponse:
        """Return a read-only summary of a validated SofaWatch export."""

        return DataImportPreviewResponse(
            format=export.format,
            version=export.version,
            user_display_name=export.user.display_name,
            summary=DataImportPreviewSummaryResponse(
                library_shows=len(
                    export.library.shows,
                ),
                library_movies=len(
                    export.library.movies,
                ),
                episode_watch_events=len(
                    export.history.episodes,
                ),
                movie_watch_events=len(
                    export.history.movies,
                ),
            ),
        )

    def import_user_data(
        self,
        *,
        user_id: UUID,
        export: SofaWatchExportResponse,
    ) -> DataImportResultResponse:
        """Import all supported portable data for the current user.

        Library state is restored before viewing History so locally stored
        media and tracking state are available before historical events are
        merged.

        Importing History remains independent from Library membership:
        historical media that is not part of the exported Library is not
        automatically added to it.
        """

        library_result = self.import_library(
            user_id=user_id,
            export=export,
        )

        history_result = self.import_history(
            user_id=user_id,
            export=export,
        )

        return DataImportResultResponse(
            library=library_result,
            history=history_result,
        )

    def import_library(
        self,
        *,
        user_id: UUID,
        export: SofaWatchExportResponse,
    ) -> DataImportLibraryResultResponse:
        """Merge portable Library data into the current user's Library.

        Individual media failures are isolated so one invalid or unavailable
        item does not prevent the remaining Library data from being restored.
        """

        show_created = 0
        show_updated = 0
        show_unchanged = 0
        show_failed = 0

        for exported_show in export.library.shows:
            try:
                outcome = self._import_library_show(
                    user_id=user_id,
                    exported_show=exported_show,
                )
            except Exception:
                self._session.rollback()

                show_failed += 1

                logger.exception(
                    "Failed to import Library Show with TMDB ID %s.",
                    exported_show.tmdb_id,
                )

                continue

            if outcome == "created":
                show_created += 1
            elif outcome == "updated":
                show_updated += 1
            else:
                show_unchanged += 1

        movie_created = 0
        movie_updated = 0
        movie_unchanged = 0
        movie_failed = 0

        for exported_movie in export.library.movies:
            try:
                outcome = self._import_library_movie(
                    user_id=user_id,
                    exported_movie=exported_movie,
                )
            except Exception:
                self._session.rollback()

                movie_failed += 1

                logger.exception(
                    "Failed to import Library Movie with TMDB ID %s.",
                    exported_movie.tmdb_id,
                )

                continue

            if outcome == "created":
                movie_created += 1
            elif outcome == "updated":
                movie_updated += 1
            else:
                movie_unchanged += 1

        return DataImportLibraryResultResponse(
            shows=DataImportMediaSummaryResponse(
                created=show_created,
                updated=show_updated,
                unchanged=show_unchanged,
                failed=show_failed,
            ),
            movies=DataImportMediaSummaryResponse(
                created=movie_created,
                updated=movie_updated,
                unchanged=movie_unchanged,
                failed=movie_failed,
            ),
        )

    def import_history(
        self,
        *,
        user_id: UUID,
        export: SofaWatchExportResponse,
    ) -> DataImportHistoryResultResponse:
        """Merge portable viewing History into the current user's History.

        Individual event failures are isolated so the remaining viewing History
        can still be restored.
        """

        episode_created = 0
        episode_skipped = 0
        episode_failed = 0

        for exported_event in export.history.episodes:
            try:
                created = self._import_episode_watch_event(
                    user_id=user_id,
                    exported_event=exported_event,
                )
            except Exception:
                self._session.rollback()

                episode_failed += 1

                logger.exception(
                    (
                        "Failed to import Episode watch event "
                        "for TMDB Episode ID %s."
                    ),
                    exported_event.episode_tmdb_id,
                )

                continue

            if created:
                episode_created += 1
            else:
                episode_skipped += 1

        movie_created = 0
        movie_skipped = 0
        movie_failed = 0

        for exported_event in export.history.movies:
            try:
                created = self._import_movie_watch_event(
                    user_id=user_id,
                    exported_event=exported_event,
                )
            except Exception:
                self._session.rollback()

                movie_failed += 1

                logger.exception(
                    "Failed to import Movie watch event for TMDB ID %s.",
                    exported_event.movie_tmdb_id,
                )

                continue

            if created:
                movie_created += 1
            else:
                movie_skipped += 1

        return DataImportHistoryResultResponse(
            episodes=DataImportHistoryMediaSummaryResponse(
                created=episode_created,
                skipped=episode_skipped,
                failed=episode_failed,
            ),
            movies=DataImportHistoryMediaSummaryResponse(
                created=movie_created,
                skipped=movie_skipped,
                failed=movie_failed,
            ),
        )

    def _import_episode_watch_event(
        self,
        *,
        user_id: UUID,
        exported_event: ExportEpisodeWatchEventResponse,
    ) -> bool:
        """Restore one historical Episode viewing."""

        show = self._show_repository.get_by_tmdb_id(
            exported_event.show_tmdb_id,
        )

        if show is None:
            show = self._show_import_service.import_show(
                tmdb_id=exported_event.show_tmdb_id,
            )

        season = self._season_repository.get_by_number(
            show_id=show.id,
            season_number=exported_event.season_number,
        )

        if season is None:
            return False

        episode = self._episode_repository.get_by_tmdb_id(
            exported_event.episode_tmdb_id,
        )

        if episode is None:
            self._season_episode_sync_service.sync(
                season_id=season.id,
            )

            episode = self._episode_repository.get_by_tmdb_id(
                exported_event.episode_tmdb_id,
            )

        if (
            episode is None
            or episode.season_id != season.id
            or episode.episode_number != exported_event.episode_number
        ):
            return False

        if self._episode_watch_event_repository.exists_at(
            user_id=user_id,
            episode_id=episode.id,
            watched_at=exported_event.watched_at,
        ):
            return False

        event = EpisodeWatchEvent(
            user_id=user_id,
            episode_id=episode.id,
            watched_at=exported_event.watched_at,
        )

        self._episode_watch_event_repository.add(
            event,
        )

        progress = self._episode_progress_repository.get_by_user_and_episode(
            user_id=user_id,
            episode_id=episode.id,
        )

        if progress is None:
            progress = EpisodeProgress(
                user_id=user_id,
                episode_id=episode.id,
                is_watched=True,
                watched_at=exported_event.watched_at,
            )

            self._episode_progress_repository.add(
                progress,
            )
        else:
            progress.is_watched = True

            if (
                progress.watched_at is None
                or exported_event.watched_at > progress.watched_at
            ):
                progress.watched_at = exported_event.watched_at

        self._session.commit()

        return True

    def _import_movie_watch_event(
        self,
        *,
        user_id: UUID,
        exported_event: ExportMovieWatchEventResponse,
    ) -> bool:
        """Restore one historical Movie viewing without changing Library state."""

        movie = self._movie_repository.get_by_tmdb_id(
            exported_event.movie_tmdb_id,
        )

        if movie is None:
            movie = self._movie_import_service.import_movie(
                tmdb_id=exported_event.movie_tmdb_id,
            )

        if self._movie_watch_event_repository.exists_at(
            user_id=user_id,
            movie_id=movie.id,
            watched_at=exported_event.watched_at,
        ):
            return False

        event = MovieWatchEvent(
            user_id=user_id,
            movie_id=movie.id,
            watched_at=exported_event.watched_at,
        )

        self._movie_watch_event_repository.add(
            event,
        )

        self._session.commit()

        return True

    def _import_library_show(
        self,
        *,
        user_id: UUID,
        exported_show: ExportLibraryShowResponse,
    ) -> str:
        show = self._show_repository.get_by_tmdb_id(
            exported_show.tmdb_id,
        )

        if show is None:
            show = self._show_import_service.import_show(
                tmdb_id=exported_show.tmdb_id,
            )

        entry = self._library_repository.get_by_user_and_show(
            user_id=user_id,
            show_id=show.id,
        )

        if entry is None:
            entry = LibraryEntry(
                user_id=user_id,
                show_id=show.id,
                status=exported_show.status,
                started_at=exported_show.started_at,
                completed_at=exported_show.completed_at,
            )

            self._library_repository.add(
                entry,
            )

            self._session.commit()
            self._session.refresh(entry)

            return "created"

        changed = self._merge_library_entry(
            entry=entry,
            status=exported_show.status,
            started_at=exported_show.started_at,
            completed_at=exported_show.completed_at,
        )

        if not changed:
            return "unchanged"

        self._session.commit()

        return "updated"

    def _import_library_movie(
        self,
        *,
        user_id: UUID,
        exported_movie: ExportLibraryMovieResponse,
    ) -> str:
        movie = self._movie_repository.get_by_tmdb_id(
            exported_movie.tmdb_id,
        )

        if movie is None:
            movie = self._movie_import_service.import_movie(
                tmdb_id=exported_movie.tmdb_id,
            )

        entry = self._library_repository.get_by_user_and_movie(
            user_id=user_id,
            movie_id=movie.id,
        )

        if entry is None:
            entry = LibraryEntry(
                user_id=user_id,
                movie_id=movie.id,
                status=exported_movie.status,
                started_at=exported_movie.started_at,
                completed_at=exported_movie.completed_at,
            )

            self._library_repository.add(
                entry,
            )

            self._session.commit()
            self._session.refresh(entry)

            return "created"

        changed = self._merge_library_entry(
            entry=entry,
            status=exported_movie.status,
            started_at=exported_movie.started_at,
            completed_at=exported_movie.completed_at,
        )

        if not changed:
            return "unchanged"

        self._session.commit()

        return "updated"

    @staticmethod
    def _merge_library_entry(
        *,
        entry: LibraryEntry,
        status: LibraryStatus,
        started_at: datetime | None,
        completed_at: datetime | None,
    ) -> bool:
        """Merge imported tracking state without inventing timestamps."""

        changed = False

        if entry.status != status:
            entry.status = status
            changed = True

        if (
            started_at is not None
            and entry.started_at != started_at
        ):
            entry.started_at = started_at
            changed = True

        if status == LibraryStatus.COMPLETED:
            if (
                completed_at is not None
                and entry.completed_at != completed_at
            ):
                entry.completed_at = completed_at
                changed = True
        elif entry.completed_at is not None:
            entry.completed_at = None
            changed = True

        return changed