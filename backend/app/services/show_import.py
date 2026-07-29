from datetime import UTC, datetime, timedelta

from sqlalchemy.orm import Session

from app.core.config import Settings
from app.models.episode import Episode
from app.models.genre import Genre
from app.models.network import Network
from app.models.season import Season
from app.models.show import Show
from app.repositories.episode import EpisodeRepository
from app.repositories.genre import GenreRepository
from app.repositories.network import NetworkRepository
from app.repositories.season import SeasonRepository
from app.repositories.show import ShowRepository
from app.schemas.tmdb_episode import EpisodeSummary
from app.schemas.tmdb_show import (
    ShowDetailsResponse,
    ShowSeasonSummary,
)
from app.services.tmdb_season_details import TMDBSeasonDetailsService
from app.services.tmdb_show_details import TMDBShowDetailsService


class ShowImportService:
    """Import and refresh TV series metadata."""

    def __init__(
        self,
        *,
        session: Session,
        settings: Settings,
        show_repository: ShowRepository,
        genre_repository: GenreRepository,
        season_repository: SeasonRepository,
        episode_repository: EpisodeRepository,
        tmdb_show_details_service: TMDBShowDetailsService,
        tmdb_season_details_service: TMDBSeasonDetailsService,
        network_repository: NetworkRepository,
    ) -> None:
        self._session = session
        self._settings = settings
        self._show_repository = show_repository
        self._genre_repository = genre_repository
        self._season_repository = season_repository
        self._episode_repository = episode_repository
        self._tmdb_show_details_service = tmdb_show_details_service
        self._tmdb_season_details_service = tmdb_season_details_service
        self._network_repository = network_repository

    def import_show(
        self,
        *,
        tmdb_id: int,
        language: str | None = None,
        force_refresh: bool = False,
    ) -> Show:
        """Import a TV series or refresh its metadata."""

        metadata_language = language or self._settings.default_language

        show = self._show_repository.get_by_tmdb_id(tmdb_id)

        if show is not None and not force_refresh and not self._should_refresh(show):
            return show

        details = self._tmdb_show_details_service.get_details(
            tmdb_id=tmdb_id,
            language=metadata_language,
        )

        try:
            genres = self._resolve_genres(details)
            networks = self._resolve_networks(details)

            if show is None:
                show = self._build_show(
                    details=details,
                    metadata_language=metadata_language,
                )

                show.genres = genres
                show.networks = networks

                self._show_repository.add(show)
            else:
                self._apply_metadata(
                    show=show,
                    details=details,
                    metadata_language=metadata_language,
                )

                show.genres = genres
                show.networks = networks

            seasons = self._sync_seasons(
                show=show,
                seasons=details.seasons,
            )

            self._session.flush()

            self._sync_episodes(
                show=show,
                seasons=seasons,
                language=metadata_language,
            )
            show.metadata_updated_at = datetime.now(UTC)

            self._session.commit()
            self._session.refresh(show)

            return show

        except Exception:
            self._session.rollback()
            raise

    def _should_refresh(
        self,
        show: Show,
    ) -> bool:
        """Return whether the show's metadata should be refreshed automatically."""

        normalized_status = show.status.strip().lower() if show.status else ""

        if normalized_status in {
            "ended",
            "canceled",
            "cancelled",
        }:
            return False

        if show.metadata_updated_at is None:
            return True

        metadata_updated_at = show.metadata_updated_at

        if metadata_updated_at.tzinfo is None:
            metadata_updated_at = metadata_updated_at.replace(
                tzinfo=UTC,
            )

        return (datetime.now(UTC) - metadata_updated_at) >= timedelta(
            days=self._settings.metadata_refresh_days,
        )

    def _resolve_genres(
        self,
        details: ShowDetailsResponse,
    ) -> list[Genre]:
        """Resolve TMDB genres into local Genre entities."""

        return [
            self._genre_repository.get_or_create(
                tmdb_id=genre.tmdb_id,
                name=genre.name,
            )
            for genre in details.genres
        ]

    def _resolve_networks(
        self,
        details: ShowDetailsResponse,
    ) -> list[Network]:
        """Resolve TMDB networks into local Network entities."""

        return [
            self._network_repository.get_or_create(
                tmdb_id=network.tmdb_id,
                name=network.name,
                tmdb_logo_path=network.logo_path,
                origin_country=network.origin_country,
            )
            for network in details.networks
        ]

    def _build_show(
        self,
        *,
        details: ShowDetailsResponse,
        metadata_language: str,
    ) -> Show:
        """Build a new Show entity."""

        show = Show()

        self._apply_metadata(
            show=show,
            details=details,
            metadata_language=metadata_language,
        )

        return show

    def _apply_metadata(
        self,
        *,
        show: Show,
        details: ShowDetailsResponse,
        metadata_language: str,
    ) -> None:
        """Apply TMDB metadata to a Show."""

        show.tmdb_id = details.tmdb_id
        show.title = details.title
        show.original_title = details.original_title
        show.overview = details.overview
        show.tagline = details.tagline

        show.first_air_date = details.first_air_date
        show.last_air_date = details.last_air_date

        show.tmdb_poster_path = details.poster_path
        show.tmdb_backdrop_path = details.backdrop_path

        show.homepage_url = details.homepage_url
        show.original_language = details.original_language

        show.status = details.status
        show.show_type = details.show_type
        show.in_production = details.in_production

        show.number_of_seasons = details.number_of_seasons
        show.number_of_episodes = details.number_of_episodes

        show.episode_run_time = details.episode_run_times[0] if details.episode_run_times else None

        show.popularity = details.popularity
        show.vote_average = details.vote_average
        show.vote_count = details.vote_count

        show.metadata_language = metadata_language
        # show.metadata_updated_at = datetime.now(timezone.utc)

    def _sync_seasons(
        self,
        *,
        show: Show,
        seasons: list[ShowSeasonSummary],
    ) -> list[Season]:
        """Create or update seasons returned by TMDB.

        Seasons missing from the TMDB response are preserved locally.
        """

        resolved_seasons: list[Season] = []

        for season_details in seasons:
            season = self._season_repository.get_by_tmdb_id(
                show_id=show.id,
                tmdb_id=season_details.tmdb_id,
            )

            if season is None:
                season = self._season_repository.get_by_number(
                    show_id=show.id,
                    season_number=season_details.season_number,
                )

            if season is None:
                season = Season(
                    show_id=show.id,
                )

                self._apply_season_metadata(
                    season=season,
                    details=season_details,
                )

                self._season_repository.add(season)
            else:
                self._apply_season_metadata(
                    season=season,
                    details=season_details,
                )

            resolved_seasons.append(season)

        return resolved_seasons

    def _sync_episodes(
        self,
        *,
        show: Show,
        seasons: list[Season],
        language: str,
    ) -> None:
        """Synchronize locally stored episodes with TMDB."""

        for season in seasons:
            episodes = self._tmdb_season_details_service.get_episodes(
                tmdb_id=show.tmdb_id,
                season_number=season.season_number,
                language=language,
            )

            self._sync_season_episodes(
                season=season,
                episodes=episodes,
            )

    def _sync_season_episodes(
        self,
        *,
        season: Season,
        episodes: list[EpisodeSummary],
    ) -> None:
        """Create or update episodes returned by TMDB.

        Episodes missing from the TMDB response are preserved locally.
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

                self._episode_repository.add(episode)
                continue

            self._apply_episode_metadata(
                episode=episode,
                details=episode_details,
            )

    def refresh_show(
        self,
        *,
        tmdb_id: int,
        language: str | None = None,
    ) -> Show:
        """Force a metadata refresh for a TV series."""

        return self.import_show(
            tmdb_id=tmdb_id,
            language=language,
            force_refresh=True,
        )

    @staticmethod
    def _apply_season_metadata(
        *,
        season: Season,
        details: ShowSeasonSummary,
    ) -> None:
        """Apply TMDB metadata to a local season."""

        season.tmdb_id = details.tmdb_id
        season.season_number = details.season_number
        season.title = details.title
        season.overview = details.overview or None
        season.air_date = details.air_date
        season.episode_count = details.episode_count
        season.vote_average = details.vote_average
        season.tmdb_poster_path = details.poster_path

    @staticmethod
    def _apply_episode_metadata(
        *,
        episode: Episode,
        details: EpisodeSummary,
    ) -> None:
        """Apply TMDB metadata to a local episode."""

        episode.tmdb_id = details.tmdb_id
        episode.episode_number = details.episode_number
        episode.title = details.title
        episode.overview = details.overview or None
        episode.air_date = details.air_date
        episode.runtime = details.runtime
        episode.vote_average = details.vote_average
        episode.vote_count = details.vote_count
        episode.tmdb_still_path = details.still_path
