from uuid import UUID

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models.episode import Episode
from app.models.episode_progress import EpisodeProgress
from app.models.season import Season


class EpisodeProgressRepository:
    """Persistence operations for episode viewing progress."""

    def __init__(
        self,
        session: Session,
    ) -> None:
        self._session = session

    def get_by_user_and_episode(
        self,
        *,
        user_id: UUID,
        episode_id: UUID,
    ) -> EpisodeProgress | None:
        """Return progress for a user's episode."""

        return self._session.scalar(
            select(EpisodeProgress).where(
                EpisodeProgress.user_id == user_id,
                EpisodeProgress.episode_id == episode_id,
            )
        )

    def add(
        self,
        progress: EpisodeProgress,
    ) -> EpisodeProgress:
        """Add episode progress to the current unit of work."""

        self._session.add(progress)

        return progress

    def count_watched_for_season(
        self,
        *,
        user_id: UUID,
        season_id: UUID,
    ) -> int:
        """Count watched episodes for a user within a season."""

        return (
            self._session.scalar(
                select(func.count())
                .select_from(EpisodeProgress)
                .join(
                    Episode,
                    Episode.id == EpisodeProgress.episode_id,
                )
                .where(
                    EpisodeProgress.user_id == user_id,
                    EpisodeProgress.is_watched.is_(True),
                    Episode.season_id == season_id,
                )
            )
            or 0
        )

    def count_watched_for_show(
        self,
        *,
        user_id: UUID,
        show_id: UUID,
    ) -> int:
        """Count watched episodes for a user within a TV series."""

        return (
            self._session.scalar(
                select(func.count())
                .select_from(EpisodeProgress)
                .join(
                    Episode,
                    Episode.id == EpisodeProgress.episode_id,
                )
                .join(
                    Season,
                    Season.id == Episode.season_id,
                )
                .where(
                    EpisodeProgress.user_id == user_id,
                    EpisodeProgress.is_watched.is_(True),
                    Season.show_id == show_id,
                )
            )
            or 0
        )

    def get_next_unwatched_for_show(
        self,
        *,
        user_id: UUID,
        show_id: UUID,
    ) -> Episode | None:
        """Return the next unwatched episode of a TV series."""

        watched_episode_ids = select(EpisodeProgress.episode_id).where(
            EpisodeProgress.user_id == user_id,
            EpisodeProgress.is_watched.is_(True),
        )

        return self._session.scalar(
            select(Episode)
            .join(
                Season,
                Season.id == Episode.season_id,
            )
            .where(
                Season.show_id == show_id,
                Season.season_number > 0,
                Episode.id.not_in(watched_episode_ids),
            )
            .order_by(
                Season.season_number.asc(),
                Episode.episode_number.asc(),
            )
            .limit(1)
        )
