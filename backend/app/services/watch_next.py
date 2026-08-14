from datetime import date
from uuid import UUID

from app.models.enums import LibraryStatus
from app.repositories.episode import EpisodeRepository
from app.repositories.episode_progress import (
    EpisodeProgressRepository,
    NextUnwatchedEpisode,
)
from app.repositories.library import LibraryRepository
from app.schemas.watch_next import (
    WatchNextEpisodeResponse,
    WatchNextProgressResponse,
    WatchNextShowResponse,
)


class WatchNextService:
    """Build the current user's Watch Next collection."""

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

        today = date.today()

        next_by_show = (
            self._progress_repository.list_next_unwatched_for_shows(
                user_id=user_id,
                show_ids=show_ids,
                as_of=today,
            )
        )

        aired_counts = self._episode_repository.get_aired_counts_by_show_ids(
            show_ids=show_ids,
            as_of=today,
        )

        watched_aired_counts = (
            self._progress_repository.get_watched_aired_counts_by_show_ids(
                user_id=user_id,
                show_ids=show_ids,
                as_of=today,
            )
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

            aired_episodes = aired_counts.get(
                show_id,
                0,
            )

            watched_episodes = watched_aired_counts.get(
                show_id,
                0,
            )

            percentage = (
                watched_episodes / aired_episodes * 100
                if aired_episodes > 0
                else 0.0
            )

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
                    progress=WatchNextProgressResponse(
                        watched_episodes=watched_episodes,
                        aired_episodes=aired_episodes,
                        percentage=percentage,
                    ),
                )
            )

        return results