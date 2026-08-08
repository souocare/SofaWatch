from datetime import UTC, datetime, timedelta

from sqlalchemy.orm import Session

from app.core.config import Settings
from app.models.genre import Genre
from app.models.movie import Movie
from app.repositories.genre import GenreRepository
from app.repositories.movie import MovieRepository
from app.schemas.tmdb_movie import MovieDetailsResponse
from app.services.tmdb_movie_details import TMDBMovieDetailsService


class MovieImportService:
    """Import and refresh movie metadata."""

    def __init__(
        self,
        *,
        session: Session,
        settings: Settings,
        movie_repository: MovieRepository,
        genre_repository: GenreRepository,
        tmdb_movie_details_service: TMDBMovieDetailsService,
    ) -> None:
        self._session = session
        self._settings = settings
        self._movie_repository = movie_repository
        self._genre_repository = genre_repository
        self._tmdb_movie_details_service = tmdb_movie_details_service

    def import_movie(
        self,
        *,
        tmdb_id: int,
        language: str | None = None,
        force_refresh: bool = False,
    ) -> Movie:
        """Import a movie or refresh its locally stored metadata."""

        metadata_language = (
            language
            or self._settings.default_language
        )

        movie = self._movie_repository.get_by_tmdb_id(
            tmdb_id,
        )

        if (
            movie is not None
            and not force_refresh
            and not self._should_refresh(movie)
        ):
            return movie

        details = self._tmdb_movie_details_service.get_details(
            tmdb_id=tmdb_id,
            language=metadata_language,
        )

        try:
            genres = self._resolve_genres(
                details,
            )

            if movie is None:
                movie = self._build_movie(
                    details=details,
                    metadata_language=metadata_language,
                )

                movie.genres = genres

                self._movie_repository.add(
                    movie,
                )
            else:
                self._apply_metadata(
                    movie=movie,
                    details=details,
                    metadata_language=metadata_language,
                )

                movie.genres = genres

            movie.metadata_updated_at = datetime.now(
                UTC,
            )

            self._session.commit()
            self._session.refresh(movie)

            return movie

        except Exception:
            self._session.rollback()
            raise

    def refresh_movie(
        self,
        *,
        tmdb_id: int,
        language: str | None = None,
    ) -> Movie:
        """Force a metadata refresh for a movie."""

        return self.import_movie(
            tmdb_id=tmdb_id,
            language=language,
            force_refresh=True,
        )

    def _should_refresh(
        self,
        movie: Movie,
    ) -> bool:
        """Return whether locally stored metadata is stale."""

        if movie.metadata_updated_at is None:
            return True

        metadata_updated_at = (
            movie.metadata_updated_at
        )

        if metadata_updated_at.tzinfo is None:
            metadata_updated_at = (
                metadata_updated_at.replace(
                    tzinfo=UTC,
                )
            )

        return (
            datetime.now(UTC)
            - metadata_updated_at
        ) >= timedelta(
            days=self._settings.metadata_refresh_days,
        )

    def _resolve_genres(
        self,
        details: MovieDetailsResponse,
    ) -> list[Genre]:
        """Resolve TMDB genres into local Genre entities."""

        return [
            self._genre_repository.get_or_create(
                tmdb_id=genre.tmdb_id,
                name=genre.name,
            )
            for genre in details.genres
        ]

    def _build_movie(
        self,
        *,
        details: MovieDetailsResponse,
        metadata_language: str,
    ) -> Movie:
        """Build a new local Movie entity."""

        movie = Movie()

        self._apply_metadata(
            movie=movie,
            details=details,
            metadata_language=metadata_language,
        )

        return movie

    @staticmethod
    def _apply_metadata(
        *,
        movie: Movie,
        details: MovieDetailsResponse,
        metadata_language: str,
    ) -> None:
        """Apply TMDB metadata to a local Movie entity."""

        movie.tmdb_id = details.tmdb_id

        movie.title = details.title
        movie.original_title = details.original_title

        movie.overview = details.overview
        movie.tagline = details.tagline

        movie.release_date = details.release_date

        movie.tmdb_poster_path = details.poster_path
        movie.tmdb_backdrop_path = details.backdrop_path

        movie.original_language = (
            details.original_language
        )

        movie.runtime = details.runtime
        movie.status = details.status

        movie.adult = details.adult
        movie.video = details.video

        movie.popularity = details.popularity
        movie.vote_average = details.vote_average
        movie.vote_count = details.vote_count

        movie.metadata_language = metadata_language