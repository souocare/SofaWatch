from uuid import UUID

from sqlalchemy.orm import Session

from app.models.episode_watch_event import EpisodeWatchEvent
from app.repositories.episode_progress import EpisodeProgressRepository
from app.repositories.episode_watch_event import EpisodeWatchEventRepository


class EpisodeWatchEventService:
    """Business logic for historical Episode watch events."""

    def __init__(
        self,
        *,
        session: Session,
        watch_event_repository: EpisodeWatchEventRepository,
        progress_repository: EpisodeProgressRepository,
    ) -> None:
        self._session = session
        self._watch_event_repository = watch_event_repository
        self._progress_repository = progress_repository

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

        event = (
            self._watch_event_repository.get_by_id_for_user_and_episode(
                event_id=event_id,
                user_id=user_id,
                episode_id=episode_id,
            )
        )

        if event is None:
            return False

        self._watch_event_repository.delete(
            event,
        )

        # The deleted event must disappear from the current transaction before
        # selecting the latest remaining event.
        self._session.flush()

        latest_event = (
            self._watch_event_repository.get_latest_for_user_and_episode(
                user_id=user_id,
                episode_id=episode_id,
            )
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

        self._session.commit()

        return True