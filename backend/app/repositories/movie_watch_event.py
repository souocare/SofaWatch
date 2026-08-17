from datetime import datetime
from uuid import UUID

from sqlalchemy import delete as sqlalchemy_delete, func, select
from sqlalchemy.orm import Session

from app.models.movie_watch_event import MovieWatchEvent
from app.models.movie import Movie


class MovieWatchEventRepository:
    """Persistence operations for historical Movie watch events."""

    def __init__(
        self,
        session: Session,
    ) -> None:
        self._session = session

    def add(
        self,
        event: MovieWatchEvent,
    ) -> MovieWatchEvent:
        """Add a Movie watch event to the current unit of work."""

        self._session.add(event)

        return event

    def get_by_id(
        self,
        event_id: UUID,
    ) -> MovieWatchEvent | None:
        """Return a Movie watch event by identifier."""

        return self._session.get(
            MovieWatchEvent,
            event_id,
        )

    def get_by_id_for_user_and_movie(
        self,
        *,
        event_id: UUID,
        user_id: UUID,
        movie_id: UUID,
    ) -> MovieWatchEvent | None:
        """Return an event owned by the user and belonging to the Movie."""

        return self._session.scalar(
            select(MovieWatchEvent).where(
                MovieWatchEvent.id == event_id,
                MovieWatchEvent.user_id == user_id,
                MovieWatchEvent.movie_id == movie_id,
            )
        )

    def list_by_user_and_movie(
        self,
        *,
        user_id: UUID,
        movie_id: UUID,
    ) -> list[MovieWatchEvent]:
        """Return all historical viewings for a Movie, newest first."""

        return list(
            self._session.scalars(
                select(MovieWatchEvent)
                .where(
                    MovieWatchEvent.user_id == user_id,
                    MovieWatchEvent.movie_id == movie_id,
                )
                .order_by(
                    MovieWatchEvent.watched_at.desc(),
                    MovieWatchEvent.id.desc(),
                )
            ).all()
        )

    def count_by_user_and_movie(
        self,
        *,
        user_id: UUID,
        movie_id: UUID,
    ) -> int:
        """Return how many times a user watched a Movie."""

        return (
            self._session.scalar(
                select(func.count())
                .select_from(MovieWatchEvent)
                .where(
                    MovieWatchEvent.user_id == user_id,
                    MovieWatchEvent.movie_id == movie_id,
                )
            )
            or 0
        )

    def get_latest_for_user_and_movie(
        self,
        *,
        user_id: UUID,
        movie_id: UUID,
    ) -> MovieWatchEvent | None:
        """Return the most recent viewing of a Movie."""

        return self._session.scalar(
            select(MovieWatchEvent)
            .where(
                MovieWatchEvent.user_id == user_id,
                MovieWatchEvent.movie_id == movie_id,
            )
            .order_by(
                MovieWatchEvent.watched_at.desc(),
                MovieWatchEvent.id.desc(),
            )
            .limit(1)
        )

    def get_earliest_for_user_and_movie(
        self,
        *,
        user_id: UUID,
        movie_id: UUID,
    ) -> MovieWatchEvent | None:
        """Return the oldest recorded viewing of a Movie."""

        return self._session.scalar(
            select(MovieWatchEvent)
            .where(
                MovieWatchEvent.user_id == user_id,
                MovieWatchEvent.movie_id == movie_id,
            )
            .order_by(
                MovieWatchEvent.watched_at.asc(),
                MovieWatchEvent.id.asc(),
            )
            .limit(1)
        )

    def get_statistics_for_period(
        self,
        *,
        user_id: UUID,
        start_at: datetime,
        end_at: datetime,
    ) -> tuple[int, int]:
        """Return Movie viewing count and known watch time for a period.

        Every historical Movie watch event is counted independently, so
        rewatches contribute again to both the viewing count and watch time.

        Movies without a known runtime still contribute to the viewing count
        but add zero minutes to watch time.

        ``end_at`` is exclusive.
        """

        row = self._session.execute(
            select(
                func.count(MovieWatchEvent.id),
                func.coalesce(
                    func.sum(Movie.runtime),
                    0,
                ),
            )
            .select_from(MovieWatchEvent)
            .join(
                Movie,
                Movie.id == MovieWatchEvent.movie_id,
            )
            .where(
                MovieWatchEvent.user_id == user_id,
                MovieWatchEvent.watched_at >= start_at,
                MovieWatchEvent.watched_at < end_at,
            )
        ).one()

        return (
            int(row[0] or 0),
            int(row[1] or 0),
        )

    def delete(
        self,
        event: MovieWatchEvent,
    ) -> None:
        """Delete one Movie watch event."""

        self._session.delete(event)

    def delete_all_for_user_and_movie(
        self,
        *,
        user_id: UUID,
        movie_id: UUID,
    ) -> int:
        """Delete every historical viewing for a user's Movie."""

        result = self._session.execute(
            sqlalchemy_delete(MovieWatchEvent).where(
                MovieWatchEvent.user_id == user_id,
                MovieWatchEvent.movie_id == movie_id,
            )
        )

        return int(result.rowcount or 0)