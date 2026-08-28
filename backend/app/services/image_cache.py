from collections.abc import Callable
from pathlib import Path
from uuid import UUID

import httpx

from app.core.config import Settings
from app.core.storage import ImageStorage


class ImageCacheError(RuntimeError):
    """Raised when an image cannot be downloaded or cached."""


class ImageCacheService:
    """Download and store provider images in the local cache."""

    _POSTER_SIZE = "w500"
    _BACKDROP_SIZE = "original"
    _STILL_SIZE = "w500"

    _CONTENT_TYPE_EXTENSIONS = {
        "image/jpeg": "jpg",
        "image/png": "png",
        "image/webp": "webp",
    }

    def __init__(
        self,
        *,
        settings: Settings,
        storage: ImageStorage,
        http_client: httpx.Client | None = None,
    ) -> None:
        self._settings = settings
        self._storage = storage
        self._owns_http_client = http_client is None

        self._http_client = http_client or httpx.Client(
            timeout=settings.tmdb_timeout_seconds,
            follow_redirects=True,
        )

    def cache_show_poster(
        self,
        *,
        show_id: UUID,
        tmdb_path: str,
    ) -> str:
        """Download and cache a TV series poster."""

        return self._cache_image(
            tmdb_path=tmdb_path,
            size=self._POSTER_SIZE,
            destination_factory=lambda extension: self._storage.show_poster_path(
                show_id,
                extension=extension,
            ),
        )

    def cache_show_backdrop(
        self,
        *,
        show_id: UUID,
        tmdb_path: str,
    ) -> str:
        """Download and cache a TV series backdrop."""

        return self._cache_image(
            tmdb_path=tmdb_path,
            size=self._BACKDROP_SIZE,
            destination_factory=lambda extension: self._storage.show_backdrop_path(
                show_id,
                extension=extension,
            ),
        )

    def cache_movie_poster(
        self,
        *,
        movie_id: UUID,
        tmdb_path: str,
    ) -> str:
        """Download and cache a movie poster."""

        return self._cache_image(
            tmdb_path=tmdb_path,
            size=self._POSTER_SIZE,
            destination_factory=lambda extension: self._storage.movie_poster_path(
                movie_id,
                extension=extension,
            ),
        )

    def cache_movie_backdrop(
        self,
        *,
        movie_id: UUID,
        tmdb_path: str,
    ) -> str:
        """Download and cache a movie backdrop."""

        return self._cache_image(
            tmdb_path=tmdb_path,
            size=self._BACKDROP_SIZE,
            destination_factory=lambda extension: self._storage.movie_backdrop_path(
                movie_id,
                extension=extension,
            ),
        )

    def cache_season_poster(
        self,
        *,
        season_id: UUID,
        tmdb_path: str,
    ) -> str:
        """Download and cache a season poster."""

        return self._cache_image(
            tmdb_path=tmdb_path,
            size=self._POSTER_SIZE,
            destination_factory=lambda extension: self._storage.season_poster_path(
                season_id,
                extension=extension,
            ),
        )

    def cache_episode_still(
        self,
        *,
        episode_id: UUID,
        tmdb_path: str,
    ) -> str:
        """Download and cache an episode still."""

        return self._cache_image(
            tmdb_path=tmdb_path,
            size=self._STILL_SIZE,
            destination_factory=lambda extension: self._storage.episode_still_path(
                episode_id,
                extension=extension,
            ),
        )

    def _cache_image(
        self,
        *,
        tmdb_path: str,
        size: str,
        destination_factory: Callable[[str], Path],
    ) -> str:
        """Download one TMDB image and return its relative cache path."""

        normalized_path = tmdb_path.lstrip("/")

        image_url = f"{self._settings.tmdb_image_base_url.rstrip('/')}/{size}/{normalized_path}"

        try:
            response = self._http_client.get(
                image_url,
            )
            response.raise_for_status()
        except httpx.HTTPError as error:
            raise ImageCacheError("The provider image could not be downloaded.") from error

        content_type = (
            response.headers.get(
                "content-type",
                "",
            )
            .split(";")[0]
            .strip()
            .lower()
        )

        extension = self._CONTENT_TYPE_EXTENSIONS.get(
            content_type,
        )

        if extension is None:
            raise ImageCacheError(f"Unsupported image content type: {content_type or 'unknown'}.")

        destination = destination_factory(
            extension,
        )

        temporary_path = destination.with_suffix(f"{destination.suffix}.tmp")

        try:
            temporary_path.write_bytes(
                response.content,
            )
            temporary_path.replace(
                destination,
            )
        except OSError as error:
            temporary_path.unlink(
                missing_ok=True,
            )

            raise ImageCacheError("The image could not be written to local storage.") from error

        return self._storage.to_relative_path(
            destination,
        )

    def close(self) -> None:
        """Close the internally owned HTTP client."""

        if self._owns_http_client:
            self._http_client.close()

    def __enter__(self) -> "ImageCacheService":
        return self

    def __exit__(
        self,
        exc_type: type[BaseException] | None,
        exc_value: BaseException | None,
        traceback: object | None,
    ) -> None:
        self.close()
