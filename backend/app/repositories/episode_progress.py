from uuid import UUID

from sqlalchemy import case, func, select
from sqlalchemy.orm import Session
from datetime import date
from dataclasses import dataclass

from app.models.episode import Episode
from app.models.episode_progress import EpisodeProgress
from app.models.season import Season


@dataclass(frozen=True, slots=True)
class NextUnwatchedEpisode:
    """Next aired unwatched Episode for a TV series."""

    show_id: UUID
    episode: Episode
    season_number: int

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

    def list_by_user_and_season(
        self,
        *,
        user_id: UUID,
        season_id: UUID,
    ) -> list[EpisodeProgress]:
        """Return a user's episode progress entries for a season."""

        statement = (
            select(EpisodeProgress)
            .join(
                Episode,
                Episode.id == EpisodeProgress.episode_id,
            )
            .where(
                EpisodeProgress.user_id == user_id,
                Episode.season_id == season_id,
            )
            .order_by(
                Episode.episode_number.asc(),
            )
        )

        return list(
            self._session.scalars(statement).all()
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
                    Season.season_number > 0,
                )
            )
            or 0
        )

    def get_next_unwatched_for_show(
        self,
        *,
        user_id: UUID,
        show_id: UUID,
        as_of: date,
    ) -> Episode | None:
        """Return the next aired unwatched regular episode of a TV series."""

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
                Episode.air_date.is_not(None),
                Episode.air_date <= as_of,
                Episode.id.not_in(watched_episode_ids),
            )
            .order_by(
                Season.season_number.asc(),
                Episode.episode_number.asc(),
            )
            .limit(1)
        )

    def get_next_upcoming_for_show(
        self,
        *,
        show_id: UUID,
        after: date,
    ) -> Episode | None:
        """Return the next future regular episode of a TV series."""

        return self._session.scalar(
            select(Episode)
            .join(
                Season,
                Season.id == Episode.season_id,
            )
            .where(
                Season.show_id == show_id,
                Season.season_number > 0,
                Episode.air_date.is_not(None),
                Episode.air_date > after,
            )
            .order_by(
                Episode.air_date.asc(),
                Season.season_number.asc(),
                Episode.episode_number.asc(),
            )
            .limit(1)
        )

    def count_watched_aired_for_season(
        self,
        *,
        user_id: UUID,
        season_id: UUID,
        as_of: date,
    ) -> int:
        """Count watched aired episodes for a user within a season."""

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
                    Episode.air_date.is_not(None),
                    Episode.air_date <= as_of,
                )
            )
            or 0
        )

    def count_watched_aired_for_show(
        self,
        *,
        user_id: UUID,
        show_id: UUID,
        as_of: date,
    ) -> int:
        """Count watched aired regular episodes for a user within a TV series."""

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
                    Season.season_number > 0,
                    Episode.air_date.is_not(None),
                    Episode.air_date <= as_of,
                )
            )
            or 0
        )

    def get_watched_counts_by_show_id(
        self,
        *,
        user_id: UUID,
        show_id: UUID,
        as_of: date,
    ) -> dict[UUID, tuple[int, int]]:
        """Return watched and watched-aired counts grouped by season."""

        statement = (
            select(
                Episode.season_id,
                func.count(EpisodeProgress.id),
                func.sum(
                    case(
                        (
                            (
                                Episode.air_date.is_not(None)
                                & (Episode.air_date <= as_of)
                            ),
                            1,
                        ),
                        else_=0,
                    )
                ),
            )
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
            .group_by(
                Episode.season_id,
            )
        )

        rows = self._session.execute(
            statement,
        ).all()

        return {
            season_id: (
                int(watched_episodes or 0),
                int(watched_aired_episodes or 0),
            )
            for season_id, watched_episodes, watched_aired_episodes in rows
        }

    def list_next_unwatched_for_shows(
        self,
        *,
        user_id: UUID,
        show_ids: list[UUID],
        as_of: date,
    ) -> dict[UUID, NextUnwatchedEpisode]:
        """Return the next aired unwatched Episode for multiple TV series."""

        if not show_ids:
            return {}

        watched_episode_ids = select(
            EpisodeProgress.episode_id,
        ).where(
            EpisodeProgress.user_id == user_id,
            EpisodeProgress.is_watched.is_(True),
        )

        ranked_episodes = (
            select(
                Season.show_id.label("show_id"),
                Episode.id.label("episode_id"),
                Season.season_number.label("season_number"),
                func.row_number()
                .over(
                    partition_by=Season.show_id,
                    order_by=(
                        Season.season_number.asc(),
                        Episode.episode_number.asc(),
                    ),
                )
                .label("row_number"),
            )
            .join(
                Season,
                Season.id == Episode.season_id,
            )
            .where(
                Season.show_id.in_(show_ids),
                Season.season_number > 0,
                Episode.air_date.is_not(None),
                Episode.air_date <= as_of,
                Episode.id.not_in(watched_episode_ids),
            )
            .subquery()
        )

        statement = (
            select(
                ranked_episodes.c.show_id,
                ranked_episodes.c.season_number,
                Episode,
            )
            .join(
                Episode,
                Episode.id == ranked_episodes.c.episode_id,
            )
            .where(
                ranked_episodes.c.row_number == 1,
            )
        )

        rows = self._session.execute(statement).all()

        return {
            show_id: NextUnwatchedEpisode(
                show_id=show_id,
                episode=episode,
                season_number=season_number,
            )
            for show_id, season_number, episode in rows
        }
