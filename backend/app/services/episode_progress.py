from datetime import UTC, datetime, date
from uuid import UUID


from sqlalchemy.orm import Session

from app.models.episode_progress import EpisodeProgress
from app.repositories.episode import EpisodeRepository
from app.repositories.episode_progress import EpisodeProgressRepository
from app.repositories.season import SeasonRepository
from app.repositories.show import ShowRepository
from app.schemas.progress import NextEpisodeResponse, NextUpcomingEpisodeResponse, SeasonProgressResponse, ShowProgressResponse


class EpisodeProgressService:
    """Business logic for episode viewing progress."""

    def __init__(
        self,
        *,
        session: Session,
        progress_repository: EpisodeProgressRepository,
        episode_repository: EpisodeRepository,
        season_repository: SeasonRepository,
        show_repository: ShowRepository,
    ) -> None:
        self._session = session
        self._progress_repository = progress_repository
        self._episode_repository = episode_repository
        self._season_repository = season_repository
        self._show_repository = show_repository

    def mark_watched(
        self,
        *,
        user_id: UUID,
        episode_id: UUID,
        watched_at: datetime | None = None,
    ) -> EpisodeProgress | None:
        """Mark an episode as watched."""

        episode = self._episode_repository.get_by_id(
            episode_id,
        )

        if episode is None:
            return None

        progress = self._progress_repository.get_by_user_and_episode(
            user_id=user_id,
            episode_id=episode_id,
        )

        if watched_at is not None and watched_at.tzinfo is None:
            watched_at = watched_at.replace(
                tzinfo=UTC,
            )

        viewed_at = watched_at or datetime.now(UTC)

        if progress is None:
            progress = EpisodeProgress(
                user_id=user_id,
                episode_id=episode_id,
                is_watched=True,
                watched_at=viewed_at,
            )

            self._progress_repository.add(progress)

        elif not progress.is_watched:
            progress.is_watched = True
            progress.watched_at = viewed_at

        self._session.commit()
        self._session.refresh(progress)

        return progress

    def mark_unwatched(
        self,
        *,
        user_id: UUID,
        episode_id: UUID,
    ) -> EpisodeProgress | None:
        """Mark an episode as not watched.

        Returns None when the episode does not exist locally.
        """

        episode = self._episode_repository.get_by_id(
            episode_id,
        )

        if episode is None:
            return None

        progress = self._progress_repository.get_by_user_and_episode(
            user_id=user_id,
            episode_id=episode_id,
        )

        if progress is None:
            progress = EpisodeProgress(
                user_id=user_id,
                episode_id=episode_id,
                is_watched=False,
                watched_at=None,
            )

            self._progress_repository.add(progress)
        else:
            progress.is_watched = False
            progress.watched_at = None

        self._session.commit()
        self._session.refresh(progress)

        return progress

    def get_season_progress(
        self,
        *,
        user_id: UUID,
        season_id: UUID,
    ) -> SeasonProgressResponse | None:
        """Calculate viewing progress for a TV season."""

        season = self._season_repository.get_by_id(
            season_id,
        )

        if season is None:
            return None

        today = date.today()

        total_episodes = self._episode_repository.count_by_season_id(
            season_id,
        )

        watched_episodes = (
            self._progress_repository.count_watched_for_season(
                user_id=user_id,
                season_id=season_id,
            )
        )

        aired_episodes = (
            self._episode_repository.count_aired_by_season_id(
                season_id,
                as_of=today,
            )
        )

        watched_aired_episodes = (
            self._progress_repository.count_watched_aired_for_season(
                user_id=user_id,
                season_id=season_id,
                as_of=today,
            )
        )

        progress_percentage = (
            watched_episodes / total_episodes * 100
            if total_episodes > 0
            else 0.0
        )

        aired_progress_percentage = (
            watched_aired_episodes / aired_episodes * 100
            if aired_episodes > 0
            else 0.0
        )

        caught_up = (
            aired_episodes > 0
            and watched_aired_episodes == aired_episodes
        )

        return SeasonProgressResponse(
            season_id=season_id,
            watched_episodes=watched_episodes,
            total_episodes=total_episodes,
            progress_percentage=progress_percentage,
            aired_episodes=aired_episodes,
            watched_aired_episodes=watched_aired_episodes,
            aired_progress_percentage=aired_progress_percentage,
            caught_up=caught_up,
        )

    def get_show_progress(
        self,
        *,
        user_id: UUID,
        show_id: UUID,
    ) -> ShowProgressResponse | None:
        """Calculate viewing progress for a TV series."""

        show = self._show_repository.get_by_id(
            show_id,
        )

        if show is None:
            return None

        today = date.today()

        total_episodes = (
            self._episode_repository.count_regular_by_show_id(
                show_id,
            )
        )

        watched_episodes = (
            self._progress_repository.count_watched_for_show(
                user_id=user_id,
                show_id=show_id,
            )
        )

        aired_episodes = (
            self._episode_repository.count_aired_by_show_id(
                show_id,
                as_of=today,
            )
        )

        watched_aired_episodes = (
            self._progress_repository.count_watched_aired_for_show(
                user_id=user_id,
                show_id=show_id,
                as_of=today,
            )
        )

        progress_percentage = (
            watched_episodes / total_episodes * 100
            if total_episodes > 0
            else 0.0
        )

        aired_progress_percentage = (
            watched_aired_episodes / aired_episodes * 100
            if aired_episodes > 0
            else 0.0
        )

        caught_up = (
            aired_episodes > 0
            and watched_aired_episodes == aired_episodes
        )

        return ShowProgressResponse(
            show_id=show_id,
            watched_episodes=watched_episodes,
            total_episodes=total_episodes,
            progress_percentage=progress_percentage,
            aired_episodes=aired_episodes,
            watched_aired_episodes=watched_aired_episodes,
            aired_progress_percentage=aired_progress_percentage,
            caught_up=caught_up,
        )

    def get_next_episode(
        self,
        *,
        user_id: UUID,
        show_id: UUID,
    ) -> NextEpisodeResponse | None:
        """Return the next unwatched episode of a TV series.

        Returns None when the TV series does not exist.
        """

        show = self._show_repository.get_by_id(
            show_id,
        )

        if show is None:
            return None

        episode = self._progress_repository.get_next_unwatched_for_show(
            user_id=user_id,
            show_id=show_id,
            as_of=date.today(),
        )

        return NextEpisodeResponse(
            show_id=show_id,
            next_episode=episode,
        )
    
    def get_next_upcoming_episode(
        self,
        *,
        show_id: UUID,
    ) -> NextUpcomingEpisodeResponse | None:
        """Return the next future regular episode of a TV series."""

        show = self._show_repository.get_by_id(
            show_id,
        )

        if show is None:
            return None

        episode = self._progress_repository.get_next_upcoming_for_show(
            show_id=show_id,
            after=date.today(),
        )

        return NextUpcomingEpisodeResponse(
            show_id=show_id,
            next_episode=episode,
        )
