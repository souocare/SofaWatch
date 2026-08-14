from datetime import date
from uuid import UUID

from app.models.enums import LibraryStatus
from app.repositories.episode import EpisodeRepository
from app.repositories.library import LibraryRepository
from app.schemas.havent_started import HaventStartedShowResponse
from app.schemas.watch_next import WatchNextEpisodeResponse


class HaventStartedService:
    """Build the Haven't Started collection."""

    def __init__(
        self,
        *,
        library_repository: LibraryRepository,
        episode_repository: EpisodeRepository,
    ) -> None:
        self._library_repository = library_repository
        self._episode_repository = episode_repository

    def list_for_user(
        self,
        *,
        user_id: UUID,
    ) -> list[HaventStartedShowResponse]:
        """Return Planning Shows with their first available Episode."""

        entries = self._library_repository.list_shows_by_user(
            user_id,
            status=LibraryStatus.PLANNING,
        )

        results: list[HaventStartedShowResponse] = []

        today = date.today()

        for entry in entries:
            show_id = entry.show_id
            show = entry.show

            if show_id is None or show is None:
                continue

            first_episode_result = (
                self._episode_repository.get_first_aired_regular_for_show(
                    show_id=show_id,
                    as_of=today,
                )
            )

            if first_episode_result is None:
                continue

            episode, season_number = first_episode_result

            results.append(
                HaventStartedShowResponse(
                    library_entry_id=entry.id,
                    library_status=entry.status,
                    show=show,
                    first_episode=WatchNextEpisodeResponse(
                        id=episode.id,
                        tmdb_id=episode.tmdb_id,
                        season_number=season_number,
                        episode_number=episode.episode_number,
                        title=episode.title,
                        air_date=episode.air_date,
                        runtime=episode.runtime,
                        still_url=episode.still_url,
                    ),
                )
            )

        return results