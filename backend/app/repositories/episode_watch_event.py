from dataclasses import dataclass
from datetime import datetime
from uuid import UUID

from sqlalchemy import delete as sqlalchemy_delete, func, select
from sqlalchemy.orm import Session

from app.models.episode import Episode
from app.models.episode_watch_event import EpisodeWatchEvent
from app.models.season import Season
from app.models.show import Show
from app.repositories.viewing_statistics import DailyViewingStatistics
from app.models.genre import Genre
from app.repositories.statistics_insights import (
    EpisodeViewingInsight,
    GenreViewingInsight,
    ShowViewingInsight,
    
)


@dataclass(frozen=True, slots=True)
class WatchHistoryEvent:
    """One historical Episode viewing displayed in Watch History."""

    event_id: UUID
    show: Show
    episode: Episode
    season_number: int
    watched_at: datetime


@dataclass(frozen=True, slots=True)
class WatchHistoryEventPage:
    """One cursor-paginated page of historical Episode viewings."""

    items: list[WatchHistoryEvent]
    has_more: bool



class EpisodeWatchEventRepository:
    """Persistence operations for historical Episode watch events."""

    def __init__(
        self,
        session: Session,
    ) -> None:
        self._session = session

    def add(
        self,
        event: EpisodeWatchEvent,
    ) -> EpisodeWatchEvent:
        """Add a watch event to the current unit of work."""

        self._session.add(event)

        return event

    def get_by_id(
        self,
        event_id: UUID,
    ) -> EpisodeWatchEvent | None:
        """Return a watch event by its identifier."""

        return self._session.get(
            EpisodeWatchEvent,
            event_id,
        )

    def get_by_id_for_user(
        self,
        *,
        event_id: UUID,
        user_id: UUID,
    ) -> EpisodeWatchEvent | None:
        """Return a watch event when it belongs to the requested user."""

        return self._session.scalar(
            select(EpisodeWatchEvent).where(
                EpisodeWatchEvent.id == event_id,
                EpisodeWatchEvent.user_id == user_id,
            )
        )

    def get_by_id_for_user_and_episode(
        self,
        *,
        event_id: UUID,
        user_id: UUID,
        episode_id: UUID,
    ) -> EpisodeWatchEvent | None:
        """Return a watch event owned by the user and Episode."""

        return self._session.scalar(
            select(EpisodeWatchEvent).where(
                EpisodeWatchEvent.id == event_id,
                EpisodeWatchEvent.user_id == user_id,
                EpisodeWatchEvent.episode_id == episode_id,
            )
        )

    def list_by_user_and_episode(
        self,
        *,
        user_id: UUID,
        episode_id: UUID,
    ) -> list[EpisodeWatchEvent]:
        """Return all watch events for an Episode, newest first."""

        return list(
            self._session.scalars(
                select(EpisodeWatchEvent)
                .where(
                    EpisodeWatchEvent.user_id == user_id,
                    EpisodeWatchEvent.episode_id == episode_id,
                )
                .order_by(
                    EpisodeWatchEvent.watched_at.desc(),
                    EpisodeWatchEvent.id.desc(),
                )
            ).all()
        )

    def count_by_user_and_episode(
        self,
        *,
        user_id: UUID,
        episode_id: UUID,
    ) -> int:
        """Return how many times the user watched an Episode."""

        return (
            self._session.scalar(
                select(func.count())
                .select_from(EpisodeWatchEvent)
                .where(
                    EpisodeWatchEvent.user_id == user_id,
                    EpisodeWatchEvent.episode_id == episode_id,
                )
            )
            or 0
        )

    def get_latest_for_user_and_episode(
        self,
        *,
        user_id: UUID,
        episode_id: UUID,
    ) -> EpisodeWatchEvent | None:
        """Return the most recent watch event for an Episode."""

        return self._session.scalar(
            select(EpisodeWatchEvent)
            .where(
                EpisodeWatchEvent.user_id == user_id,
                EpisodeWatchEvent.episode_id == episode_id,
            )
            .order_by(
                EpisodeWatchEvent.watched_at.desc(),
                EpisodeWatchEvent.id.desc(),
            )
            .limit(1)
        )

    def list_watch_history(
        self,
        *,
        user_id: UUID,
        limit: int = 30,
        before_watched_at: datetime | None = None,
        before_event_id: UUID | None = None,
    ) -> WatchHistoryEventPage:
        """Return one cursor-paginated page of viewing events.

        Every result represents one real viewing event. Rewatching the same
        Episode therefore produces multiple Watch History entries.

        Results are ordered newest first. The cursor combines ``watched_at``
        with ``event_id`` so pagination remains deterministic when multiple
        events have the same viewing timestamp.
        """

        if limit <= 0:
            return WatchHistoryEventPage(
                items=[],
                has_more=False,
            )

        if (before_watched_at is None) != (before_event_id is None):
            raise ValueError(
                "Watch History cursor requires both "
                "before_watched_at and before_event_id."
            )

        statement = (
            select(
                EpisodeWatchEvent.id,
                Show,
                Season.season_number,
                EpisodeWatchEvent.watched_at,
                Episode,
            )
            .select_from(EpisodeWatchEvent)
            .join(
                Episode,
                Episode.id == EpisodeWatchEvent.episode_id,
            )
            .join(
                Season,
                Season.id == Episode.season_id,
            )
            .join(
                Show,
                Show.id == Season.show_id,
            )
            .where(
                EpisodeWatchEvent.user_id == user_id,
                Season.season_number > 0,
            )
        )

        if before_watched_at is not None and before_event_id is not None:
            statement = statement.where(
                (
                    EpisodeWatchEvent.watched_at
                    < before_watched_at
                )
                | (
                    (
                        EpisodeWatchEvent.watched_at
                        == before_watched_at
                    )
                    & (
                        EpisodeWatchEvent.id
                        < before_event_id
                    )
                )
            )

        statement = statement.order_by(
            EpisodeWatchEvent.watched_at.desc(),
            EpisodeWatchEvent.id.desc(),
        ).limit(limit + 1)

        rows = self._session.execute(
            statement,
        ).all()

        has_more = len(rows) > limit

        page_rows = rows[:limit]

        items = [
            WatchHistoryEvent(
                event_id=event_id,
                show=show,
                episode=episode,
                season_number=season_number,
                watched_at=watched_at,
            )
            for (
                event_id,
                show,
                season_number,
                watched_at,
                episode,
            ) in page_rows
        ]

        return WatchHistoryEventPage(
            items=items,
            has_more=has_more,
        )

    def get_counts_by_user_and_episode_ids(
        self,
        *,
        user_id: UUID,
        episode_ids: list[UUID],
    ) -> dict[UUID, int]:
        """Return watch event counts grouped by Episode."""

        if not episode_ids:
            return {}

        statement = (
            select(
                EpisodeWatchEvent.episode_id,
                func.count(EpisodeWatchEvent.id),
            )
            .where(
                EpisodeWatchEvent.user_id == user_id,
                EpisodeWatchEvent.episode_id.in_(episode_ids),
            )
            .group_by(
                EpisodeWatchEvent.episode_id,
            )
        )

        rows = self._session.execute(
            statement,
        ).all()

        return {
            episode_id: int(watch_count or 0)
            for episode_id, watch_count in rows
        }

    def get_statistics_for_period(
        self,
        *,
        user_id: UUID,
        start_at: datetime,
        end_at: datetime,
    ) -> tuple[int, int]:
        """Return Episode viewing count and known watch time for a period.

        Every historical watch event is counted independently, therefore
        rewatches contribute again to both the viewing count and watch time.

        Episodes without a known runtime still contribute to the viewing
        count but add zero minutes to watch time.

        ``end_at`` is exclusive.
        """

        row = self._session.execute(
            select(
                func.count(EpisodeWatchEvent.id),
                func.coalesce(
                    func.sum(Episode.runtime),
                    0,
                ),
            )
            .select_from(EpisodeWatchEvent)
            .join(
                Episode,
                Episode.id == EpisodeWatchEvent.episode_id,
            )
            .where(
                EpisodeWatchEvent.user_id == user_id,
                EpisodeWatchEvent.watched_at >= start_at,
                EpisodeWatchEvent.watched_at < end_at,
            )
        ).one()

        return (
            int(row[0] or 0),
            int(row[1] or 0),
        )


    def get_daily_statistics_for_period(
        self,
        *,
        user_id: UUID,
        start_at: datetime,
        end_at: datetime,
    ) -> list[DailyViewingStatistics]:
        """Return Episode viewing statistics grouped by calendar day.

        Every historical watch event contributes independently, so rewatches
        are included in both the viewing count and watch time.

        Episodes without a known runtime contribute zero minutes.

        Only days containing viewing activity are returned. Filling missing
        calendar days with zero values is the responsibility of the service.

        ``end_at`` is exclusive.
        """

        watched_day = func.date(
            EpisodeWatchEvent.watched_at,
        )

        rows = self._session.execute(
            select(
                watched_day.label("day"),
                func.count(
                    EpisodeWatchEvent.id,
                ),
                func.coalesce(
                    func.sum(Episode.runtime),
                    0,
                ),
            )
            .select_from(EpisodeWatchEvent)
            .join(
                Episode,
                Episode.id == EpisodeWatchEvent.episode_id,
            )
            .where(
                EpisodeWatchEvent.user_id == user_id,
                EpisodeWatchEvent.watched_at >= start_at,
                EpisodeWatchEvent.watched_at < end_at,
            )
            .group_by(
                watched_day,
            )
            .order_by(
                watched_day.asc(),
            )
        ).all()

        return [
            DailyViewingStatistics(
                day=str(day),
                watch_count=int(watch_count or 0),
                watch_time_minutes=int(
                    watch_time_minutes or 0,
                ),
            )
            for (
                day,
                watch_count,
                watch_time_minutes,
            ) in rows
        ]


    def get_all_time_statistics(
        self,
        *,
        user_id: UUID,
    ) -> tuple[int, int, int, int, int]:
        """Return all-time Episode viewing statistics for a user.

        The returned tuple contains:

        1. total watch events;
        2. unique Episodes watched;
        3. rewatch events;
        4. total known watch time in minutes;
        5. rewatch watch time in minutes.

        Every historical watch event contributes to the total viewing count
        and total watch time.

        For each Episode, only its first recorded viewing contributes to the
        unique count. Every additional viewing is considered a Rewatch.

        Episodes without a known runtime still contribute to viewing counts,
        but add zero minutes to watch-time values.
        """

        per_episode = (
            select(
                EpisodeWatchEvent.episode_id.label(
                    "episode_id",
                ),
                func.count(
                    EpisodeWatchEvent.id,
                ).label(
                    "watch_count",
                ),
                func.coalesce(
                    Episode.runtime,
                    0,
                ).label(
                    "runtime",
                ),
            )
            .select_from(EpisodeWatchEvent)
            .join(
                Episode,
                Episode.id == EpisodeWatchEvent.episode_id,
            )
            .where(
                EpisodeWatchEvent.user_id == user_id,
            )
            .group_by(
                EpisodeWatchEvent.episode_id,
                Episode.runtime,
            )
            .subquery()
        )

        row = self._session.execute(
            select(
                func.coalesce(
                    func.sum(per_episode.c.watch_count),
                    0,
                ),
                func.count(
                    per_episode.c.episode_id,
                ),
                func.coalesce(
                    func.sum(
                        per_episode.c.watch_count - 1,
                    ),
                    0,
                ),
                func.coalesce(
                    func.sum(
                        per_episode.c.watch_count
                        * per_episode.c.runtime,
                    ),
                    0,
                ),
                func.coalesce(
                    func.sum(
                        (per_episode.c.watch_count - 1)
                        * per_episode.c.runtime,
                    ),
                    0,
                ),
            )
        ).one()

        return (
            int(row[0] or 0),
            int(row[1] or 0),
            int(row[2] or 0),
            int(row[3] or 0),
            int(row[4] or 0),
        )


    def count_watched_shows(
        self,
        *,
        user_id: UUID,
    ) -> int:
        """Return the number of distinct Shows with at least one watch event."""

        count = self._session.scalar(
            select(
                func.count(
                    func.distinct(
                        Season.show_id,
                    )
                )
            )
            .select_from(EpisodeWatchEvent)
            .join(
                Episode,
                Episode.id == EpisodeWatchEvent.episode_id,
            )
            .join(
                Season,
                Season.id == Episode.season_id,
            )
            .where(
                EpisodeWatchEvent.user_id == user_id,
            )
        )

        return int(count or 0)


    def get_lifetime_statistics(
        self,
        *,
        user_id: UUID,
    ) -> tuple[int, int, int]:
        """Return lifetime Episode viewing statistics for one user.

        The returned values are:

        - number of Episode watch events;
        - number of distinct Shows with at least one watched Episode;
        - total known Episode watch time in minutes.

        Every watch event contributes independently to the Episode count
        and watch time, so rewatches are counted again.

        A Show is counted only once regardless of how many Episodes or
        rewatches it contains.
        """

        row = self._session.execute(
            select(
                func.count(EpisodeWatchEvent.id),
                func.count(
                    func.distinct(Season.show_id),
                ),
                func.coalesce(
                    func.sum(Episode.runtime),
                    0,
                ),
            )
            .select_from(EpisodeWatchEvent)
            .join(
                Episode,
                Episode.id == EpisodeWatchEvent.episode_id,
            )
            .join(
                Season,
                Season.id == Episode.season_id,
            )
            .where(
                EpisodeWatchEvent.user_id == user_id,
            )
        ).one()

        return (
            int(row[0] or 0),
            int(row[1] or 0),
            int(row[2] or 0),
        )

    def get_earliest_watched_at_for_user(
        self,
        *,
        user_id: UUID,
    ) -> datetime | None:
        """Return the user's earliest recorded Episode viewing."""

        return self._session.scalar(
            select(
                func.min(
                    EpisodeWatchEvent.watched_at,
                )
            ).where(
                EpisodeWatchEvent.user_id == user_id,
            )
        )

    def get_most_watched_shows(
        self,
        *,
        user_id: UUID,
        limit: int = 5,
        ) -> list[ShowViewingInsight]:
        """Return Shows ranked by total Episode watch events."""

        watch_count = func.count(
            EpisodeWatchEvent.id,
        )

        rows = self._session.execute(
            select(
                Show.id,
                Show.tmdb_id,
                Show.title,
                Show.local_poster_path,
                Show.tmdb_poster_path,
                watch_count.label("watch_count"),
            )
            .select_from(EpisodeWatchEvent)
            .join(
                Episode,
                Episode.id == EpisodeWatchEvent.episode_id,
            )
            .join(
                Season,
                Season.id == Episode.season_id,
            )
            .join(
                Show,
                Show.id == Season.show_id,
            )
            .where(
                EpisodeWatchEvent.user_id == user_id,
            )
            .group_by(
                Show.id,
                Show.tmdb_id,
                Show.title,
                Show.local_poster_path,
                Show.tmdb_poster_path,
            )
            .order_by(
                watch_count.desc(),
                Show.title.asc(),
            )
            .limit(limit)
        ).all()

        return [
            ShowViewingInsight(
                show_id=show_id,
                tmdb_id=int(tmdb_id),
                title=title,
                poster_url=(
                    f"/api/v1/images/shows/{show_id}/poster"
                    if local_poster_path or tmdb_poster_path
                    else None
                ),
                watch_count=int(total_watch_count),
            )
            for (
                show_id,
                tmdb_id,
                title,
                local_poster_path,
                tmdb_poster_path,
                total_watch_count,
            ) in rows
        ]

    def get_most_rewatched_shows(
        self,
        *,
        user_id: UUID,
        limit: int = 5,
    ) -> list[ShowViewingInsight]:
        """Return Shows ranked by Episode rewatch count."""

        per_episode = (
            select(
                Season.show_id.label("show_id"),
                Episode.id.label("episode_id"),
                func.count(
                    EpisodeWatchEvent.id,
                ).label("watch_count"),
            )
            .select_from(EpisodeWatchEvent)
            .join(
                Episode,
                Episode.id == EpisodeWatchEvent.episode_id,
            )
            .join(
                Season,
                Season.id == Episode.season_id,
            )
            .where(
                EpisodeWatchEvent.user_id == user_id,
            )
            .group_by(
                Season.show_id,
                Episode.id,
            )
            .subquery()
        )

        total_watch_count = func.sum(
            per_episode.c.watch_count,
        )

        rewatch_count = func.sum(
            per_episode.c.watch_count - 1,
        )

        rows = self._session.execute(
            select(
                Show.id,
                Show.tmdb_id,
                Show.title,
                Show.local_poster_path,
                Show.tmdb_poster_path,
                total_watch_count.label("watch_count"),
                rewatch_count.label("rewatch_count"),
            )
            .join(
                per_episode,
                per_episode.c.show_id == Show.id,
            )
            .group_by(
                Show.id,
                Show.tmdb_id,
                Show.title,
                Show.local_poster_path,
                Show.tmdb_poster_path,
            )
            .having(
                rewatch_count > 0,
            )
            .order_by(
                rewatch_count.desc(),
                total_watch_count.desc(),
                Show.title.asc(),
            )
            .limit(limit)
        ).all()

        return [
            ShowViewingInsight(
                show_id=show_id,
                tmdb_id=int(tmdb_id),
                title=title,
                poster_url=(
                    f"/api/v1/images/shows/{show_id}/poster"
                    if local_poster_path or tmdb_poster_path
                    else None
                ),
                watch_count=int(watch_count),
                rewatch_count=int(rewatch_count_value),
            )
            for (
                show_id,
                tmdb_id,
                title,
                local_poster_path,
                tmdb_poster_path,
                watch_count,
                rewatch_count_value,
            ) in rows
        ]

    def get_most_rewatched_episodes(
        self,
        *,
        user_id: UUID,
        limit: int = 5,
    ) -> list[EpisodeViewingInsight]:
        """Return Episodes ranked by rewatch count."""

        watch_count = func.count(
            EpisodeWatchEvent.id,
        )

        rows = self._session.execute(
            select(
                Episode.id,
                Show.tmdb_id,
                Show.title,
                Season.season_number,
                Episode.episode_number,
                Episode.title,
                Episode.local_still_path,
                Episode.tmdb_still_path,
                watch_count.label("watch_count"),
            )
            .select_from(EpisodeWatchEvent)
            .join(
                Episode,
                Episode.id == EpisodeWatchEvent.episode_id,
            )
            .join(
                Season,
                Season.id == Episode.season_id,
            )
            .join(
                Show,
                Show.id == Season.show_id,
            )
            .where(
                EpisodeWatchEvent.user_id == user_id,
            )
            .group_by(
                Episode.id,
                Show.tmdb_id,
                Show.title,
                Season.season_number,
                Episode.episode_number,
                Episode.title,
                Episode.local_still_path,
                Episode.tmdb_still_path,
            )
            .having(
                watch_count > 1,
            )
            .order_by(
                watch_count.desc(),
                Show.title.asc(),
                Season.season_number.asc(),
                Episode.episode_number.asc(),
            )
            .limit(limit)
        ).all()

        return [
            EpisodeViewingInsight(
                episode_id=episode_id,
                show_tmdb_id=int(show_tmdb_id),
                show_title=show_title,
                season_number=int(season_number),
                episode_number=int(episode_number),
                episode_title=episode_title,
                still_url=(
                    f"/api/v1/images/episodes/{episode_id}/still"
                    if local_still_path or tmdb_still_path
                    else None
                ),
                watch_count=int(total_watch_count),
                rewatch_count=int(total_watch_count) - 1,
            )
            for (
                episode_id,
                show_tmdb_id,
                show_title,
                season_number,
                episode_number,
                episode_title,
                local_still_path,
                tmdb_still_path,
                total_watch_count,
            ) in rows
        ]

    def get_top_show_genres(
        self,
        *,
        user_id: UUID,
        limit: int = 5,
    ) -> list[GenreViewingInsight]:
        """Return Show Genres ranked by Episode watch events."""

        watch_count = func.count(
            EpisodeWatchEvent.id,
        )

        rows = self._session.execute(
            select(
                Genre.id,
                Genre.name,
                watch_count.label("watch_count"),
            )
            .select_from(EpisodeWatchEvent)
            .join(
                Episode,
                Episode.id == EpisodeWatchEvent.episode_id,
            )
            .join(
                Season,
                Season.id == Episode.season_id,
            )
            .join(
                Show,
                Show.id == Season.show_id,
            )
            .join(
                Show.genres,
            )
            .where(
                EpisodeWatchEvent.user_id == user_id,
            )
            .group_by(
                Genre.id,
                Genre.name,
            )
            .order_by(
                watch_count.desc(),
                Genre.name.asc(),
            )
            .limit(limit)
        ).all()

        return [
            GenreViewingInsight(
                genre_id=int(genre_id),
                name=name,
                watch_count=int(total_watch_count),
            )
            for (
                genre_id,
                name,
                total_watch_count,
            ) in rows
        ]

    def delete_all_for_user_and_episode(
        self,
        *,
        user_id: UUID,
        episode_id: UUID,
    ) -> int:
        """Delete every watch event for a user's Episode.

        Return the number of deleted viewing events.
        """

        result = self._session.execute(
            sqlalchemy_delete(EpisodeWatchEvent).where(
                EpisodeWatchEvent.user_id == user_id,
                EpisodeWatchEvent.episode_id == episode_id,
            )
        )

        return int(result.rowcount or 0)

    def delete(
        self,
        event: EpisodeWatchEvent,
    ) -> None:
        """Delete a watch event from the current unit of work."""

        self._session.delete(event)