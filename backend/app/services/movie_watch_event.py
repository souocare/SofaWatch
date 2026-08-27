from datetime import UTC, datetime
from uuid import UUID

from sqlalchemy.orm import Session

from app.models.enums import LibraryStatus
from app.models.movie_watch_event import MovieWatchEvent
from app.repositories.library import LibraryRepository
from app.repositories.movie import MovieRepository
from app.repositories.movie_watch_event import MovieWatchEventRepository


class MovieWatchEventService:
    """Business logic for historical Movie viewing events."""

    def __init__(
        self,
        *,
        session: Session,
        movie_repository: MovieRepository,
        library_repository: LibraryRepository,
        watch_event_repository: MovieWatchEventRepository,
    ) -> None:
        self._session = session
        self._movie_repository = movie_repository
        self._library_repository = library_repository
        self._watch_event_repository = watch_event_repository

    def watch(
        self,
        *,
        user_id: UUID,
        movie_id: UUID,
        watched_at: datetime | None = None,
    ) -> MovieWatchEvent | None:
        """Record one real viewing of a locally stored Movie.

        Every invocation represents one viewing event.

        Calling this again for an already completed Movie therefore records
        a Rewatch without moving the Movie's original completion timestamp.
        """

        movie = self._movie_repository.get_by_id(
            movie_id,
        )

        if movie is None:
            return None

        entry = self._library_repository.get_by_user_and_movie(
            user_id=user_id,
            movie_id=movie_id,
        )

        if entry is None:
            return None

        viewed_at = watched_at or datetime.now(UTC)

        event = MovieWatchEvent(
            user_id=user_id,
            movie_id=movie_id,
            watched_at=viewed_at,
        )

        self._watch_event_repository.add(
            event,
        )

        # /*
        #  * Historical watch events are the source of truth for real Movie
        #  * viewings.
        #  *
        #  * The first real viewing moves the Movie to Completed. Rewatches
        #  * create additional events but must not move completed_at forward.
        #  */
        entry.status = LibraryStatus.COMPLETED

        if entry.completed_at is None:
            entry.completed_at = viewed_at

        self._session.commit()
        self._session.refresh(event)

        return event

    def list_for_movie(
        self,
        *,
        user_id: UUID,
        movie_id: UUID,
    ) -> list[MovieWatchEvent]:
        """Return every recorded viewing for a Movie."""

        return self._watch_event_repository.list_by_user_and_movie(
            user_id=user_id,
            movie_id=movie_id,
        )

    def delete(
        self,
        *,
        user_id: UUID,
        movie_id: UUID,
        event_id: UUID,
    ) -> bool:
        """Delete one Movie viewing and synchronize Library state."""

        event = self._watch_event_repository.get_by_id_for_user_and_movie(
            event_id=event_id,
            user_id=user_id,
            movie_id=movie_id,
        )

        if event is None:
            return False

        self._watch_event_repository.delete(
            event,
        )

        # /*
        #  * Ensure the deleted event is no longer visible before determining
        #  * the Movie's remaining historical state.
        #  */
        self._session.flush()

        latest_event = self._watch_event_repository.get_latest_for_user_and_movie(
            user_id=user_id,
            movie_id=movie_id,
        )

        entry = self._library_repository.get_by_user_and_movie(
            user_id=user_id,
            movie_id=movie_id,
        )

        if entry is not None:
            if latest_event is None:
                entry.status = LibraryStatus.PLANNING
                entry.completed_at = None
            else:
                earliest_event = self._watch_event_repository.get_earliest_for_user_and_movie(
                    user_id=user_id,
                    movie_id=movie_id,
                )

                entry.status = LibraryStatus.COMPLETED
                entry.completed_at = (
                    earliest_event.watched_at
                    if earliest_event is not None
                    else latest_event.watched_at
                )

        self._session.commit()

        return True

    def delete_all(
        self,
        *,
        user_id: UUID,
        movie_id: UUID,
    ) -> int:
        """Delete all Movie viewings and return it to the Watchlist.

        The operation is idempotent.
        """

        deleted_count = self._watch_event_repository.delete_all_for_user_and_movie(
            user_id=user_id,
            movie_id=movie_id,
        )

        entry = self._library_repository.get_by_user_and_movie(
            user_id=user_id,
            movie_id=movie_id,
        )

        if entry is not None:
            entry.status = LibraryStatus.PLANNING
            entry.completed_at = None

        self._session.commit()

        return deleted_count
