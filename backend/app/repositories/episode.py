from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.episode import Episode


class EpisodeRepository:
    """Persistence operations for locally stored TV episodes."""

    def __init__(
        self,
        session: Session,
    ) -> None:
        self._session = session

    def get_by_id(
        self,
        episode_id: UUID,
    ) -> Episode | None:
        """Return an episode by its internal identifier."""

        return self._session.get(
            Episode,
            episode_id,
        )

    def get_by_tmdb_id(
        self,
        tmdb_id: int,
    ) -> Episode | None:
        """Return an episode by its TMDB identifier."""

        return self._session.scalar(
            select(Episode).where(
                Episode.tmdb_id == tmdb_id,
            )
        )

    def get_by_number(
        self,
        *,
        season_id: UUID,
        episode_number: int,
    ) -> Episode | None:
        """Return an episode by season and episode number."""

        return self._session.scalar(
            select(Episode).where(
                Episode.season_id == season_id,
                Episode.episode_number == episode_number,
            )
        )

    def list_by_season_id(
        self,
        season_id: UUID,
    ) -> list[Episode]:
        """Return all episodes of a season."""

        return list(
            self._session.scalars(
                select(Episode)
                .where(
                    Episode.season_id == season_id,
                )
                .order_by(
                    Episode.episode_number,
                )
            ).all()
        )

    def add(
        self,
        episode: Episode,
    ) -> Episode:
        """Add an episode to the current unit of work."""

        self._session.add(episode)

        return episode