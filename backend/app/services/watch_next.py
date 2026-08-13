from datetime import date
from uuid import UUID

from app.models.enums import LibraryStatus
from app.repositories.episode_progress import (
    EpisodeProgressRepository,
    NextUnwatchedEpisode,
)
from app.repositories.library import LibraryRepository
from app.schemas.watch_next import (
    WatchNextEpisodeResponse,
    WatchNextShowResponse,
)


class WatchNextService:
    """Build the current user's Watch Next collection."""

    def __init__(
        self,
        *,
        library_repository: LibraryRepository,
        progress_repository: EpisodeProgressRepository,
    ) -> None:
        self._library_repository = library_repository
        self._progress_repository = progress_repository

    def list_for_user(
        self,
        *,
        user_id: UUID,
    ) -> list[WatchNextShowResponse]:
        """Return Shows that currently have an aired unwatched Episode."""

        entries = self._library_repository.list_shows_by_user(
            user_id,
            status=LibraryStatus.WATCHING,
        )

        eligible_entries = [
            entry
            for entry in entries
            if entry.show_id is not None
            and entry.show is not None
        ]

        if not eligible_entries:
            return []

        show_ids = [
            entry.show_id
            for entry in eligible_entries
            if entry.show_id is not None
        ]

        next_by_show = self._progress_repository.list_next_unwatched_for_shows(
            user_id=user_id,
            show_ids=show_ids,
            as_of=date.today(),
        )

        results: list[WatchNextShowResponse] = []

        for entry in eligible_entries:
            show_id = entry.show_id
            show = entry.show

            if show_id is None or show is None:
                continue

            candidate: NextUnwatchedEpisode | None = next_by_show.get(
                show_id,
            )

            if candidate is None:
                continue

            episode = candidate.episode

            results.append(
                WatchNextShowResponse(
                    library_entry_id=entry.id,
                    library_status=entry.status,
                    show=show,
                    next_episode=WatchNextEpisodeResponse(
                        id=episode.id,
                        tmdb_id=episode.tmdb_id,
                        season_number=candidate.season_number,
                        episode_number=episode.episode_number,
                        title=episode.title,
                        air_date=episode.air_date,
                        runtime=episode.runtime,
                        still_url=episode.still_url,
                    ),
                )
            )

        return results