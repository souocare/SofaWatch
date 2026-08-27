from uuid import UUID

from sqlalchemy.orm import Session

from app.models.episode import Episode
from app.models.season import Season
from app.repositories.episode import EpisodeRepository
from app.repositories.season import SeasonRepository
from app.repositories.show import ShowRepository
from app.schemas.tmdb_episode import EpisodeSummary
from app.services.tmdb_season_details import TMDBSeasonDetailsService


class SeasonEpisodeSyncService:
    """Synchronize episodes for one locally stored TV season."""

    def __init__(
        self,
        *,
        session: Session,
        show_repository: ShowRepository,
        season_repository: SeasonRepository,
        episode_repository: EpisodeRepository,
        tmdb_season_details_service: TMDBSeasonDetailsService,
    ) -> None:
        self._session = session
        self._show_repository = show_repository
        self._season_repository = season_repository
        self._episode_repository = episode_repository
        self._tmdb_season_details_service = tmdb_season_details_service

    def sync(
        self,
        *,
        season_id: UUID,
        language: str | None = None,
        force_refresh: bool = False,
    ) -> list[Episode] | None:
        """Synchronize and return episodes for one season.

        Existing local episodes are returned without contacting the provider
        unless a refresh is explicitly requested.

        Returns None when the local season or its parent show does not exist.
        """

        season = self._season_repository.get_by_id(
            season_id,
        )

        if season is None:
            return None

        local_episodes = self._episode_repository.list_by_season_id(
            season.id,
        )

        if local_episodes and not force_refresh:
            return local_episodes

        show = self._show_repository.get_by_id(
            season.show_id,
        )

        if show is None:
            return None

        episode_details = self._tmdb_season_details_service.get_episodes(
            tmdb_id=show.tmdb_id,
            season_number=season.season_number,
            language=language,
        )

        try:
            self._sync_episodes(
                season=season,
                episodes=episode_details,
            )

            self._session.commit()

            return self._episode_repository.list_by_season_id(
                season.id,
            )
        except Exception:
            self._session.rollback()
            raise

    def _sync_episodes(
        self,
        *,
        season: Season,
        episodes: list[EpisodeSummary],
    ) -> None:
        """Create or update episodes returned for one season.

        Episodes missing from a later provider response are preserved locally.
        """

        for episode_details in episodes:
            episode = self._episode_repository.get_by_tmdb_id(
                episode_details.tmdb_id,
            )

            if episode is None:
                episode = self._episode_repository.get_by_number(
                    season_id=season.id,
                    episode_number=episode_details.episode_number,
                )

            if episode is None:
                episode = Episode(
                    season_id=season.id,
                )

                self._apply_episode_metadata(
                    episode=episode,
                    details=episode_details,
                )

                self._episode_repository.add(
                    episode,
                )

                continue

            self._apply_episode_metadata(
                episode=episode,
                details=episode_details,
            )

    @staticmethod
    def _apply_episode_metadata(
        *,
        episode: Episode,
        details: EpisodeSummary,
    ) -> None:
        """Apply provider metadata to a locally stored episode."""

        episode.tmdb_id = details.tmdb_id
        episode.episode_number = details.episode_number
        episode.title = details.title
        episode.overview = details.overview or None
        episode.air_date = details.air_date
        episode.runtime = details.runtime
        episode.vote_average = details.vote_average
        episode.vote_count = details.vote_count
        episode.tmdb_still_path = details.still_path
