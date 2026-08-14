from uuid import UUID

from app.repositories.episode_watch_event import (
    EpisodeWatchEventRepository,
    WatchHistoryEvent,
)
from app.schemas.watch_history import (
    WatchHistoryEpisodeResponse,
    WatchHistoryItemResponse,
    WatchHistoryPageResponse,
)
from app.services.watch_history_cursor import (
    WatchHistoryCursor,
    WatchHistoryCursorCodec,
)


class WatchHistoryService:
    """Build the current user's cursor-paginated Watch History."""

    def __init__(
        self,
        *,
        watch_event_repository: EpisodeWatchEventRepository,
    ) -> None:
        self._watch_event_repository = watch_event_repository

    def list_for_user(
        self,
        *,
        user_id: UUID,
        limit: int = 30,
        cursor: str | None = None,
    ) -> WatchHistoryPageResponse:
        """Return one page of historical TV Episode viewings."""

        decoded_cursor = (
            WatchHistoryCursorCodec.decode(
                cursor,
            )
            if cursor is not None
            else None
        )

        page = self._watch_event_repository.list_watch_history(
            user_id=user_id,
            limit=limit,
            before_watched_at=(
                decoded_cursor.watched_at
                if decoded_cursor is not None
                else None
            ),
            before_event_id=(
                decoded_cursor.event_id
                if decoded_cursor is not None
                else None
            ),
        )

        episode_ids = list(
            dict.fromkeys(
                history_item.episode.id
                for history_item in page.items
            )
        )

        watch_counts = (
            self._watch_event_repository.get_counts_by_user_and_episode_ids(
                user_id=user_id,
                episode_ids=episode_ids,
            )
        )

        items = [
            self._build_item(
                history_item,
                watch_count=watch_counts.get(
                    history_item.episode.id,
                    1,
                ),
            )
            for history_item in page.items
        ]

        next_cursor: str | None = None

        if page.has_more and page.items:
            last_item = page.items[-1]

            next_cursor = WatchHistoryCursorCodec.encode(
                WatchHistoryCursor(
                    watched_at=last_item.watched_at,
                    event_id=last_item.event_id,
                )
            )

        return WatchHistoryPageResponse(
            items=items,
            next_cursor=next_cursor,
            has_more=page.has_more,
        )

    @staticmethod
    def _build_item(
        history_item: WatchHistoryEvent,
        *,
        watch_count: int,
    ) -> WatchHistoryItemResponse:
        episode = history_item.episode

        return WatchHistoryItemResponse(
            event_id=history_item.event_id,
            show=history_item.show,
            episode=WatchHistoryEpisodeResponse(
                id=episode.id,
                tmdb_id=episode.tmdb_id,
                season_number=history_item.season_number,
                episode_number=episode.episode_number,
                title=episode.title,
                air_date=episode.air_date,
                runtime=episode.runtime,
                still_url=episode.still_url,
                watched_at=history_item.watched_at,
                watch_count=watch_count,
            ),
        )