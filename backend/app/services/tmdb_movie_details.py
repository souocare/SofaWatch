from app.core.config import Settings
from app.providers.tmdb import TMDBClient
from app.providers.tmdb.schemas import TMDBMovieDetails
from app.schemas.tmdb_movie import (
    MovieDetailsResponse,
    MovieGenre,
)


class TMDBMovieDetailsService:
    """Service responsible for retrieving movie details."""

    def __init__(
        self,
        settings: Settings,
        tmdb_client: TMDBClient,
    ) -> None:
        self._settings = settings
        self._tmdb_client = tmdb_client

    def get_details(
        self,
        *,
        tmdb_id: int,
        language: str | None = None,
    ) -> MovieDetailsResponse:
        """Get detailed information about a movie."""

        tmdb_movie = self._tmdb_client.get_movie_details(
            tmdb_id=tmdb_id,
            language=language,
        )

        return self._map_movie_details(tmdb_movie)

    def _map_movie_details(
        self,
        tmdb_movie: TMDBMovieDetails,
    ) -> MovieDetailsResponse:
        """Map TMDB movie details to the public SofaWatch schema."""

        return MovieDetailsResponse(
            tmdb_id=tmdb_movie.id,
            title=tmdb_movie.title,
            original_title=tmdb_movie.original_title,
            overview=tmdb_movie.overview or None,
            tagline=tmdb_movie.tagline or None,
            release_date=tmdb_movie.release_date,
            poster_path=tmdb_movie.poster_path,
            backdrop_path=tmdb_movie.backdrop_path,
            poster_url=self._build_image_url(
                tmdb_movie.poster_path,
                size="w500",
            ),
            backdrop_url=self._build_image_url(
                tmdb_movie.backdrop_path,
                size="original",
            ),
            genres=[
                MovieGenre(
                    tmdb_id=genre.id,
                    name=genre.name,
                )
                for genre in tmdb_movie.genres
            ],
            original_language=tmdb_movie.original_language,
            runtime=tmdb_movie.runtime,
            status=tmdb_movie.status,
            popularity=tmdb_movie.popularity,
            vote_average=tmdb_movie.vote_average,
            vote_count=tmdb_movie.vote_count,
        )

    def _build_image_url(
        self,
        image_path: str | None,
        *,
        size: str,
    ) -> str | None:
        """Build a full TMDB image URL."""

        if image_path is None:
            return None

        base_url = self._settings.tmdb_image_base_url.rstrip("/")

        return f"{base_url}/{size}{image_path}"