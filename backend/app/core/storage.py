from pathlib import Path
from uuid import UUID

from app.core.config import Settings


class ImageStorage:
    """Resolve image cache paths without exposing absolute paths."""

    def __init__(
        self,
        *,
        settings: Settings,
    ) -> None:
        self._base_path = Path(
            settings.image_storage_path,
        ).resolve()

    @property
    def base_path(self) -> Path:
        """Return the absolute image cache directory."""

        return self._base_path

    def ensure_base_path(self) -> None:
        """Create the image cache root when it does not exist."""

        self._base_path.mkdir(
            parents=True,
            exist_ok=True,
        )

    def show_poster_path(
        self,
        show_id: UUID,
        *,
        extension: str,
    ) -> Path:
        """Return the cached poster path for a TV series."""

        return self._resource_path(
            category="shows",
            resource_id=show_id,
            filename=f"poster.{extension}",
        )

    def show_backdrop_path(
        self,
        show_id: UUID,
        *,
        extension: str,
    ) -> Path:
        """Return the cached backdrop path for a TV series."""

        return self._resource_path(
            category="shows",
            resource_id=show_id,
            filename=f"backdrop.{extension}",
        )

    def season_poster_path(
        self,
        season_id: UUID,
        *,
        extension: str,
    ) -> Path:
        """Return the cached poster path for a season."""

        return self._resource_path(
            category="seasons",
            resource_id=season_id,
            filename=f"poster.{extension}",
        )

    def episode_still_path(
        self,
        episode_id: UUID,
        *,
        extension: str,
    ) -> Path:
        """Return the cached still path for an episode."""

        return self._resource_path(
            category="episodes",
            resource_id=episode_id,
            filename=f"still.{extension}",
        )

    def to_relative_path(
        self,
        path: Path,
    ) -> str:
        """Return a cache path relative to the image storage root."""

        return (
            path.resolve()
            .relative_to(
                self._base_path,
            )
            .as_posix()
        )

    def from_relative_path(
        self,
        relative_path: str,
    ) -> Path:
        """Resolve a stored relative cache path safely."""

        resolved_path = (self._base_path / relative_path).resolve()

        if not resolved_path.is_relative_to(
            self._base_path,
        ):
            raise ValueError("Image path is outside the configured storage directory.")

        return resolved_path

    def _resource_path(
        self,
        *,
        category: str,
        resource_id: UUID,
        filename: str,
    ) -> Path:
        """Build and create a resource-specific cache directory."""

        directory = self._base_path / category / str(resource_id)

        directory.mkdir(
            parents=True,
            exist_ok=True,
        )

        return directory / filename
