from uuid import UUID

from app.repositories.episode import EpisodeRepository
from app.repositories.episode_progress import EpisodeProgressRepository
from app.repositories.episode_watch_event import EpisodeWatchEventRepository
from app.repositories.season import SeasonRepository
from app.repositories.show import ShowRepository
from app.schemas.episode import EpisodeResponse
from app.schemas.episode_details import (
    EpisodeDetailsProgressResponse,
    EpisodeDetailsResponse,
    EpisodeDetailsSeasonResponse,
)
from app.schemas.show import ShowSummaryResponse


class EpisodeDetailsService:
    """Build the data required by the Episode Details screen."""

    def __init__(
        self,
        *,
        episode_repository: EpisodeRepository,
        season_repository: SeasonRepository,
        show_repository: ShowRepository,
        progress_repository: EpisodeProgressRepository,
        watch_event_repository: EpisodeWatchEventRepository,
    ) -> None:
        self._episode_repository = episode_repository
        self._season_repository = season_repository
        self._show_repository = show_repository
        self._progress_repository = progress_repository
        self._watch_event_repository = watch_event_repository

    def get_details(
        self,
        *,
        user_id: UUID,
        episode_id: UUID,
    ) -> EpisodeDetailsResponse | None:
        """Return aggregated Episode Details for the requested user.

        Returns None when the Episode or one of its required parent resources
        no longer exists locally.
        """

        episode = self._episode_repository.get_by_id(
            episode_id,
        )

        if episode is None:
            return None

        season = self._season_repository.get_by_id(
            episode.season_id,
        )

        if season is None:
            return None

        show = self._show_repository.get_by_id(
            season.show_id,
        )

        if show is None:
            return None

        progress = self._progress_repository.get_by_user_and_episode(
            user_id=user_id,
            episode_id=episode_id,
        )

        watch_count = self._watch_event_repository.count_by_user_and_episode(
            user_id=user_id,
            episode_id=episode_id,
        )

        latest_watch_event = self._watch_event_repository.get_latest_for_user_and_episode(
            user_id=user_id,
            episode_id=episode_id,
        )

        return EpisodeDetailsResponse(
            episode=EpisodeResponse.model_validate(
                episode,
            ),
            season=EpisodeDetailsSeasonResponse(
                id=season.id,
                season_number=season.season_number,
                title=season.title,
            ),
            show=ShowSummaryResponse.model_validate(
                show,
            ),
            progress=EpisodeDetailsProgressResponse(
                is_watched=progress.is_watched if progress is not None else False,
                watched_at=progress.watched_at if progress is not None else None,
                watch_count=watch_count,
                last_watched_at=(
                    latest_watch_event.watched_at if latest_watch_event is not None else None
                ),
            ),
        )
