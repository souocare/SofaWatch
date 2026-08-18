from datetime import date
from uuid import UUID

from app.models.enums import LibraryStatus
from app.repositories.episode import (
    EpisodeRepository,
    TimelineEpisode,
)
from app.models.library import LibraryEntry
from app.repositories.library import LibraryRepository
from app.schemas.upcoming import (
    UpcomingEpisodeResponse,
    UpcomingItemResponse,
)
from app.repositories.episode_progress import EpisodeProgressRepository


class UpcomingService:
    """Build the current user's TV Episode Upcoming timeline."""

    ELIGIBLE_STATUSES = frozenset(
        {
            LibraryStatus.WATCHING,
            LibraryStatus.PLANNING,
        }
    )

    def __init__(
        self,
        *,
        library_repository: LibraryRepository,
        episode_repository: EpisodeRepository,
        progress_repository: EpisodeProgressRepository,
    ) -> None:
        self._library_repository = library_repository
        self._episode_repository = episode_repository
        self._progress_repository = progress_repository

    def list_for_user(
        self,
        *,
        user_id: UUID,
        from_date: date | None = None,
        to_date: date | None = None,
        limit: int | None = None,
    ) -> list[UpcomingItemResponse]:
        """Return known dated Episodes for the user's Upcoming timeline.

        By default the timeline starts today and has no upper date bound.

        Only Watching and Planning Shows are eligible. When ``limit`` is
        provided, the database returns at most that many Episodes.
        """

        if limit is not None and limit <= 0:
            return []

        timeline_start = from_date or date.today()

        entries = self._library_repository.list_shows_by_user(
            user_id,
        )

        eligible_entries = [
            entry
            for entry in entries
            if entry.status in self.ELIGIBLE_STATUSES
            and entry.show_id is not None
            and entry.show is not None
        ]

        if not eligible_entries:
            return []

        entries_by_show_id = {
            entry.show_id: entry
            for entry in eligible_entries
            if entry.show_id is not None
        }

        timeline_episodes = (
            self._episode_repository.list_regular_for_shows_between(
                show_ids=list(entries_by_show_id),
                from_date=timeline_start,
                to_date=to_date,
                limit=limit,
            )
        )

        watched_episode_ids = self._progress_repository.get_watched_episode_ids(
            user_id=user_id,
            episode_ids=[
                timeline_episode.episode.id
                for timeline_episode in timeline_episodes
            ],
        )

        results: list[UpcomingItemResponse] = []

        for timeline_episode in timeline_episodes:
            entry = entries_by_show_id.get(
                timeline_episode.show_id,
            )

            if entry is None or entry.show is None:
                continue

            results.append(
                self._build_item(
                    entry=entry,
                    timeline_episode=timeline_episode,
                    is_watched=(
                        timeline_episode.episode.id
                        in watched_episode_ids
                    ),
                )
            )

        results.sort(
            key=lambda item: (
                item.episode.air_date,
                item.show.title.casefold(),
                item.episode.season_number,
                item.episode.episode_number,
                str(item.episode.id),
            )
        )

        return results

    @staticmethod
    def _build_item(
        *,
        entry: LibraryEntry,
        timeline_episode: TimelineEpisode,
        is_watched: bool,
    ) -> UpcomingItemResponse:
        episode = timeline_episode.episode

        if episode.air_date is None:
            raise ValueError(
                "Upcoming timeline Episode must have an air date."
            )

        return UpcomingItemResponse(
        library_entry_id=entry.id,
        library_status=entry.status,
        show=entry.show,
        episode=UpcomingEpisodeResponse(
            id=episode.id,
            tmdb_id=episode.tmdb_id,
            season_number=timeline_episode.season_number,
            episode_number=episode.episode_number,
            title=episode.title,
            air_date=episode.air_date,
            runtime=episode.runtime,
            still_url=episode.still_url,
            is_watched=is_watched,
        ),
    )