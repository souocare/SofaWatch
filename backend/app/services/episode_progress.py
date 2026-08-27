from collections.abc import Callable
from datetime import UTC, date, datetime
from uuid import UUID

from sqlalchemy.orm import Session

from app.models.episode_progress import EpisodeProgress
from app.models.episode_watch_event import EpisodeWatchEvent
from app.repositories.episode import EpisodeRepository
from app.repositories.episode_progress import EpisodeProgressRepository
from app.repositories.episode_watch_event import EpisodeWatchEventRepository
from app.repositories.season import SeasonRepository
from app.repositories.show import ShowRepository
from app.schemas.episode_progress import (
    EpisodeProgressResponse,
    EpisodeProgressWithWatchCountResponse,
    EpisodeWatchedWithPreviousResponse,
    PreviousUnwatchedEpisodesResponse,
)
from app.schemas.progress import (
    NextEpisodeResponse,
    NextUpcomingEpisodeResponse,
    SeasonProgressResponse,
    ShowProgressResponse,
)


class EpisodeNotWatchableError(Exception):
    """Raised when an Episode cannot yet be marked as watched."""


class EpisodeProgressService:
    """Business logic for Episode viewing progress."""

    def __init__(
        self,
        *,
        session: Session,
        progress_repository: EpisodeProgressRepository,
        episode_repository: EpisodeRepository,
        season_repository: SeasonRepository,
        show_repository: ShowRepository,
        watch_event_repository: EpisodeWatchEventRepository,
        today: Callable[[], date] | None = None,
    ) -> None:
        self._session = session
        self._progress_repository = progress_repository
        self._episode_repository = episode_repository
        self._season_repository = season_repository
        self._show_repository = show_repository
        self._watch_event_repository = watch_event_repository
        self._today = today or date.today

    def mark_watched(
        self,
        *,
        user_id: UUID,
        episode_id: UUID,
        watched_at: datetime | None = None,
    ) -> EpisodeProgressWithWatchCountResponse | None:
        """Record an Episode watch and update its current progress.

        An Episode can only be marked as watched when its air date is known
        and is not later than Today.

        Because the current provider data does not include a reliable air time,
        an Episode dated Today is considered available to watch.

        Calling this operation for an already watched Episode is intentionally
        treated as a Rewatch and therefore creates another historical viewing
        event.
        """

        episode = self._episode_repository.get_by_id(
            episode_id,
        )

        if episode is None:
            return None

        air_date = episode.air_date

        if air_date is None or air_date > self._today():
            raise EpisodeNotWatchableError(
                "Episode has not aired yet.",
            )

        if watched_at is not None and watched_at.tzinfo is None:
            watched_at = watched_at.replace(
                tzinfo=UTC,
            )

        viewed_at = watched_at or datetime.now(UTC)

        progress = self._progress_repository.get_by_user_and_episode(
            user_id=user_id,
            episode_id=episode_id,
        )

        if progress is None:
            progress = EpisodeProgress(
                user_id=user_id,
                episode_id=episode_id,
                is_watched=True,
                watched_at=viewed_at,
            )

            self._progress_repository.add(
                progress,
            )
        else:
            progress.is_watched = True
            progress.watched_at = viewed_at

        self._watch_event_repository.add(
            EpisodeWatchEvent(
                user_id=user_id,
                episode_id=episode_id,
                watched_at=viewed_at,
            )
        )

        # One transaction deliberately persists both:
        # - the current Episode progress;
        # - the historical watch event.
        #
        # We must never record one without the other.
        self._session.commit()
        self._session.refresh(progress)

        watch_count = self._watch_event_repository.count_by_user_and_episode(
            user_id=user_id,
            episode_id=episode_id,
        )

        return EpisodeProgressWithWatchCountResponse(
            id=progress.id,
            episode_id=progress.episode_id,
            is_watched=progress.is_watched,
            watched_at=progress.watched_at,
            watch_count=watch_count,
        )

    def get_previous_unwatched_episodes(
        self,
        *,
        user_id: UUID,
        episode_id: UUID,
    ) -> PreviousUnwatchedEpisodesResponse | None:
        """Return the number of eligible earlier Episodes still unwatched.

        Earlier Episodes include:

        - regular Episodes from previous Seasons;
        - earlier Episodes from the target Season.

        Specials are excluded.

        Only Episodes whose air date is known and not later than Today are
        considered eligible.

        The target Episode itself must also be watchable.

        Returns None when the target Episode or its Season does not exist.
        """

        episode = self._episode_repository.get_by_id(
            episode_id,
        )

        if episode is None:
            return None

        air_date = episode.air_date

        if air_date is None or air_date > self._today():
            raise EpisodeNotWatchableError(
                "Episode has not aired yet.",
            )

        season = self._season_repository.get_by_id(
            episode.season_id,
        )

        if season is None:
            return None

        previous_episodes = self._progress_repository.list_previous_unwatched_aired_episodes(
            user_id=user_id,
            show_id=season.show_id,
            target_season_number=season.season_number,
            target_episode_number=episode.episode_number,
            as_of=self._today(),
        )

        return PreviousUnwatchedEpisodesResponse(
            episode_id=episode.id,
            previous_unwatched_count=len(previous_episodes),
        )

    def mark_watched_with_previous(
        self,
        *,
        user_id: UUID,
        episode_id: UUID,
        watched_at: datetime | None = None,
    ) -> EpisodeWatchedWithPreviousResponse | None:
        """Mark a target Episode and eligible previous Episodes as watched.

        Earlier Episodes include regular Episodes from previous Seasons and
        earlier Episodes from the target Season.

        Specials, future Episodes, Episodes without a known air date, and
        Episodes already watched by the user are ignored.

        This is a catch-up operation rather than a Rewatch operation.
        Existing viewing history is therefore never duplicated, including for
        the target Episode when it is already watched.

        Every newly watched Episode receives the same viewing timestamp.

        Previous Episodes and the target Episode are persisted as one atomic
        transaction.

        Returns None when the target Episode or its Season does not exist.
        """

        episode = self._episode_repository.get_by_id(
            episode_id,
        )

        if episode is None:
            return None

        air_date = episode.air_date

        if air_date is None or air_date > self._today():
            raise EpisodeNotWatchableError(
                "Episode has not aired yet.",
            )

        season = self._season_repository.get_by_id(
            episode.season_id,
        )

        if season is None:
            return None

        if watched_at is not None and watched_at.tzinfo is None:
            watched_at = watched_at.replace(
                tzinfo=UTC,
            )

        viewed_at = watched_at or datetime.now(UTC)

        previous_episodes = self._progress_repository.list_previous_unwatched_aired_episodes(
            user_id=user_id,
            show_id=season.show_id,
            target_season_number=season.season_number,
            target_episode_number=episode.episode_number,
            as_of=self._today(),
        )

        previous_episode_ids = [previous_episode.id for previous_episode in previous_episodes]

        previous_progress_entries = {
            progress.episode_id: progress
            for progress in self._progress_repository.list_by_user_and_episode_ids(
                user_id=user_id,
                episode_ids=previous_episode_ids,
            )
        }

        previous_marked_count = 0

        for previous_episode in previous_episodes:
            progress = previous_progress_entries.get(
                previous_episode.id,
            )

            # The repository query already excludes watched Episodes.
            #
            # Keep this defensive check nevertheless: this operation must never
            # create an accidental Rewatch if state changes between the lookup
            # and the mutation.
            if progress is not None and progress.is_watched:
                continue

            if progress is None:
                progress = EpisodeProgress(
                    user_id=user_id,
                    episode_id=previous_episode.id,
                    is_watched=True,
                    watched_at=viewed_at,
                )

                self._progress_repository.add(
                    progress,
                )
            else:
                progress.is_watched = True
                progress.watched_at = viewed_at

            self._watch_event_repository.add(
                EpisodeWatchEvent(
                    user_id=user_id,
                    episode_id=previous_episode.id,
                    watched_at=viewed_at,
                )
            )

            previous_marked_count += 1

        target_progress = self._progress_repository.get_by_user_and_episode(
            user_id=user_id,
            episode_id=episode.id,
        )

        # Unlike the regular /watched operation, this catch-up operation must
        # never convert an already watched target Episode into a Rewatch.
        if target_progress is None:
            target_progress = EpisodeProgress(
                user_id=user_id,
                episode_id=episode.id,
                is_watched=True,
                watched_at=viewed_at,
            )

            self._progress_repository.add(
                target_progress,
            )

            self._watch_event_repository.add(
                EpisodeWatchEvent(
                    user_id=user_id,
                    episode_id=episode.id,
                    watched_at=viewed_at,
                )
            )

        elif not target_progress.is_watched:
            target_progress.is_watched = True
            target_progress.watched_at = viewed_at

            self._watch_event_repository.add(
                EpisodeWatchEvent(
                    user_id=user_id,
                    episode_id=episode.id,
                    watched_at=viewed_at,
                )
            )

        # Previous Episodes and the target Episode form one logical catch-up
        # operation and must therefore either all persist or none persist.
        self._session.commit()
        self._session.refresh(target_progress)

        return EpisodeWatchedWithPreviousResponse(
            progress=EpisodeProgressResponse.model_validate(
                target_progress,
            ),
            previous_marked_count=previous_marked_count,
        )

    def mark_unwatched(
        self,
        *,
        user_id: UUID,
        episode_id: UUID,
    ) -> EpisodeProgressWithWatchCountResponse | None:
        """Mark an Episode as not watched.

        Returns None when the Episode does not exist locally.
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

            self._progress_repository.add(
                progress,
            )
        else:
            progress.is_watched = False
            progress.watched_at = None

        self._session.commit()
        self._session.refresh(progress)

        watch_count = self._watch_event_repository.count_by_user_and_episode(
            user_id=user_id,
            episode_id=episode_id,
        )

        return EpisodeProgressWithWatchCountResponse(
            id=progress.id,
            episode_id=progress.episode_id,
            is_watched=progress.is_watched,
            watched_at=progress.watched_at,
            watch_count=watch_count,
        )

    def mark_season_watched(
        self,
        *,
        user_id: UUID,
        season_id: UUID,
        watched_at: datetime | None = None,
    ) -> SeasonProgressResponse | None:
        """Mark every eligible unwatched Episode in a Season as watched.

        Only Episodes whose air date is known and not later than Today are
        eligible.

        Episodes that are already watched are deliberately left unchanged so
        this bulk operation never records accidental rewatches.

        All newly watched Episodes and their historical watch events are
        persisted in one transaction.

        Returns None when the Season does not exist.
        """

        season = self._season_repository.get_by_id(
            season_id,
        )

        if season is None:
            return None

        episodes = self._episode_repository.list_by_season_id(
            season_id,
        )

        if watched_at is not None and watched_at.tzinfo is None:
            watched_at = watched_at.replace(
                tzinfo=UTC,
            )

        viewed_at = watched_at or datetime.now(UTC)
        today = self._today()

        progress_entries = self._progress_repository.list_by_user_and_season(
            user_id=user_id,
            season_id=season_id,
        )

        progress_by_episode_id = {progress.episode_id: progress for progress in progress_entries}

        for episode in episodes:
            air_date = episode.air_date

            # Unknown and future Episodes are not watchable yet.
            if air_date is None or air_date > today:
                continue

            progress = progress_by_episode_id.get(
                episode.id,
            )

            # This is a bulk completion operation, not a Rewatch.
            #
            # Already watched Episodes keep their existing watched_at and
            # historical viewing events unchanged.
            if progress is not None and progress.is_watched:
                continue

            if progress is None:
                progress = EpisodeProgress(
                    user_id=user_id,
                    episode_id=episode.id,
                    is_watched=True,
                    watched_at=viewed_at,
                )

                self._progress_repository.add(
                    progress,
                )

                progress_by_episode_id[episode.id] = progress
            else:
                progress.is_watched = True
                progress.watched_at = viewed_at

            self._watch_event_repository.add(
                EpisodeWatchEvent(
                    user_id=user_id,
                    episode_id=episode.id,
                    watched_at=viewed_at,
                )
            )

        # The whole Season update is one logical operation.
        #
        # Progress and historical watch events must therefore either all be
        # persisted together or not persisted at all.
        self._session.commit()

        return self.get_season_progress(
            user_id=user_id,
            season_id=season_id,
        )

    def mark_show_watched(
        self,
        *,
        user_id: UUID,
        show_id: UUID,
        watched_at: datetime | None = None,
    ) -> ShowProgressResponse | None:
        """Mark every eligible unwatched regular Episode in a Show as watched.

        Only regular Episodes whose air date is known and not later than Today
        are eligible.

        Specials, future Episodes, and Episodes without a known air date are
        deliberately ignored.

        Episodes that are already watched remain unchanged so this bulk
        operation never records accidental rewatches.

        All newly watched Episodes and their historical watch events are
        persisted in one transaction.

        Returns None when the Show does not exist.
        """

        show = self._show_repository.get_by_id(
            show_id,
        )

        if show is None:
            return None

        episodes = self._episode_repository.list_regular_by_show_id(
            show_id,
        )

        if watched_at is not None and watched_at.tzinfo is None:
            watched_at = watched_at.replace(
                tzinfo=UTC,
            )

        viewed_at = watched_at or datetime.now(UTC)
        today = self._today()

        progress_entries = self._progress_repository.list_by_user_and_show(
            user_id=user_id,
            show_id=show_id,
        )

        progress_by_episode_id = {progress.episode_id: progress for progress in progress_entries}

        for episode in episodes:
            air_date = episode.air_date

            if air_date is None or air_date > today:
                continue

            progress = progress_by_episode_id.get(
                episode.id,
            )

            # This is a bulk completion operation, not a Rewatch.
            if progress is not None and progress.is_watched:
                continue

            if progress is None:
                progress = EpisodeProgress(
                    user_id=user_id,
                    episode_id=episode.id,
                    is_watched=True,
                    watched_at=viewed_at,
                )

                self._progress_repository.add(
                    progress,
                )

                progress_by_episode_id[episode.id] = progress
            else:
                progress.is_watched = True
                progress.watched_at = viewed_at

            self._watch_event_repository.add(
                EpisodeWatchEvent(
                    user_id=user_id,
                    episode_id=episode.id,
                    watched_at=viewed_at,
                )
            )

        # The whole Show update is one logical operation.
        #
        # Progress and historical watch events must therefore either all be
        # persisted together or not persisted at all.
        self._session.commit()

        return self.get_show_progress(
            user_id=user_id,
            show_id=show_id,
        )

    def get_season_progress(
        self,
        *,
        user_id: UUID,
        season_id: UUID,
    ) -> SeasonProgressResponse | None:
        """Calculate viewing progress for a TV Season."""

        season = self._season_repository.get_by_id(
            season_id,
        )

        if season is None:
            return None

        today = self._today()

        total_episodes = self._episode_repository.count_by_season_id(
            season_id,
        )

        watched_episodes = self._progress_repository.count_watched_for_season(
            user_id=user_id,
            season_id=season_id,
        )

        aired_episodes = self._episode_repository.count_aired_by_season_id(
            season_id,
            as_of=today,
        )

        watched_aired_episodes = self._progress_repository.count_watched_aired_for_season(
            user_id=user_id,
            season_id=season_id,
            as_of=today,
        )

        progress_percentage = watched_episodes / total_episodes * 100 if total_episodes > 0 else 0.0

        aired_progress_percentage = (
            watched_aired_episodes / aired_episodes * 100 if aired_episodes > 0 else 0.0
        )

        caught_up = aired_episodes > 0 and watched_aired_episodes == aired_episodes

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

    def get_episode_progress_for_season(
        self,
        *,
        user_id: UUID,
        season_id: UUID,
    ) -> list[EpisodeProgressWithWatchCountResponse] | None:
        """Return Episode progress enriched with historical watch counts.

        Returns None when the Season does not exist.

        Episodes without a progress entry are implicitly unwatched and are not
        included in this collection. The Episode list remains the source of
        truth for all Episodes belonging to the Season.

        Watch counts are fetched in one batch query to avoid one query per
        Episode.
        """

        season = self._season_repository.get_by_id(
            season_id,
        )

        if season is None:
            return None

        progress_entries = self._progress_repository.list_by_user_and_season(
            user_id=user_id,
            season_id=season_id,
        )

        if not progress_entries:
            return []

        episode_ids = [progress.episode_id for progress in progress_entries]

        watch_counts = self._watch_event_repository.get_counts_by_user_and_episode_ids(
            user_id=user_id,
            episode_ids=episode_ids,
        )

        return [
            EpisodeProgressWithWatchCountResponse(
                id=progress.id,
                episode_id=progress.episode_id,
                is_watched=progress.is_watched,
                watched_at=progress.watched_at,
                watch_count=watch_counts.get(
                    progress.episode_id,
                    0,
                ),
            )
            for progress in progress_entries
        ]

    def get_show_seasons_progress(
        self,
        *,
        user_id: UUID,
        show_id: UUID,
    ) -> list[SeasonProgressResponse] | None:
        """Calculate viewing progress for every locally stored Season of a Show.

        Returns None when the TV series does not exist.
        """

        show = self._show_repository.get_by_id(
            show_id,
        )

        if show is None:
            return None

        seasons = self._season_repository.list_by_show_id(
            show_id,
        )

        if not seasons:
            return []

        today = self._today()

        episode_counts = self._episode_repository.get_counts_by_show_id(
            show_id,
            as_of=today,
        )

        watched_counts = self._progress_repository.get_watched_counts_by_show_id(
            user_id=user_id,
            show_id=show_id,
            as_of=today,
        )

        results: list[SeasonProgressResponse] = []

        for season in seasons:
            total_episodes, aired_episodes = episode_counts.get(
                season.id,
                (0, 0),
            )

            watched_episodes, watched_aired_episodes = watched_counts.get(
                season.id,
                (0, 0),
            )

            progress_percentage = (
                watched_episodes / total_episodes * 100 if total_episodes > 0 else 0.0
            )

            aired_progress_percentage = (
                watched_aired_episodes / aired_episodes * 100 if aired_episodes > 0 else 0.0
            )

            caught_up = aired_episodes > 0 and watched_aired_episodes == aired_episodes

            results.append(
                SeasonProgressResponse(
                    season_id=season.id,
                    watched_episodes=watched_episodes,
                    total_episodes=total_episodes,
                    progress_percentage=progress_percentage,
                    aired_episodes=aired_episodes,
                    watched_aired_episodes=watched_aired_episodes,
                    aired_progress_percentage=aired_progress_percentage,
                    caught_up=caught_up,
                )
            )

        return results

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

        today = self._today()

        total_episodes = self._episode_repository.count_regular_by_show_id(
            show_id,
        )

        watched_episodes = self._progress_repository.count_watched_for_show(
            user_id=user_id,
            show_id=show_id,
        )

        aired_episodes = self._episode_repository.count_aired_by_show_id(
            show_id,
            as_of=today,
        )

        watched_aired_episodes = self._progress_repository.count_watched_aired_for_show(
            user_id=user_id,
            show_id=show_id,
            as_of=today,
        )

        progress_percentage = watched_episodes / total_episodes * 100 if total_episodes > 0 else 0.0

        aired_progress_percentage = (
            watched_aired_episodes / aired_episodes * 100 if aired_episodes > 0 else 0.0
        )

        caught_up = aired_episodes > 0 and watched_aired_episodes == aired_episodes

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
        """Return the next unwatched Episode of a TV series.

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
            as_of=self._today(),
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
        """Return the next future regular Episode of a TV series."""

        show = self._show_repository.get_by_id(
            show_id,
        )

        if show is None:
            return None

        episode = self._progress_repository.get_next_upcoming_for_show(
            show_id=show_id,
            after=self._today(),
        )

        return NextUpcomingEpisodeResponse(
            show_id=show_id,
            next_episode=episode,
        )
