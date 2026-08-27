from datetime import datetime
from uuid import UUID

from app.repositories.episode_watch_event import (
    EpisodeWatchEventRepository,
    WatchHistoryEvent,
    WatchHistoryEventPage,
)
from app.repositories.movie_watch_event import (
    MovieWatchEventRepository,
    MovieWatchHistoryEvent,
    MovieWatchHistoryEventPage,
)
from app.schemas.history import (
    HistoryEpisodeItemResponse,
    HistoryEpisodeResponse,
    HistoryMovieItemResponse,
    HistoryPageResponse,
    HistoryPreviewResponse,
)
from app.services.history_cursor import (
    HistoryCursor,
    HistoryCursorCodec,
)

_HISTORY_MEDIA_RANK = {
    "episode": 0,
    "movie": 1,
}


class HistoryService:
    """Build Profile previews and the combined viewing History timeline."""

    def __init__(
        self,
        *,
        episode_watch_event_repository: EpisodeWatchEventRepository,
        movie_watch_event_repository: MovieWatchEventRepository,
    ) -> None:
        self._episode_watch_event_repository = episode_watch_event_repository
        self._movie_watch_event_repository = movie_watch_event_repository

    def get_preview(
        self,
        *,
        user_id: UUID,
        limit: int = 5,
    ) -> HistoryPreviewResponse:
        """Return compact recent Episode and Movie History collections."""

        episode_page = self._episode_watch_event_repository.list_watch_history(
            user_id=user_id,
            limit=limit,
        )

        movie_page = self._movie_watch_event_repository.list_watch_history(
            user_id=user_id,
            limit=limit,
        )

        return HistoryPreviewResponse(
            episodes=[self._build_episode_item(item) for item in episode_page.items],
            movies=[self._build_movie_item(item) for item in movie_page.items],
        )

    def list_for_user(
        self,
        *,
        user_id: UUID,
        limit: int = 30,
        cursor: str | None = None,
    ) -> HistoryPageResponse:
        """Return one page of combined Episode and Movie viewing History."""

        if limit <= 0:
            return HistoryPageResponse(
                items=[],
                next_cursor=None,
                has_more=False,
            )

        decoded_cursor = HistoryCursorCodec.decode(cursor) if cursor is not None else None

        # /*
        #  * Each source contributes at most ``limit + 1`` candidates.
        #  *
        #  * The final limit is applied only after the two independently
        #  * ordered timelines are merged.
        #  */
        source_limit = limit + 1

        episode_page = self._load_episode_candidates(
            user_id=user_id,
            limit=source_limit,
            cursor=decoded_cursor,
        )

        movie_page = self._load_movie_candidates(
            user_id=user_id,
            limit=source_limit,
            cursor=decoded_cursor,
        )

        combined: list[HistoryEpisodeItemResponse | HistoryMovieItemResponse] = [
            *[self._build_episode_item(item) for item in episode_page.items],
            *[self._build_movie_item(item) for item in movie_page.items],
        ]

        # /*
        #  * Repository boundaries deliberately work at source level.
        #  *
        #  * Keep this final combined cursor filter as a defensive guarantee
        #  * that no boundary event can be emitted twice.
        #  */
        if decoded_cursor is not None:
            combined = [
                item
                for item in combined
                if self._is_after_cursor(
                    watched_at=item.watched_at,
                    media_type=item.media_type,
                    event_id=item.event_id,
                    cursor=decoded_cursor,
                )
            ]

        combined.sort(
            key=self._sort_key,
            reverse=True,
        )

        has_more = len(combined) > limit or episode_page.has_more or movie_page.has_more

        page_items = combined[:limit]

        next_cursor: str | None = None

        if has_more and page_items:
            last_item = page_items[-1]

            next_cursor = HistoryCursorCodec.encode(
                HistoryCursor(
                    watched_at=last_item.watched_at,
                    media_type=last_item.media_type,
                    event_id=last_item.event_id,
                )
            )

        return HistoryPageResponse(
            items=page_items,
            next_cursor=next_cursor,
            has_more=has_more,
        )

    def _load_episode_candidates(
        self,
        *,
        user_id: UUID,
        limit: int,
        cursor: HistoryCursor | None,
    ) -> WatchHistoryEventPage:
        """Load Episode candidates valid after the combined cursor."""

        if cursor is None:
            return self._episode_watch_event_repository.list_watch_history(
                user_id=user_id,
                limit=limit,
            )

        if cursor.media_type == "episode":
            # /*
            #  * Same source as the cursor:
            #  * use its normal deterministic (watched_at, event_id) cursor.
            #  */
            return self._episode_watch_event_repository.list_watch_history(
                user_id=user_id,
                limit=limit,
                before_watched_at=cursor.watched_at,
                before_event_id=cursor.event_id,
            )

        # /*
        #  * Movie sorts before Episode when watched_at is equal.
        #  *
        #  * Therefore, after a Movie cursor, Episodes occurring at exactly the
        #  * same timestamp still belong to the following combined page.
        #  */
        return self._episode_watch_event_repository.list_watch_history_before_timestamp(
            user_id=user_id,
            limit=limit,
            watched_at=cursor.watched_at,
            inclusive=True,
        )

    def _load_movie_candidates(
        self,
        *,
        user_id: UUID,
        limit: int,
        cursor: HistoryCursor | None,
    ) -> MovieWatchHistoryEventPage:
        """Load Movie candidates valid after the combined cursor."""

        if cursor is None:
            return self._movie_watch_event_repository.list_watch_history(
                user_id=user_id,
                limit=limit,
            )

        if cursor.media_type == "movie":
            # /*
            #  * Same source as the cursor:
            #  * use its normal deterministic (watched_at, event_id) cursor.
            #  */
            return self._movie_watch_event_repository.list_watch_history(
                user_id=user_id,
                limit=limit,
                before_watched_at=cursor.watched_at,
                before_event_id=cursor.event_id,
            )

        # /*
        #  * Movie sorts before Episode when watched_at is equal.
        #  *
        #  * Therefore, after an Episode cursor, Movies from the same timestamp
        #  * were already before the cursor and must not be returned again.
        #  */
        return self._movie_watch_event_repository.list_watch_history_before_timestamp(
            user_id=user_id,
            limit=limit,
            watched_at=cursor.watched_at,
            inclusive=False,
        )

    @staticmethod
    def _build_episode_item(
        history_item: WatchHistoryEvent,
    ) -> HistoryEpisodeItemResponse:
        episode = history_item.episode

        return HistoryEpisodeItemResponse(
            event_id=history_item.event_id,
            watched_at=history_item.watched_at,
            show=history_item.show,
            episode=HistoryEpisodeResponse(
                id=episode.id,
                tmdb_id=episode.tmdb_id,
                season_number=history_item.season_number,
                episode_number=episode.episode_number,
                title=episode.title,
                air_date=episode.air_date,
                runtime=episode.runtime,
                still_url=episode.still_url,
            ),
        )

    @staticmethod
    def _build_movie_item(
        history_item: MovieWatchHistoryEvent,
    ) -> HistoryMovieItemResponse:
        return HistoryMovieItemResponse(
            event_id=history_item.event_id,
            watched_at=history_item.watched_at,
            movie=history_item.movie,
        )

    @staticmethod
    def _sort_key(
        item: HistoryEpisodeItemResponse | HistoryMovieItemResponse,
    ) -> tuple[datetime, int, UUID]:
        return (
            item.watched_at,
            _HISTORY_MEDIA_RANK[item.media_type],
            item.event_id,
        )

    @staticmethod
    def _is_after_cursor(
        *,
        watched_at: datetime,
        media_type: str,
        event_id: UUID,
        cursor: HistoryCursor,
    ) -> bool:
        candidate = (
            watched_at,
            _HISTORY_MEDIA_RANK[media_type],
            event_id,
        )

        cursor_key = (
            cursor.watched_at,
            _HISTORY_MEDIA_RANK[cursor.media_type],
            cursor.event_id,
        )

        return candidate < cursor_key
