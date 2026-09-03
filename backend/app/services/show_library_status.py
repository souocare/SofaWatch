from datetime import datetime
from uuid import UUID

from sqlalchemy.orm import Session

from app.models.enums import LibraryStatus
from app.repositories.episode import EpisodeRepository
from app.repositories.episode_progress import EpisodeProgressRepository
from app.repositories.library import LibraryRepository
from app.repositories.show import ShowRepository


class ShowLibraryStatusSynchronizer:
    """Synchronize derived Show Library status with viewing progress."""

    _TERMINAL_PROVIDER_STATUSES = {
        "ended",
        "canceled",
        "cancelled",
    }

    def __init__(
        self,
        *,
        session: Session,
        library_repository: LibraryRepository,
        show_repository: ShowRepository,
        episode_repository: EpisodeRepository,
        progress_repository: EpisodeProgressRepository,
    ) -> None:
        self._session = session
        self._library_repository = library_repository
        self._show_repository = show_repository
        self._episode_repository = episode_repository
        self._progress_repository = progress_repository

    def after_watch(
        self,
        *,
        user_id: UUID,
        show_id: UUID,
        watched_at: datetime,
    ) -> None:
        """Synchronize status after new viewing activity."""

        entry = self._library_repository.get_by_user_and_show(
            user_id=user_id,
            show_id=show_id,
        )

        if entry is None:
            return

        show = self._show_repository.get_by_id(
            show_id,
        )

        if show is None:
            return

        self._session.flush()

        watched_episodes = self._progress_repository.count_watched_for_show(
            user_id=user_id,
            show_id=show_id,
        )
        total_episodes = self._episode_repository.count_regular_by_show_id(
            show_id,
        )

        provider_status = show.status.strip().lower()

        is_completed = (
            total_episodes > 0
            and watched_episodes == total_episodes
            and not show.in_production
            and provider_status in self._TERMINAL_PROVIDER_STATUSES
        )

        if entry.started_at is None:
            entry.started_at = watched_at

        if is_completed:
            entry.status = LibraryStatus.COMPLETED

            if entry.completed_at is None:
                entry.completed_at = watched_at

            return

        entry.status = LibraryStatus.WATCHING
        entry.completed_at = None

    def after_unwatch(
        self,
        *,
        user_id: UUID,
        show_id: UUID,
    ) -> None:
        """Synchronize status after current viewing progress is removed."""

        entry = self._library_repository.get_by_user_and_show(
            user_id=user_id,
            show_id=show_id,
        )

        if entry is None:
            return

        if entry.status in {
            LibraryStatus.PAUSED,
            LibraryStatus.DROPPED,
        }:
            return

        self._session.flush()

        watched_episodes = self._progress_repository.count_watched_for_show(
            user_id=user_id,
            show_id=show_id,
        )

        if watched_episodes == 0 and entry.started_at is None:
            entry.status = LibraryStatus.PLANNING
        else:
            entry.status = LibraryStatus.WATCHING

        entry.completed_at = None
