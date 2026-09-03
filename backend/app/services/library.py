from datetime import UTC, date, datetime
from uuid import UUID

from sqlalchemy.orm import Session

from app.models.enums import LibraryStatus
from app.models.library import LibraryEntry
from app.repositories.episode import EpisodeRepository
from app.repositories.episode_progress import EpisodeProgressRepository
from app.repositories.library import LibraryRepository
from app.repositories.movie import MovieRepository
from app.repositories.show import ShowRepository
from app.schemas.library import (
    LibraryFirstEpisodeResponse,
    LibraryPreviewMovieResponse,
    LibraryPreviewResponse,
    LibraryPreviewShowResponse,
    LibraryShowProgressResponse,
    LibraryShowResponse,
)


class InvalidManualShowStatusError(ValueError):
    """Raised when a derived Show status is requested manually."""


class LibraryService:
    """Business logic for a user's personal media library."""

    def __init__(
        self,
        *,
        session: Session,
        library_repository: LibraryRepository,
        show_repository: ShowRepository,
        movie_repository: MovieRepository,
        episode_repository: EpisodeRepository,
        episode_progress_repository: EpisodeProgressRepository,
    ) -> None:
        self._session = session
        self._library_repository = library_repository
        self._show_repository = show_repository
        self._movie_repository = movie_repository
        self._episode_repository = episode_repository
        self._episode_progress_repository = episode_progress_repository

    def list_for_user(
        self,
        user_id: UUID,
        *,
        status: LibraryStatus | None = None,
    ) -> list[LibraryEntry]:
        """Return a user's library entries."""

        return self._library_repository.list_by_user(
            user_id,
            status=status,
        )

    def list_shows_for_user(
        self,
        user_id: UUID,
        *,
        status: LibraryStatus | None = None,
    ) -> list[LibraryShowResponse]:
        """Return TV series in a user's library enriched with viewing progress."""

        entries = self._library_repository.list_shows_by_user(
            user_id,
            status=status,
        )

        today = date.today()

        show_ids = [entry.show_id for entry in entries if entry.show_id is not None]

        planning_show_ids = [
            entry.show_id
            for entry in entries
            if entry.status == LibraryStatus.PLANNING and entry.show_id is not None
        ]

        first_episode_by_show = self._episode_repository.get_first_aired_regular_for_shows(
            show_ids=planning_show_ids,
            as_of=today,
        )

        aired_counts = self._episode_repository.get_aired_counts_by_show_ids(
            show_ids=show_ids,
            as_of=today,
        )

        watched_aired_counts = (
            self._episode_progress_repository.get_watched_aired_counts_by_show_ids(
                user_id=user_id,
                show_ids=show_ids,
                as_of=today,
            )
        )

        results: list[LibraryShowResponse] = []

        for entry in entries:
            if entry.show is None or entry.show_id is None:
                continue

            first_available_episode = None

            first_episode_result = first_episode_by_show.get(
                entry.show_id,
            )

            if first_episode_result is not None:
                episode, season_number = first_episode_result

                first_available_episode = LibraryFirstEpisodeResponse(
                    id=episode.id,
                    tmdb_id=episode.tmdb_id,
                    season_number=season_number,
                    episode_number=episode.episode_number,
                    title=episode.title,
                    air_date=episode.air_date,
                    runtime=episode.runtime,
                )

            aired_episodes = aired_counts.get(
                entry.show_id,
                0,
            )

            watched_episodes = watched_aired_counts.get(
                entry.show_id,
                0,
            )

            percentage = watched_episodes / aired_episodes * 100 if aired_episodes > 0 else 0.0

            caught_up = aired_episodes > 0 and watched_episodes == aired_episodes

            results.append(
                LibraryShowResponse(
                    id=entry.id,
                    status=entry.status,
                    rating=entry.rating,
                    started_at=entry.started_at,
                    completed_at=entry.completed_at,
                    created_at=entry.created_at,
                    updated_at=entry.updated_at,
                    show=entry.show,
                    first_available_episode=first_available_episode,
                    progress=LibraryShowProgressResponse(
                        watched_episodes=watched_episodes,
                        aired_episodes=aired_episodes,
                        percentage=percentage,
                        caught_up=caught_up,
                    ),
                )
            )

        return results

    def get_show_entry(
        self,
        *,
        user_id: UUID,
        show_id: UUID,
    ) -> LibraryEntry | None:
        """Return the user's library entry for a TV series."""

        return self._library_repository.get_by_user_and_show(
            user_id=user_id,
            show_id=show_id,
        )

    def get_movie_entry(
        self,
        *,
        user_id: UUID,
        movie_id: UUID,
    ) -> LibraryEntry | None:
        """Return the user's library entry for a Movie."""

        return self._library_repository.get_by_user_and_movie(
            user_id=user_id,
            movie_id=movie_id,
        )

    def add_show(
        self,
        *,
        user_id: UUID,
        show_id: UUID,
        status: LibraryStatus = LibraryStatus.PLANNING,
    ) -> LibraryEntry | None:
        """Ensure a locally stored TV series exists in a user's library."""

        show = self._show_repository.get_by_id(
            show_id,
        )

        if show is None:
            return None

        existing_entry = self._library_repository.get_by_user_and_show(
            user_id=user_id,
            show_id=show_id,
        )

        if existing_entry is not None:
            return existing_entry

        entry = LibraryEntry(
            user_id=user_id,
            show_id=show_id,
            status=status,
        )

        self._library_repository.add(entry)

        self._session.commit()
        self._session.refresh(entry)

        return entry

    def add_movie(
        self,
        *,
        user_id: UUID,
        movie_id: UUID,
        status: LibraryStatus = LibraryStatus.PLANNING,
    ) -> LibraryEntry | None:
        """Ensure a locally stored Movie exists in a user's library."""

        movie = self._movie_repository.get_by_id(
            movie_id,
        )

        if movie is None:
            return None

        existing_entry = self._library_repository.get_by_user_and_movie(
            user_id=user_id,
            movie_id=movie_id,
        )

        if existing_entry is not None:
            return existing_entry

        entry = LibraryEntry(
            user_id=user_id,
            movie_id=movie_id,
            status=status,
        )

        self._library_repository.add(entry)

        self._session.commit()
        self._session.refresh(entry)

        return entry

    def remove_show(
        self,
        *,
        user_id: UUID,
        show_id: UUID,
    ) -> bool:
        """Remove a TV series from a user's library."""

        entry = self._library_repository.get_by_user_and_show(
            user_id=user_id,
            show_id=show_id,
        )

        if entry is None:
            return False

        self._library_repository.delete(entry)

        self._session.commit()

        return True

    def remove_movie(
        self,
        *,
        user_id: UUID,
        movie_id: UUID,
    ) -> bool:
        """Remove a Movie from a user's library."""

        entry = self._library_repository.get_by_user_and_movie(
            user_id=user_id,
            movie_id=movie_id,
        )

        if entry is None:
            return False

        self._library_repository.delete(entry)

        self._session.commit()

        return True

    def update_show_status(
        self,
        *,
        user_id: UUID,
        show_id: UUID,
        status: LibraryStatus,
    ) -> LibraryEntry | None:
        """Update the tracking status of a TV series."""

        entry = self._library_repository.get_by_user_and_show(
            user_id=user_id,
            show_id=show_id,
        )

        if entry is None:
            return None

        manual_statuses = {
            LibraryStatus.PAUSED,
            LibraryStatus.DROPPED,
        }

        if status not in manual_statuses:
            raise InvalidManualShowStatusError(
                "TV series status can only be manually changed to paused or dropped."
            )

        entry.status = status
        entry.completed_at = None

        self._session.commit()
        self._session.refresh(entry)

        return entry

    def update_movie_status(
        self,
        *,
        user_id: UUID,
        movie_id: UUID,
        status: LibraryStatus,
    ) -> LibraryEntry | None:
        """Update the tracking status of a Movie."""

        entry = self._library_repository.get_by_user_and_movie(
            user_id=user_id,
            movie_id=movie_id,
        )

        if entry is None:
            return None

        if status == LibraryStatus.COMPLETED:
            if entry.completed_at is None:
                entry.completed_at = datetime.now(UTC)
        else:
            entry.completed_at = None

        entry.status = status

        self._session.commit()
        self._session.refresh(entry)

        return entry

    def get_entry(
        self,
        *,
        user_id: UUID,
        show_id: UUID,
    ) -> LibraryEntry | None:
        """Backward-compatible alias for getting a TV series Library entry."""

        return self.get_show_entry(
            user_id=user_id,
            show_id=show_id,
        )

    def update_status(
        self,
        *,
        user_id: UUID,
        show_id: UUID,
        status: LibraryStatus,
    ) -> LibraryEntry | None:
        """Backward-compatible alias for updating TV series Library status."""

        return self.update_show_status(
            user_id=user_id,
            show_id=show_id,
            status=status,
        )

    def list_movies_for_user(
        self,
        user_id: UUID,
        *,
        status: LibraryStatus | None = None,
    ) -> list[LibraryEntry]:
        """Return Movie library entries belonging to a user."""

        return self._library_repository.list_movies_by_user(
            user_id,
            status=status,
        )

    def get_preview_for_user(
        self,
        *,
        user_id: UUID,
        limit: int = 10,
    ) -> LibraryPreviewResponse:
        """Return recently added Shows and Movies for the Profile Library preview."""

        show_entries = self._library_repository.list_recent_shows_by_user(
            user_id=user_id,
            limit=limit,
        )

        movie_entries = self._library_repository.list_recent_movies_by_user(
            user_id=user_id,
            limit=limit,
        )

        show_ids = [entry.show_id for entry in show_entries if entry.show_id is not None]

        today = date.today()

        aired_counts = self._episode_repository.get_aired_counts_by_show_ids(
            show_ids=show_ids,
            as_of=today,
        )

        watched_counts = self._episode_progress_repository.get_watched_aired_counts_by_show_ids(
            user_id=user_id,
            show_ids=show_ids,
            as_of=today,
        )

        shows: list[LibraryPreviewShowResponse] = []

        for entry in show_entries:
            if entry.show is None or entry.show_id is None:
                continue

            shows.append(
                LibraryPreviewShowResponse(
                    show=entry.show,
                    watched_episodes=watched_counts.get(
                        entry.show_id,
                        0,
                    ),
                    aired_episodes=aired_counts.get(
                        entry.show_id,
                        0,
                    ),
                )
            )

        movies = [
            LibraryPreviewMovieResponse(
                movie=entry.movie,
            )
            for entry in movie_entries
            if entry.movie is not None
        ]

        total_shows = self._library_repository.count_shows_by_user(
            user_id=user_id,
        )
        total_movies = self._library_repository.count_movies_by_user(
            user_id=user_id,
        )

        return LibraryPreviewResponse(
            total_shows=total_shows,
            total_movies=total_movies,
            shows=shows,
            movies=movies,
        )
