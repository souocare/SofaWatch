from datetime import datetime, timedelta, timezone

from sqlalchemy.orm import Session

from app.core.config import Settings
from app.models.genre import Genre
from app.models.show import Show
from app.repositories.genre import GenreRepository
from app.repositories.show import ShowRepository
from app.schemas.tmdb_show import ShowDetailsResponse
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
        tmdb_show_details_service: TMDBShowDetailsService,
    ) -> None:
        self._session = session
        self._settings = settings
        self._show_repository = show_repository
        self._genre_repository = genre_repository
        self._tmdb_show_details_service = tmdb_show_details_service

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

        if (
            show is not None
            and not force_refresh
            and not self._should_refresh(show)
        ):
            return show

        details = self._tmdb_show_details_service.get_details(
            tmdb_id=tmdb_id,
            language=metadata_language,
        )

        try:
            genres = self._resolve_genres(details)

            if show is None:
                show = self._build_show(
                    details=details,
                    metadata_language=metadata_language,
                )

                show.genres = genres
                self._show_repository.add(show)
            else:
                self._apply_metadata(
                    show=show,
                    details=details,
                    metadata_language=metadata_language,
                )

                show.genres = genres

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
        """Return whether the show's metadata should be refreshed."""

        if show.metadata_updated_at is None:
            return True

        metadata_updated_at = show.metadata_updated_at

        if metadata_updated_at.tzinfo is None:
            metadata_updated_at = metadata_updated_at.replace(
                tzinfo=timezone.utc,
            )

        return (
            datetime.now(timezone.utc) - metadata_updated_at
        ) >= timedelta(
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

        show.episode_run_time = (
            details.episode_run_times[0]
            if details.episode_run_times
            else None
        )

        show.popularity = details.popularity
        show.vote_average = details.vote_average
        show.vote_count = details.vote_count

        show.metadata_language = metadata_language
        show.metadata_updated_at = datetime.now(timezone.utc)