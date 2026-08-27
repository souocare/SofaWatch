import logging
from collections.abc import Mapping
from typing import Any, TypeVar

import httpx
from pydantic import BaseModel, ValidationError

from app.core.config import Settings
from app.providers.tmdb.exceptions import (
    TMDBConfigurationError,
    TMDBNotFoundError,
    TMDBRequestError,
    TMDBResponseError,
)
from app.providers.tmdb.schemas import (
    TMDBGenreListResponse,
    TMDBHealthResponse,
    TMDBMovieDetails,
    TMDBMovieSearchResponse,
    TMDBMultiSearchResponse,
    TMDBSeasonDetails,
    TMDBTVDetails,
    TMDBTVSearchResponse,
)

logger = logging.getLogger(__name__)

ResponseModel = TypeVar("ResponseModel", bound=BaseModel)


class TMDBClient:
    """HTTP client responsible for communicating with the TMDB API."""

    def __init__(
        self,
        settings: Settings,
        http_client: httpx.Client | None = None,
    ) -> None:
        api_token = settings.tmdb_api_token

        if api_token is None:
            raise TMDBConfigurationError("TMDB API token is not configured.")

        self._settings = settings
        self._owns_http_client = http_client is None

        self._http_client = http_client or httpx.Client(
            base_url=settings.tmdb_base_url,
            headers={
                "Authorization": (f"Bearer {api_token.get_secret_value()}"),
                "Accept": "application/json",
            },
            timeout=settings.tmdb_timeout_seconds,
        )

    def get(
        self,
        path: str,
        *,
        response_model: type[ResponseModel],
        params: Mapping[str, Any] | None = None,
    ) -> ResponseModel:
        """Perform a GET request and validate the TMDB response."""

        try:
            response = self._http_client.get(
                path,
                params=params,
            )
            response.raise_for_status()

        except httpx.TimeoutException as error:
            raise TMDBRequestError("The request to TMDB timed out.") from error

        except httpx.HTTPStatusError as error:
            if error.response.status_code == httpx.codes.NOT_FOUND:
                raise TMDBNotFoundError("The requested TMDB resource was not found.") from error

            raise TMDBResponseError(
                "TMDB returned an unsuccessful response "
                f"with status code {error.response.status_code}."
            ) from error

        except httpx.RequestError as error:
            raise TMDBRequestError("TMDB could not be reached.") from error

        try:
            return response_model.model_validate(response.json())

        except (ValueError, ValidationError) as error:
            logger.exception(
                "TMDB response failed schema validation: %s",
                error,
            )
            raise TMDBResponseError("TMDB returned an invalid response.") from error

    def search_tv_shows(
        self,
        *,
        query: str,
        page: int = 1,
        language: str | None = None,
    ) -> TMDBTVSearchResponse:
        """Search for TV series by name in TMDB."""

        normalized_query = query.strip()

        if not normalized_query:
            raise ValueError("The search query cannot be empty.")

        if page < 1:
            raise ValueError("The page must be greater than or equal to 1.")

        request_language = language or self._settings.default_language

        return self.get(
            "/search/tv",
            response_model=TMDBTVSearchResponse,
            params={
                "query": normalized_query,
                "page": page,
                "language": request_language,
                "include_adult": False,
            },
        )

    def search_movies(
        self,
        *,
        query: str,
        page: int = 1,
        language: str | None = None,
    ) -> TMDBMovieSearchResponse:
        """Search for movies by title in TMDB."""

        normalized_query = query.strip()

        if not normalized_query:
            raise ValueError("The search query cannot be empty.")

        if page < 1:
            raise ValueError("The page must be greater than or equal to 1.")

        request_language = language or self._settings.default_language

        return self.get(
            "/search/movie",
            response_model=TMDBMovieSearchResponse,
            params={
                "query": normalized_query,
                "page": page,
                "language": request_language,
                "include_adult": False,
            },
        )

    def get_movie_details(
        self,
        *,
        tmdb_id: int,
        language: str | None = None,
    ) -> TMDBMovieDetails:
        """Get detailed information about a movie from TMDB."""

        if tmdb_id < 1:
            raise ValueError("The TMDB ID must be greater than or equal to 1.")

        request_language = language or self._settings.default_language

        return self.get(
            f"/movie/{tmdb_id}",
            response_model=TMDBMovieDetails,
            params={
                "language": request_language,
            },
        )

    def get_tv_show_details(
        self,
        *,
        tmdb_id: int,
        language: str | None = None,
    ) -> TMDBTVDetails:
        """Get detailed information about a TV series from TMDB."""

        if tmdb_id < 1:
            raise ValueError("The TMDB ID must be greater than or equal to 1.")

        request_language = language or self._settings.default_language

        return self.get(
            f"/tv/{tmdb_id}",
            response_model=TMDBTVDetails,
            params={
                "language": request_language,
            },
        )

    def search_multi(
        self,
        *,
        query: str,
        page: int = 1,
        language: str | None = None,
    ) -> TMDBMultiSearchResponse:
        """Search for movies, TV series and people in TMDB."""

        normalized_query = query.strip()

        if not normalized_query:
            raise ValueError("The search query cannot be empty.")

        if page < 1:
            raise ValueError("The page must be greater than or equal to 1.")

        request_language = language or self._settings.default_language

        return self.get(
            "/search/multi",
            response_model=TMDBMultiSearchResponse,
            params={
                "query": normalized_query,
                "page": page,
                "language": request_language,
                "include_adult": False,
            },
        )

    def get_tv_season_details(
        self,
        *,
        tmdb_id: int,
        season_number: int,
        language: str | None = None,
    ) -> TMDBSeasonDetails:
        """Get detailed information about a TV season from TMDB."""

        if tmdb_id < 1:
            raise ValueError("The TMDB ID must be greater than or equal to 1.")

        if season_number < 0:
            raise ValueError("The season number must be greater than or equal to 0.")

        request_language = language or self._settings.default_language

        return self.get(
            f"/tv/{tmdb_id}/season/{season_number}",
            response_model=TMDBSeasonDetails,
            params={
                "language": request_language,
            },
        )

    def get_trending_all(
        self,
        *,
        time_window: str,
        language: str | None = None,
    ) -> TMDBMultiSearchResponse:
        """Get trending movies, TV series and people from TMDB."""
        if time_window not in {"day", "week"}:
            raise ValueError("The trending time window must be 'day' or 'week'.")
        request_language = language or self._settings.default_language
        return self.get(
            f"/trending/all/{time_window}",
            response_model=TMDBMultiSearchResponse,
            params={
                "language": request_language,
            },
        )

    def get_popular_tv_shows(
        self,
        *,
        page: int = 1,
        language: str | None = None,
    ) -> TMDBTVSearchResponse:
        """Get popular TV series from TMDB."""

        if page < 1:
            raise ValueError("The page must be greater than or equal to 1.")

        request_language = language or self._settings.default_language

        return self.get(
            "/tv/popular",
            response_model=TMDBTVSearchResponse,
            params={
                "page": page,
                "language": request_language,
            },
        )

    def get_popular_movies(
        self,
        *,
        language: str | None = None,
        page: int = 1,
    ) -> TMDBMovieSearchResponse:
        """Return popular Movies from TMDB."""

        if page < 1:
            raise ValueError("page must be greater than zero")

        params: dict[str, str | int] = {
            "page": page,
        }

        if language is not None:
            params["language"] = language

        return self.get(
            "/movie/popular",
            params=params,
            response_model=TMDBMovieSearchResponse,
        )

    def get_tv_genres(
        self,
        *,
        language: str | None = None,
    ) -> TMDBGenreListResponse:
        """Return the official TMDB genres supported by TV series."""

        request_language = language or self._settings.default_language

        return self.get(
            "/genre/tv/list",
            response_model=TMDBGenreListResponse,
            params={
                "language": request_language,
            },
        )

    def get_movie_genres(
        self,
        *,
        language: str | None = None,
    ) -> TMDBGenreListResponse:
        """Return the official TMDB genres supported by Movies."""

        request_language = language or self._settings.default_language

        return self.get(
            "/genre/movie/list",
            response_model=TMDBGenreListResponse,
            params={
                "language": request_language,
            },
        )

    def discover_tv_shows(
        self,
        *,
        genre_id: int,
        page: int = 1,
        language: str | None = None,
    ) -> TMDBTVSearchResponse:
        """Discover popular TV series filtered by genre."""

        if genre_id < 1:
            raise ValueError("The genre ID must be greater than zero.")

        if page < 1:
            raise ValueError("The page must be greater than or equal to 1.")

        request_language = language or self._settings.default_language

        return self.get(
            "/discover/tv",
            response_model=TMDBTVSearchResponse,
            params={
                "page": page,
                "language": request_language,
                "with_genres": genre_id,
                "sort_by": "popularity.desc",
                "include_adult": False,
            },
        )

    def discover_movies(
        self,
        *,
        genre_id: int,
        page: int = 1,
        language: str | None = None,
    ) -> TMDBMovieSearchResponse:
        """Discover popular Movies filtered by genre."""

        if genre_id < 1:
            raise ValueError("The genre ID must be greater than zero.")

        if page < 1:
            raise ValueError("The page must be greater than or equal to 1.")

        request_language = language or self._settings.default_language

        return self.get(
            "/discover/movie",
            response_model=TMDBMovieSearchResponse,
            params={
                "page": page,
                "language": request_language,
                "with_genres": genre_id,
                "sort_by": "popularity.desc",
                "include_adult": False,
                "include_video": False,
            },
        )

    def check_health(self) -> None:
        """Verify that the configured TMDB API is reachable."""

        self.get(
            "/configuration",
            response_model=TMDBHealthResponse,
        )

    def close(self) -> None:
        """Close the internally managed HTTP client."""

        if self._owns_http_client:
            self._http_client.close()

    def __enter__(self) -> "TMDBClient":
        return self

    def __exit__(
        self,
        exc_type: type[BaseException] | None,
        exc_value: BaseException | None,
        traceback: object | None,
    ) -> None:
        self.close()
