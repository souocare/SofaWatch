from datetime import UTC, datetime
from uuid import UUID

from app.models.user import User
from app.repositories.episode_watch_event import EpisodeWatchEventRepository
from app.repositories.library import LibraryRepository
from app.repositories.movie_watch_event import MovieWatchEventRepository
from app.schemas.data_export import (
    ExportEpisodeWatchEventResponse,
    ExportLibraryMovieResponse,
    ExportLibraryResponse,
    ExportLibraryShowResponse,
    ExportMovieWatchEventResponse,
    ExportUserResponse,
    ExportWatchHistoryResponse,
    SofaWatchExportResponse,
)


class DataExportService:
    """Build a portable versioned SofaWatch user data export."""

    def __init__(
        self,
        *,
        library_repository: LibraryRepository,
        episode_watch_event_repository: EpisodeWatchEventRepository,
        movie_watch_event_repository: MovieWatchEventRepository,
    ) -> None:
        self._library_repository = library_repository
        self._episode_watch_event_repository = (
            episode_watch_event_repository
        )
        self._movie_watch_event_repository = (
            movie_watch_event_repository
        )

    def export_user_data(
        self,
        *,
        user: User,
    ) -> SofaWatchExportResponse:
        """Export the current portable user state."""

        return SofaWatchExportResponse(
            exported_at=datetime.now(UTC),
            user=ExportUserResponse(
                display_name=user.display_name,
            ),
            library=self._export_library(
                user_id=user.id,
            ),
            history=self._export_history(
                user_id=user.id,
            ),
        )

    def _export_library(
        self,
        *,
        user_id: UUID,
    ) -> ExportLibraryResponse:
        show_entries = self._library_repository.list_shows_by_user(
            user_id,
        )

        movie_entries = self._library_repository.list_movies_by_user(
            user_id,
        )

        shows: list[ExportLibraryShowResponse] = []

        for entry in show_entries:
            show = entry.show

            if show is None:
                continue

            shows.append(
                ExportLibraryShowResponse(
                    tmdb_id=show.tmdb_id,
                    status=entry.status,
                    started_at=entry.started_at,
                    completed_at=entry.completed_at,
                )
            )

        movies: list[ExportLibraryMovieResponse] = []

        for entry in movie_entries:
            movie = entry.movie

            if movie is None:
                continue

            movies.append(
                ExportLibraryMovieResponse(
                    tmdb_id=movie.tmdb_id,
                    status=entry.status,
                    started_at=entry.started_at,
                    completed_at=entry.completed_at,
                )
            )

        return ExportLibraryResponse(
            shows=shows,
            movies=movies,
        )

    def _export_history(
        self,
        *,
        user_id: UUID,
    ) -> ExportWatchHistoryResponse:
        episode_events = (
            self._episode_watch_event_repository.list_all_for_user(
                user_id=user_id,
            )
        )

        movie_events = (
            self._movie_watch_event_repository.list_all_for_user(
                user_id=user_id,
            )
        )

        episodes = [
            ExportEpisodeWatchEventResponse(
                show_tmdb_id=event.show.tmdb_id,
                season_number=event.season_number,
                episode_number=event.episode.episode_number,
                episode_tmdb_id=event.episode.tmdb_id,
                watched_at=event.watched_at,
            )
            for event in episode_events
        ]

        movies = [
            ExportMovieWatchEventResponse(
                movie_tmdb_id=event.movie.tmdb_id,
                watched_at=event.watched_at,
            )
            for event in movie_events
        ]

        return ExportWatchHistoryResponse(
            episodes=episodes,
            movies=movies,
        )