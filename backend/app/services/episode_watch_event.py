from uuid import UUID

from sqlalchemy.orm import Session

from app.models.episode_watch_event import EpisodeWatchEvent
from app.repositories.episode import EpisodeRepository
from app.repositories.episode_progress import EpisodeProgressRepository
from app.repositories.episode_watch_event import EpisodeWatchEventRepository
from app.repositories.season import SeasonRepository
from app.services.show_library_status import ShowLibraryStatusSynchronizer


class EpisodeWatchEventService:
    """Business logic for historical Episode watch events."""

    def __init__(
        self,
        *,
        session: Session,
        watch_event_repository: EpisodeWatchEventRepository,
        progress_repository: EpisodeProgressRepository,
        episode_repository: EpisodeRepository,
        season_repository: SeasonRepository,
        show_status_synchronizer: ShowLibraryStatusSynchronizer,
    ) -> None:
        self._session = session
        self._watch_event_repository = watch_event_repository
        self._progress_repository = progress_repository
        self._episode_repository = episode_repository
        self._season_repository = season_repository
        self._show_status_synchronizer = show_status_synchronizer

    def list_for_episode(
        self,
        *,
        user_id: UUID,
        episode_id: UUID,
    ) -> list[EpisodeWatchEvent]:
        """Return every recorded watch event for an Episode."""

        return self._watch_event_repository.list_by_user_and_episode(
            user_id=user_id,
            episode_id=episode_id,
        )

    def delete(
        self,
        *,
        user_id: UUID,
        episode_id: UUID,
        event_id: UUID,
    ) -> bool:
        """Delete one watch event and synchronize current Episode progress.

        Returns False when the event does not exist, belongs to another user,
        or belongs to another Episode.
        """

        event = self._watch_event_repository.get_by_id_for_user_and_episode(
            event_id=event_id,
            user_id=user_id,
            episode_id=episode_id,
        )

        if event is None:
            return False

        self._watch_event_repository.delete(
            event,
        )

        episode = self._episode_repository.get_by_id(
            episode_id,
        )

        if episode is None:
            return False

        season = self._season_repository.get_by_id(
            episode.season_id,
        )

        if season is None:
            return False

        # The deleted event must disappear from the current transaction before
        # selecting the latest remaining event.
        self._session.flush()

        latest_event = self._watch_event_repository.get_latest_for_user_and_episode(
            user_id=user_id,
            episode_id=episode_id,
        )

        progress = self._progress_repository.get_by_user_and_episode(
            user_id=user_id,
            episode_id=episode_id,
        )

        if progress is not None:
            if latest_event is None:
                progress.is_watched = False
                progress.watched_at = None
            else:
                progress.is_watched = True
                progress.watched_at = latest_event.watched_at

        if latest_event is None:
            self._show_status_synchronizer.after_unwatch(
                user_id=user_id,
                show_id=season.show_id,
            )

        self._session.commit()

        return True

    def delete_all(
        self,
        *,
        user_id: UUID,
        episode_id: UUID,
    ) -> int:
        """Delete every watch event and clear current Episode progress.

        The operation is idempotent. Calling it when no historical viewings
        remain still guarantees that the Episode is marked as unwatched.

        Returns the number of deleted watch events.
        """

        episode = self._episode_repository.get_by_id(
            episode_id,
        )

        season = (
            self._season_repository.get_by_id(
                episode.season_id,
            )
            if episode is not None
            else None
        )

        deleted_count = self._watch_event_repository.delete_all_for_user_and_episode(
            user_id=user_id,
            episode_id=episode_id,
        )

        progress = self._progress_repository.get_by_user_and_episode(
            user_id=user_id,
            episode_id=episode_id,
        )

        if progress is not None:
            progress.is_watched = False
            progress.watched_at = None

        if season is not None:
            self._show_status_synchronizer.after_unwatch(
                user_id=user_id,
                show_id=season.show_id,
            )

        self._session.commit()

        return deleted_count
