from pathlib import Path
from types import SimpleNamespace
from uuid import uuid4

import pytest

from app.core.storage import ImageStorage


def create_storage(
    tmp_path: Path,
) -> ImageStorage:
    """Create image storage using a temporary test directory."""

    settings = SimpleNamespace(
        image_storage_path=str(
            tmp_path / "images",
        ),
    )

    return ImageStorage(
        settings=settings,
    )


def test_base_path_is_resolved_from_settings(
    tmp_path: Path,
) -> None:
    """Resolve the configured image storage directory."""

    storage = create_storage(
        tmp_path,
    )

    assert storage.base_path == (
        tmp_path / "images"
    ).resolve()


def test_ensure_base_path_creates_storage_directory(
    tmp_path: Path,
) -> None:
    """Create the image storage root when it does not exist."""

    storage = create_storage(
        tmp_path,
    )

    assert storage.base_path.exists() is False

    storage.ensure_base_path()

    assert storage.base_path.is_dir()


def test_show_poster_path_creates_resource_directory(
    tmp_path: Path,
) -> None:
    """Create and return the cache path for a show poster."""

    storage = create_storage(
        tmp_path,
    )
    show_id = uuid4()

    result = storage.show_poster_path(
        show_id,
        extension="jpg",
    )

    assert result == (
        storage.base_path
        / "shows"
        / str(show_id)
        / "poster.jpg"
    )
    assert result.parent.is_dir()


def test_show_backdrop_path_creates_resource_directory(
    tmp_path: Path,
) -> None:
    """Create and return the cache path for a show backdrop."""

    storage = create_storage(
        tmp_path,
    )
    show_id = uuid4()

    result = storage.show_backdrop_path(
        show_id,
        extension="webp",
    )

    assert result == (
        storage.base_path
        / "shows"
        / str(show_id)
        / "backdrop.webp"
    )
    assert result.parent.is_dir()


def test_season_poster_path_creates_resource_directory(
    tmp_path: Path,
) -> None:
    """Create and return the cache path for a season poster."""

    storage = create_storage(
        tmp_path,
    )
    season_id = uuid4()

    result = storage.season_poster_path(
        season_id,
        extension="png",
    )

    assert result == (
        storage.base_path
        / "seasons"
        / str(season_id)
        / "poster.png"
    )
    assert result.parent.is_dir()


def test_episode_still_path_creates_resource_directory(
    tmp_path: Path,
) -> None:
    """Create and return the cache path for an episode still."""

    storage = create_storage(
        tmp_path,
    )
    episode_id = uuid4()

    result = storage.episode_still_path(
        episode_id,
        extension="jpg",
    )

    assert result == (
        storage.base_path
        / "episodes"
        / str(episode_id)
        / "still.jpg"
    )
    assert result.parent.is_dir()


def test_to_relative_path_returns_portable_path(
    tmp_path: Path,
) -> None:
    """Convert an absolute cache path into a relative stored path."""

    storage = create_storage(
        tmp_path,
    )
    show_id = uuid4()

    path = storage.show_poster_path(
        show_id,
        extension="jpg",
    )

    result = storage.to_relative_path(
        path,
    )

    assert result == (
        f"shows/{show_id}/poster.jpg"
    )


def test_from_relative_path_resolves_stored_path(
    tmp_path: Path,
) -> None:
    """Resolve a stored relative cache path."""

    storage = create_storage(
        tmp_path,
    )
    show_id = uuid4()

    result = storage.from_relative_path(
        f"shows/{show_id}/poster.jpg",
    )

    assert result == (
        storage.base_path
        / "shows"
        / str(show_id)
        / "poster.jpg"
    )


def test_from_relative_path_rejects_path_traversal(
    tmp_path: Path,
) -> None:
    """Reject relative paths that escape the image storage directory."""

    storage = create_storage(
        tmp_path,
    )

    with pytest.raises(
        ValueError,
        match="outside the configured storage directory",
    ):
        storage.from_relative_path(
            "../../outside.jpg",
        )