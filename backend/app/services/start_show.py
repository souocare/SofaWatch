from datetime import UTC, date, datetime
from uuid import UUID

from sqlalchemy.orm import Session

from app.models.episode_progress import EpisodeProgress
from app.models.episode_watch_event import EpisodeWatchEvent
from app.repositories.episode import EpisodeRepository
from app.repositories.episode_progress import EpisodeProgressRepository
from app.repositories.episode_watch_event import EpisodeWatchEventRepository
from app.repositories.library import LibraryRepository
from app.schemas.start_show import StartShowResponse
from app.services.show_library_status import ShowLibraryStatusSynchronizer


class StartShowService:
    """Start a Planning TV series from its first available Episode."""

    def __init__(
        self,
        *,
        session: Session,
        library_repository: LibraryRepository,
        episode_repository: EpisodeRepository,
        progress_repository: EpisodeProgressRepository,
        watch_event_repository: EpisodeWatchEventRepository,
        show_status_synchronizer: ShowLibraryStatusSynchronizer,
    ) -> None:
        self._session = session
        self._library_repository = library_repository
        self._episode_repository = episode_repository
        self._progress_repository = progress_repository
        self._watch_event_repository = watch_event_repository
        self._show_status_synchronizer = show_status_synchronizer

    def start(
        self,
        *,
        user_id: UUID,
        show_id: UUID,
    ) -> StartShowResponse | None:
        """Start a Library Show from its first aired regular Episode.

        Returns None when the Show is not present in the user's Library
        or when no aired regular Episode is available yet.
        """

        entry = self._library_repository.get_by_user_and_show(
            user_id=user_id,
            show_id=show_id,
        )

        if entry is None:
            return None

        first_episode_result = self._episode_repository.get_first_aired_regular_for_show(
            show_id=show_id,
            as_of=date.today(),
        )

        if first_episode_result is None:
            return None

        episode, _season_number = first_episode_result

        watched_at = datetime.now(UTC)

        progress = self._progress_repository.get_by_user_and_episode(
            user_id=user_id,
            episode_id=episode.id,
        )

        if progress is None:
            progress = EpisodeProgress(
                user_id=user_id,
                episode_id=episode.id,
                is_watched=True,
                watched_at=watched_at,
            )

            self._progress_repository.add(progress)
        else:
            progress.is_watched = True
            progress.watched_at = watched_at

        watch_event = EpisodeWatchEvent(
            user_id=user_id,
            episode_id=episode.id,
            watched_at=watched_at,
        )

        self._watch_event_repository.add(
            watch_event,
        )

        self._show_status_synchronizer.after_watch(
            user_id=user_id,
            show_id=show_id,
            watched_at=watched_at,
        )

        # One transaction deliberately covers all related changes:
        #
        # - the first Episode becomes watched;
        # - a historical watch event is recorded;
        # - the derived Show Library status is synchronized.
        #
        # These changes must remain consistent with each other.
        self._session.commit()

        return StartShowResponse(
            library_entry_id=entry.id,
            library_status=entry.status,
            show_id=show_id,
            started_episode_id=episode.id,
        )
