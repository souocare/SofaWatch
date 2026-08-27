from datetime import UTC, datetime
from uuid import UUID

from app.models.enums import LibraryStatus
from app.repositories.episode_progress import (
    EpisodeProgressRepository,
    LastWatchedEpisode,
    NextUnwatchedEpisode,
)
from app.repositories.library import LibraryRepository
from app.schemas.stale_watching import (
    LastWatchedEpisodeResponse,
    StaleWatchingEpisodeResponse,
    StaleWatchingShowResponse,
)
from app.services.watch_list_rules import (
    as_utc,
    belongs_to_stale_watching,
    is_stale_watching,
)


class StaleWatchingService:
    """Build the Haven't Watched in a While collection."""

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
    ) -> list[StaleWatchingShowResponse]:
        """Return Watching Shows inactive for at least 60 days."""

        entries = self._library_repository.list_shows_by_user(
            user_id,
            status=LibraryStatus.WATCHING,
        )

        eligible_entries = [
            entry for entry in entries if entry.show_id is not None and entry.show is not None
        ]

        if not eligible_entries:
            return []

        show_ids = [entry.show_id for entry in eligible_entries if entry.show_id is not None]

        last_watched_by_show = self._progress_repository.list_last_watched_for_shows(
            user_id=user_id,
            show_ids=show_ids,
        )

        if not last_watched_by_show:
            return []

        now = datetime.now(UTC)

        stale_show_ids = [
            show_id
            for show_id, candidate in last_watched_by_show.items()
            if is_stale_watching(
                candidate.watched_at,
                now=now,
            )
        ]

        if not stale_show_ids:
            return []

        next_by_show = self._progress_repository.list_next_unwatched_for_shows(
            user_id=user_id,
            show_ids=stale_show_ids,
            as_of=now.date(),
        )

        results: list[StaleWatchingShowResponse] = []

        for entry in eligible_entries:
            show_id = entry.show_id
            show = entry.show

            if show_id is None or show is None:
                continue

            last_watched: LastWatchedEpisode | None = last_watched_by_show.get(show_id)

            next_episode: NextUnwatchedEpisode | None = next_by_show.get(show_id)

            if last_watched is None or next_episode is None:
                continue

            if not belongs_to_stale_watching(
                watched_at=last_watched.watched_at,
                next_episode_air_date=next_episode.episode.air_date,
                now=now,
            ):
                continue

            last_episode = last_watched.episode
            next_episode_model = next_episode.episode

            results.append(
                StaleWatchingShowResponse(
                    library_entry_id=entry.id,
                    library_status=entry.status,
                    show=show,
                    last_watched=LastWatchedEpisodeResponse(
                        id=last_episode.id,
                        tmdb_id=last_episode.tmdb_id,
                        season_number=last_watched.season_number,
                        episode_number=last_episode.episode_number,
                        title=last_episode.title,
                        air_date=last_episode.air_date,
                        runtime=last_episode.runtime,
                        still_url=last_episode.still_url,
                        watched_at=as_utc(
                            last_watched.watched_at,
                        ),
                    ),
                    next_episode=StaleWatchingEpisodeResponse(
                        id=next_episode_model.id,
                        tmdb_id=next_episode_model.tmdb_id,
                        season_number=next_episode.season_number,
                        episode_number=next_episode_model.episode_number,
                        title=next_episode_model.title,
                        air_date=next_episode_model.air_date,
                        runtime=next_episode_model.runtime,
                        still_url=next_episode_model.still_url,
                    ),
                )
            )

        results.sort(
            key=lambda item: (
                item.last_watched.watched_at,
                item.show.title.casefold(),
            )
        )

        return results
