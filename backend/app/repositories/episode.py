from uuid import UUID

from sqlalchemy import case, func, select
from sqlalchemy.orm import Session
from datetime import date

from app.models.episode import Episode
from app.models.season import Season


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

    def count_by_season_id(
        self,
        season_id: UUID,
    ) -> int:
        """Count locally stored episodes belonging to a season."""

        return (
            self._session.scalar(
                select(func.count())
                .select_from(Episode)
                .where(
                    Episode.season_id == season_id,
                )
            )
            or 0
        )

    def count_by_show_id(
        self,
        show_id: UUID,
    ) -> int:
        """Count locally stored episodes belonging to a TV series."""

        return (
            self._session.scalar(
                select(func.count())
                .select_from(Episode)
                .join(
                    Season,
                    Season.id == Episode.season_id,
                )
                .where(
                    Season.show_id == show_id,
                )
            )
            or 0
        )

    def count_aired_by_season_id(
        self,
        season_id: UUID,
        *,
        as_of: date,
    ) -> int:
        """Count aired episodes belonging to a season."""

        return (
            self._session.scalar(
                select(func.count())
                .select_from(Episode)
                .where(
                    Episode.season_id == season_id,
                    Episode.air_date.is_not(None),
                    Episode.air_date <= as_of,
                )
            )
            or 0
        )

    def count_regular_by_show_id(
        self,
        show_id: UUID,
    ) -> int:
        """Count regular locally stored episodes belonging to a TV series."""

        return (
            self._session.scalar(
                select(func.count())
                .select_from(Episode)
                .join(
                    Season,
                    Season.id == Episode.season_id,
                )
                .where(
                    Season.show_id == show_id,
                    Season.season_number > 0,
                )
            )
            or 0
        )

    def count_aired_by_show_id(
        self,
        show_id: UUID,
        *,
        as_of: date,
    ) -> int:
        """Count aired regular episodes belonging to a TV series."""

        return (
            self._session.scalar(
                select(func.count())
                .select_from(Episode)
                .join(
                    Season,
                    Season.id == Episode.season_id,
                )
                .where(
                    Season.show_id == show_id,
                    Season.season_number > 0,
                    Episode.air_date.is_not(None),
                    Episode.air_date <= as_of,
                )
            )
            or 0
        )

    def get_counts_by_show_id(
        self,
        show_id: UUID,
        *,
        as_of: date,
    ) -> dict[UUID, tuple[int, int]]:
        """Return total and aired episode counts grouped by season."""

        statement = (
            select(
                Episode.season_id,
                func.count(Episode.id),
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
            .join(
                Season,
                Season.id == Episode.season_id,
            )
            .where(
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
                int(total_episodes or 0),
                int(aired_episodes or 0),
            )
            for season_id, total_episodes, aired_episodes in rows
        }

    def get_first_aired_regular_for_shows(
        self,
        *,
        show_ids: list[UUID],
        as_of: date,
    ) -> dict[UUID, tuple[Episode, int]]:
        """Return the first aired regular Episode for each TV series."""

        if not show_ids:
            return {}

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
                .label("position"),
            )
            .select_from(Episode)
            .join(
                Season,
                Season.id == Episode.season_id,
            )
            .where(
                Season.show_id.in_(show_ids),
                Season.season_number > 0,
                Episode.air_date.is_not(None),
                Episode.air_date <= as_of,
            )
            .subquery()
        )

        rows = self._session.execute(
            select(
                ranked_episodes.c.show_id,
                Episode,
                ranked_episodes.c.season_number,
            )
            .join(
                Episode,
                Episode.id == ranked_episodes.c.episode_id,
            )
            .where(
                ranked_episodes.c.position == 1,
            )
        ).all()

        return {
            show_id: (
                episode,
                int(season_number),
            )
            for show_id, episode, season_number in rows
        }

    def get_first_aired_regular_for_show(
        self,
        *,
        show_id: UUID,
        as_of: date,
    ) -> tuple[Episode, int] | None:
        """Return the first aired regular Episode of a TV series."""

        row = self._session.execute(
            select(
                Episode,
                Season.season_number,
            )
            .join(
                Season,
                Season.id == Episode.season_id,
            )
            .where(
                Season.show_id == show_id,
                Season.season_number > 0,
                Episode.air_date.is_not(None),
                Episode.air_date <= as_of,
            )
            .order_by(
                Season.season_number.asc(),
                Episode.episode_number.asc(),
            )
            .limit(1)
        ).first()

        if row is None:
            return None

        episode, season_number = row

        return episode, season_number

    def get_aired_counts_by_show_ids(
        self,
        *,
        show_ids: list[UUID],
        as_of: date,
    ) -> dict[UUID, int]:
        """Return aired regular Episode counts grouped by Show."""

        if not show_ids:
            return {}

        statement = (
            select(
                Season.show_id,
                func.count(Episode.id),
            )
            .select_from(Episode)
            .join(
                Season,
                Season.id == Episode.season_id,
            )
            .where(
                Season.show_id.in_(show_ids),
                Season.season_number > 0,
                Episode.air_date.is_not(None),
                Episode.air_date <= as_of,
            )
            .group_by(
                Season.show_id,
            )
        )

        rows = self._session.execute(statement).all()

        return {
            show_id: int(aired_episodes or 0)
            for show_id, aired_episodes in rows
        }