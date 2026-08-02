from pathlib import Path
from unittest.mock import Mock
from uuid import uuid4

import pytest
from sqlalchemy.orm import Session

from app.core.storage import ImageStorage
from app.repositories.episode import EpisodeRepository
from app.repositories.season import SeasonRepository
from app.repositories.show import ShowRepository
from app.services.image import (
    ImageNotAvailableError,
    ImageOwnerNotFoundError,
    ImageService,
)
from app.services.image_cache import ImageCacheService


@pytest.fixture
def storage() -> Mock:
    """Provide mocked image storage."""

    return Mock(spec=ImageStorage)


@pytest.fixture
def cache_service() -> Mock:
    """Provide mocked image cache service."""

    return Mock(spec=ImageCacheService)


@pytest.fixture
def show_repository() -> Mock:
    """Provide a mocked show repository."""

    return Mock(spec=ShowRepository)


@pytest.fixture
def season_repository() -> Mock:
    """Provide a mocked season repository."""

    return Mock(spec=SeasonRepository)


@pytest.fixture
def episode_repository() -> Mock:
    """Provide a mocked episode repository."""

    return Mock(spec=EpisodeRepository)


@pytest.fixture
def image_service(
    db_session: Session,
    storage: Mock,
    cache_service: Mock,
    show_repository: Mock,
    season_repository: Mock,
    episode_repository: Mock,
) -> ImageService:
    """Provide an image service using mocked dependencies."""

    return ImageService(
        session=db_session,
        storage=storage,
        cache_service=cache_service,
        show_repository=show_repository,
        season_repository=season_repository,
        episode_repository=episode_repository,
    )


def test_resolve_show_poster_returns_existing_local_file(
    tmp_path: Path,
    image_service: ImageService,
    storage: Mock,
    cache_service: Mock,
    show_repository: Mock,
) -> None:
    """Return an existing cached show poster without downloading it."""

    show_id = uuid4()
    cached_file = tmp_path / "poster.jpg"
    cached_file.write_bytes(
        b"poster",
    )

    show = Mock(
        id=show_id,
        local_poster_path=f"shows/{show_id}/poster.jpg",
        tmdb_poster_path="/provider-poster.jpg",
    )

    show_repository.get_by_id.return_value = show
    storage.from_relative_path.return_value = cached_file

    result = image_service.resolve_show_poster(
        show_id,
    )

    assert result == cached_file

    storage.from_relative_path.assert_called_once_with(
        f"shows/{show_id}/poster.jpg",
    )
    cache_service.cache_show_poster.assert_not_called()


def test_resolve_show_poster_downloads_and_persists_missing_cache(
    tmp_path: Path,
    db_session: Session,
    image_service: ImageService,
    storage: Mock,
    cache_service: Mock,
    show_repository: Mock,
) -> None:
    """Download and persist a show poster when no local cache exists."""

    show_id = uuid4()
    relative_path = f"shows/{show_id}/poster.jpg"
    absolute_path = tmp_path / "poster.jpg"
    absolute_path.write_bytes(
        b"poster",
    )

    show = Mock(
        id=show_id,
        local_poster_path=None,
        tmdb_poster_path="/provider-poster.jpg",
    )

    show_repository.get_by_id.return_value = show
    cache_service.cache_show_poster.return_value = relative_path
    storage.from_relative_path.return_value = absolute_path

    result = image_service.resolve_show_poster(
        show_id,
    )

    assert result == absolute_path
    assert show.local_poster_path == relative_path

    cache_service.cache_show_poster.assert_called_once_with(
        show_id=show_id,
        tmdb_path="/provider-poster.jpg",
    )

    storage.from_relative_path.assert_called_once_with(
        relative_path,
    )


def test_resolve_show_poster_redownloads_when_database_path_is_missing(
    tmp_path: Path,
    image_service: ImageService,
    storage: Mock,
    cache_service: Mock,
    show_repository: Mock,
) -> None:
    """Redownload a show poster when the recorded local file is missing."""

    show_id = uuid4()

    missing_path = tmp_path / "missing.jpg"
    downloaded_path = tmp_path / "poster.jpg"
    downloaded_path.write_bytes(
        b"poster",
    )

    previous_relative_path = f"shows/{show_id}/old-poster.jpg"
    new_relative_path = f"shows/{show_id}/poster.jpg"

    show = Mock(
        id=show_id,
        local_poster_path=previous_relative_path,
        tmdb_poster_path="/provider-poster.jpg",
    )

    show_repository.get_by_id.return_value = show

    storage.from_relative_path.side_effect = [
        missing_path,
        downloaded_path,
    ]

    cache_service.cache_show_poster.return_value = new_relative_path

    result = image_service.resolve_show_poster(
        show_id,
    )

    assert result == downloaded_path
    assert show.local_poster_path == new_relative_path

    cache_service.cache_show_poster.assert_called_once_with(
        show_id=show_id,
        tmdb_path="/provider-poster.jpg",
    )


def test_resolve_show_poster_ignores_unsafe_local_path(
    tmp_path: Path,
    image_service: ImageService,
    storage: Mock,
    cache_service: Mock,
    show_repository: Mock,
) -> None:
    """Ignore an invalid stored path and rebuild the cache safely."""

    show_id = uuid4()
    relative_path = f"shows/{show_id}/poster.jpg"

    downloaded_path = tmp_path / "poster.jpg"
    downloaded_path.write_bytes(
        b"poster",
    )

    show = Mock(
        id=show_id,
        local_poster_path="../../outside.jpg",
        tmdb_poster_path="/provider-poster.jpg",
    )

    show_repository.get_by_id.return_value = show

    storage.from_relative_path.side_effect = [
        ValueError(
            "Image path is outside the configured storage directory."
        ),
        downloaded_path,
    ]

    cache_service.cache_show_poster.return_value = relative_path

    result = image_service.resolve_show_poster(
        show_id,
    )

    assert result == downloaded_path
    assert show.local_poster_path == relative_path


def test_resolve_show_poster_raises_when_show_does_not_exist(
    image_service: ImageService,
    show_repository: Mock,
    cache_service: Mock,
) -> None:
    """Reject image resolution for a missing show."""

    show_id = uuid4()

    show_repository.get_by_id.return_value = None

    with pytest.raises(
        ImageOwnerNotFoundError,
        match="TV series not found",
    ):
        image_service.resolve_show_poster(
            show_id,
        )

    cache_service.cache_show_poster.assert_not_called()


def test_resolve_show_poster_raises_when_image_is_unavailable(
    image_service: ImageService,
    show_repository: Mock,
    cache_service: Mock,
) -> None:
    """Reject image resolution when no local or provider image exists."""

    show_id = uuid4()

    show_repository.get_by_id.return_value = Mock(
        id=show_id,
        local_poster_path=None,
        tmdb_poster_path=None,
    )

    with pytest.raises(
        ImageNotAvailableError,
        match="requested image is not available",
    ):
        image_service.resolve_show_poster(
            show_id,
        )

    cache_service.cache_show_poster.assert_not_called()


def test_resolve_show_backdrop_downloads_image(
    tmp_path: Path,
    image_service: ImageService,
    storage: Mock,
    cache_service: Mock,
    show_repository: Mock,
) -> None:
    """Download a missing show backdrop."""

    show_id = uuid4()
    relative_path = f"shows/{show_id}/backdrop.webp"
    absolute_path = tmp_path / "backdrop.webp"
    absolute_path.write_bytes(
        b"backdrop",
    )

    show = Mock(
        id=show_id,
        local_backdrop_path=None,
        tmdb_backdrop_path="/backdrop.webp",
    )

    show_repository.get_by_id.return_value = show
    cache_service.cache_show_backdrop.return_value = relative_path
    storage.from_relative_path.return_value = absolute_path

    result = image_service.resolve_show_backdrop(
        show_id,
    )

    assert result == absolute_path
    assert show.local_backdrop_path == relative_path

    cache_service.cache_show_backdrop.assert_called_once_with(
        show_id=show_id,
        tmdb_path="/backdrop.webp",
    )


def test_resolve_season_poster_downloads_image(
    tmp_path: Path,
    image_service: ImageService,
    storage: Mock,
    cache_service: Mock,
    season_repository: Mock,
) -> None:
    """Download a missing season poster."""

    season_id = uuid4()
    relative_path = f"seasons/{season_id}/poster.jpg"
    absolute_path = tmp_path / "poster.jpg"
    absolute_path.write_bytes(
        b"poster",
    )

    season = Mock(
        id=season_id,
        local_poster_path=None,
        tmdb_poster_path="/season-poster.jpg",
    )

    season_repository.get_by_id.return_value = season
    cache_service.cache_season_poster.return_value = relative_path
    storage.from_relative_path.return_value = absolute_path

    result = image_service.resolve_season_poster(
        season_id,
    )

    assert result == absolute_path
    assert season.local_poster_path == relative_path

    cache_service.cache_season_poster.assert_called_once_with(
        season_id=season_id,
        tmdb_path="/season-poster.jpg",
    )


def test_resolve_season_poster_raises_when_season_does_not_exist(
    image_service: ImageService,
    season_repository: Mock,
) -> None:
    """Reject image resolution for a missing season."""

    season_id = uuid4()

    season_repository.get_by_id.return_value = None

    with pytest.raises(
        ImageOwnerNotFoundError,
        match="TV season not found",
    ):
        image_service.resolve_season_poster(
            season_id,
        )


def test_resolve_episode_still_downloads_image(
    tmp_path: Path,
    image_service: ImageService,
    storage: Mock,
    cache_service: Mock,
    episode_repository: Mock,
) -> None:
    """Download a missing episode still."""

    episode_id = uuid4()
    relative_path = f"episodes/{episode_id}/still.jpg"
    absolute_path = tmp_path / "still.jpg"
    absolute_path.write_bytes(
        b"still",
    )

    episode = Mock(
        id=episode_id,
        local_still_path=None,
        tmdb_still_path="/episode-still.jpg",
    )

    episode_repository.get_by_id.return_value = episode
    cache_service.cache_episode_still.return_value = relative_path
    storage.from_relative_path.return_value = absolute_path

    result = image_service.resolve_episode_still(
        episode_id,
    )

    assert result == absolute_path
    assert episode.local_still_path == relative_path

    cache_service.cache_episode_still.assert_called_once_with(
        episode_id=episode_id,
        tmdb_path="/episode-still.jpg",
    )


def test_resolve_episode_still_raises_when_episode_does_not_exist(
    image_service: ImageService,
    episode_repository: Mock,
) -> None:
    """Reject image resolution for a missing episode."""

    episode_id = uuid4()

    episode_repository.get_by_id.return_value = None

    with pytest.raises(
        ImageOwnerNotFoundError,
        match="TV episode not found",
    ):
        image_service.resolve_episode_still(
            episode_id,
        )