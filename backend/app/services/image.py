"""Resolve and cache images belonging to local SofaWatch resources."""

from collections.abc import Callable
from pathlib import Path
from uuid import UUID

from sqlalchemy.orm import Session

from app.core.storage import ImageStorage
from app.repositories.episode import EpisodeRepository
from app.repositories.season import SeasonRepository
from app.repositories.show import ShowRepository
from app.services.image_cache import ImageCacheService


class ImageOwnerNotFoundError(LookupError):
    """Raised when the resource owning an image does not exist."""


class ImageNotAvailableError(LookupError):
    """Raised when a resource has no local or provider image."""


class ImageService:
    """Resolve local images and cache provider images when necessary."""

    def __init__(
        self,
        *,
        session: Session,
        storage: ImageStorage,
        cache_service: ImageCacheService,
        show_repository: ShowRepository,
        season_repository: SeasonRepository,
        episode_repository: EpisodeRepository,
    ) -> None:
        self._session = session
        self._storage = storage
        self._cache_service = cache_service
        self._show_repository = show_repository
        self._season_repository = season_repository
        self._episode_repository = episode_repository

    def resolve_show_poster(
        self,
        show_id: UUID,
    ) -> Path:
        """Return a locally cached show poster."""

        show = self._show_repository.get_by_id(
            show_id,
        )

        if show is None:
            raise ImageOwnerNotFoundError(
                "TV series not found."
            )

        return self._resolve_image(
            local_path=show.local_poster_path,
            provider_path=show.tmdb_poster_path,
            cache_image=lambda: self._cache_service.cache_show_poster(
                show_id=show.id,
                tmdb_path=show.tmdb_poster_path or "",
            ),
            set_local_path=lambda path: setattr(
                show,
                "local_poster_path",
                path,
            ),
        )

    def resolve_show_backdrop(
        self,
        show_id: UUID,
    ) -> Path:
        """Return a locally cached show backdrop."""

        show = self._show_repository.get_by_id(
            show_id,
        )

        if show is None:
            raise ImageOwnerNotFoundError(
                "TV series not found."
            )

        return self._resolve_image(
            local_path=show.local_backdrop_path,
            provider_path=show.tmdb_backdrop_path,
            cache_image=lambda: self._cache_service.cache_show_backdrop(
                show_id=show.id,
                tmdb_path=show.tmdb_backdrop_path or "",
            ),
            set_local_path=lambda path: setattr(
                show,
                "local_backdrop_path",
                path,
            ),
        )

    def resolve_season_poster(
        self,
        season_id: UUID,
    ) -> Path:
        """Return a locally cached season poster."""

        season = self._season_repository.get_by_id(
            season_id,
        )

        if season is None:
            raise ImageOwnerNotFoundError(
                "TV season not found."
            )

        return self._resolve_image(
            local_path=season.local_poster_path,
            provider_path=season.tmdb_poster_path,
            cache_image=lambda: self._cache_service.cache_season_poster(
                season_id=season.id,
                tmdb_path=season.tmdb_poster_path or "",
            ),
            set_local_path=lambda path: setattr(
                season,
                "local_poster_path",
                path,
            ),
        )

    def resolve_episode_still(
        self,
        episode_id: UUID,
    ) -> Path:
        """Return a locally cached episode still."""

        episode = self._episode_repository.get_by_id(
            episode_id,
        )

        if episode is None:
            raise ImageOwnerNotFoundError(
                "TV episode not found."
            )

        return self._resolve_image(
            local_path=episode.local_still_path,
            provider_path=episode.tmdb_still_path,
            cache_image=lambda: self._cache_service.cache_episode_still(
                episode_id=episode.id,
                tmdb_path=episode.tmdb_still_path or "",
            ),
            set_local_path=lambda path: setattr(
                episode,
                "local_still_path",
                path,
            ),
        )

    def _resolve_image(
        self,
        *,
        local_path: str | None,
        provider_path: str | None,
        cache_image: Callable[[], str],
        set_local_path: Callable[[str], None],
    ) -> Path:
        """Resolve an existing cache file or download it from the provider."""

        if local_path:
            cached_path = self._resolve_existing_path(
                local_path,
            )

            if cached_path is not None:
                return cached_path

        if not provider_path:
            raise ImageNotAvailableError(
                "The requested image is not available."
            )

        relative_path = cache_image()
        absolute_path = self._storage.from_relative_path(
            relative_path,
        )

        set_local_path(
            relative_path,
        )

        try:
            self._session.commit()
        except Exception:
            self._session.rollback()

            absolute_path.unlink(
                missing_ok=True,
            )

            raise

        return absolute_path

    def _resolve_existing_path(
        self,
        relative_path: str,
    ) -> Path | None:
        """Return an existing safe cache path."""

        try:
            path = self._storage.from_relative_path(
                relative_path,
            )
        except ValueError:
            return None

        if not path.is_file():
            return None

        return path