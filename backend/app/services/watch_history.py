from uuid import UUID

from app.repositories.episode_progress import (
    EpisodeProgressRepository,
    WatchHistoryEpisode,
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
        progress_repository: EpisodeProgressRepository,
    ) -> None:
        self._progress_repository = progress_repository

    def list_for_user(
        self,
        *,
        user_id: UUID,
        limit: int = 30,
        cursor: str | None = None,
    ) -> WatchHistoryPageResponse:
        """Return one page of recently watched TV Episodes."""

        decoded_cursor = (
            WatchHistoryCursorCodec.decode(cursor)
            if cursor is not None
            else None
        )

        page = self._progress_repository.list_watch_history(
            user_id=user_id,
            limit=limit,
            before_watched_at=(
                decoded_cursor.watched_at
                if decoded_cursor is not None
                else None
            ),
            before_progress_id=(
                decoded_cursor.progress_id
                if decoded_cursor is not None
                else None
            ),
        )

        items = [
            self._build_item(history_item)
            for history_item in page.items
        ]

        next_cursor: str | None = None

        if page.has_more and page.items:
            last_item = page.items[-1]

            next_cursor = WatchHistoryCursorCodec.encode(
                WatchHistoryCursor(
                    watched_at=last_item.watched_at,
                    progress_id=last_item.progress_id,
                )
            )

        return WatchHistoryPageResponse(
            items=items,
            next_cursor=next_cursor,
            has_more=page.has_more,
        )

    @staticmethod
    def _build_item(
        history_item: WatchHistoryEpisode,
    ) -> WatchHistoryItemResponse:
        episode = history_item.episode

        return WatchHistoryItemResponse(
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
            ),
        )