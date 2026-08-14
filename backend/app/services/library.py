from datetime import UTC, date, datetime
from uuid import UUID

from sqlalchemy.orm import Session

from app.models.enums import LibraryStatus
from app.models.library import LibraryEntry
from app.repositories.library import LibraryRepository
from app.repositories.movie import MovieRepository
from app.repositories.show import ShowRepository
from app.repositories.episode import EpisodeRepository
from app.schemas.library import (
    LibraryFirstEpisodeResponse,
    LibraryShowResponse,
)


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
    ) -> None:
        self._session = session
        self._library_repository = library_repository
        self._show_repository = show_repository
        self._movie_repository = movie_repository
        self._episode_repository = episode_repository

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
        """Return TV series in a user's library."""

        entries = self._library_repository.list_shows_by_user(
            user_id,
            status=status,
        )

        planning_show_ids = [
            entry.show_id
            for entry in entries
            if entry.status == LibraryStatus.PLANNING
            and entry.show_id is not None
        ]

        first_episode_by_show = (
            self._episode_repository.get_first_aired_regular_for_shows(
                show_ids=planning_show_ids,
                as_of=date.today(),
            )
        )

        results: list[LibraryShowResponse] = []

        for entry in entries:
            if entry.show is None:
                continue

            first_available_episode = None

            if entry.show_id is not None:
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
        """Return the user's library entry for a movie."""

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
        """Add a locally stored movie to a user's library."""

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
        """Remove a movie from a user's library."""

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

        entry.status = status

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
        """Update the tracking status of a movie."""

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
        """Return the user's library entry for a TV series."""

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
        """Update the tracking status of a TV series."""

        return self.update_show_status(
            user_id=user_id,
            show_id=show_id,
            status=status,
        )

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