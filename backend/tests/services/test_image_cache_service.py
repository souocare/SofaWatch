from collections.abc import Callable
from pathlib import Path
from types import SimpleNamespace
from uuid import uuid4

import httpx
import pytest

from app.core.storage import ImageStorage
from app.services.image_cache import (
    ImageCacheError,
    ImageCacheService,
)

IMAGE_BYTES = b"test-image-content"


def create_service(
    tmp_path: Path,
    handler: Callable[
        [httpx.Request],
        httpx.Response,
    ],
) -> tuple[
    ImageCacheService,
    ImageStorage,
    httpx.Client,
]:
    """Create an image cache service using mocked HTTP requests."""

    settings = SimpleNamespace(
        image_storage_path=str(
            tmp_path / "images",
        ),
        tmdb_image_base_url=("https://image.tmdb.org/t/p"),
        tmdb_timeout_seconds=10.0,
    )

    storage = ImageStorage(
        settings=settings,
    )

    http_client = httpx.Client(
        transport=httpx.MockTransport(
            handler,
        ),
    )

    service = ImageCacheService(
        settings=settings,
        storage=storage,
        http_client=http_client,
    )

    return (
        service,
        storage,
        http_client,
    )


def test_cache_show_poster_downloads_and_stores_image(
    tmp_path: Path,
) -> None:
    """Download and store a show poster in the local cache."""

    show_id = uuid4()

    def handler(
        request: httpx.Request,
    ) -> httpx.Response:
        assert request.url == ("https://image.tmdb.org/t/p/w500/poster.jpg")

        return httpx.Response(
            status_code=200,
            headers={
                "content-type": "image/jpeg",
            },
            content=IMAGE_BYTES,
            request=request,
        )

    service, storage, http_client = create_service(
        tmp_path,
        handler,
    )

    try:
        relative_path = service.cache_show_poster(
            show_id=show_id,
            tmdb_path="/poster.jpg",
        )
    finally:
        http_client.close()

    assert relative_path == (f"shows/{show_id}/poster.jpg")

    absolute_path = storage.from_relative_path(
        relative_path,
    )

    assert absolute_path.is_file()
    assert absolute_path.read_bytes() == IMAGE_BYTES


def test_cache_show_backdrop_uses_original_size(
    tmp_path: Path,
) -> None:
    """Request the original TMDB image size for show backdrops."""

    show_id = uuid4()

    def handler(
        request: httpx.Request,
    ) -> httpx.Response:
        assert request.url == ("https://image.tmdb.org/t/p/original/backdrop.webp")

        return httpx.Response(
            status_code=200,
            headers={
                "content-type": "image/webp",
            },
            content=IMAGE_BYTES,
            request=request,
        )

    service, storage, http_client = create_service(
        tmp_path,
        handler,
    )

    try:
        relative_path = service.cache_show_backdrop(
            show_id=show_id,
            tmdb_path="/backdrop.webp",
        )
    finally:
        http_client.close()

    assert relative_path == (f"shows/{show_id}/backdrop.webp")

    assert (
        storage.from_relative_path(
            relative_path,
        ).read_bytes()
        == IMAGE_BYTES
    )


def test_cache_season_poster_stores_png_image(
    tmp_path: Path,
) -> None:
    """Use the response content type to select the file extension."""

    season_id = uuid4()

    def handler(
        request: httpx.Request,
    ) -> httpx.Response:
        return httpx.Response(
            status_code=200,
            headers={
                "content-type": "image/png",
            },
            content=IMAGE_BYTES,
            request=request,
        )

    service, storage, http_client = create_service(
        tmp_path,
        handler,
    )

    try:
        relative_path = service.cache_season_poster(
            season_id=season_id,
            tmdb_path="/season-image",
        )
    finally:
        http_client.close()

    assert relative_path == (f"seasons/{season_id}/poster.png")

    assert storage.from_relative_path(
        relative_path,
    ).is_file()


def test_cache_episode_still_uses_w500_size(
    tmp_path: Path,
) -> None:
    """Request the configured internal size for episode stills."""

    episode_id = uuid4()

    def handler(
        request: httpx.Request,
    ) -> httpx.Response:
        assert request.url == ("https://image.tmdb.org/t/p/w500/still.jpg")

        return httpx.Response(
            status_code=200,
            headers={
                "content-type": "image/jpeg",
            },
            content=IMAGE_BYTES,
            request=request,
        )

    service, storage, http_client = create_service(
        tmp_path,
        handler,
    )

    try:
        relative_path = service.cache_episode_still(
            episode_id=episode_id,
            tmdb_path="still.jpg",
        )
    finally:
        http_client.close()

    assert relative_path == (f"episodes/{episode_id}/still.jpg")

    assert storage.from_relative_path(
        relative_path,
    ).exists()


@pytest.mark.parametrize(
    (
        "content_type",
        "expected_extension",
    ),
    [
        (
            "image/jpeg",
            "jpg",
        ),
        (
            "image/jpeg; charset=binary",
            "jpg",
        ),
        (
            "image/png",
            "png",
        ),
        (
            "image/webp",
            "webp",
        ),
    ],
)
def test_cache_image_supports_known_content_types(
    tmp_path: Path,
    content_type: str,
    expected_extension: str,
) -> None:
    """Support the expected provider image content types."""

    show_id = uuid4()

    def handler(
        request: httpx.Request,
    ) -> httpx.Response:
        return httpx.Response(
            status_code=200,
            headers={
                "content-type": content_type,
            },
            content=IMAGE_BYTES,
            request=request,
        )

    service, _, http_client = create_service(
        tmp_path,
        handler,
    )

    try:
        relative_path = service.cache_show_poster(
            show_id=show_id,
            tmdb_path="/poster",
        )
    finally:
        http_client.close()

    assert relative_path.endswith(
        f".{expected_extension}",
    )


def test_cache_image_rejects_unsupported_content_type(
    tmp_path: Path,
) -> None:
    """Reject provider responses that are not supported images."""

    show_id = uuid4()

    def handler(
        request: httpx.Request,
    ) -> httpx.Response:
        return httpx.Response(
            status_code=200,
            headers={
                "content-type": "text/html",
            },
            content=b"<html>Not an image</html>",
            request=request,
        )

    service, _, http_client = create_service(
        tmp_path,
        handler,
    )

    try:
        with pytest.raises(
            ImageCacheError,
            match="Unsupported image content type",
        ):
            service.cache_show_poster(
                show_id=show_id,
                tmdb_path="/poster.jpg",
            )
    finally:
        http_client.close()


def test_cache_image_raises_when_provider_returns_error(
    tmp_path: Path,
) -> None:
    """Convert provider HTTP failures into an image cache error."""

    show_id = uuid4()

    def handler(
        request: httpx.Request,
    ) -> httpx.Response:
        return httpx.Response(
            status_code=404,
            request=request,
        )

    service, _, http_client = create_service(
        tmp_path,
        handler,
    )

    try:
        with pytest.raises(
            ImageCacheError,
            match=("provider image could not be downloaded"),
        ):
            service.cache_show_poster(
                show_id=show_id,
                tmdb_path="/missing.jpg",
            )
    finally:
        http_client.close()


def test_failed_download_does_not_leave_cached_file(
    tmp_path: Path,
) -> None:
    """Do not leave cache files after an HTTP failure."""

    show_id = uuid4()

    def handler(
        request: httpx.Request,
    ) -> httpx.Response:
        return httpx.Response(
            status_code=500,
            request=request,
        )

    service, storage, http_client = create_service(
        tmp_path,
        handler,
    )

    try:
        with pytest.raises(
            ImageCacheError,
        ):
            service.cache_show_poster(
                show_id=show_id,
                tmdb_path="/poster.jpg",
            )
    finally:
        http_client.close()

    show_directory = storage.base_path / "shows" / str(show_id)

    assert not show_directory.exists()


def test_service_does_not_close_injected_http_client(
    tmp_path: Path,
) -> None:
    """Leave externally owned HTTP clients open."""

    def handler(
        request: httpx.Request,
    ) -> httpx.Response:
        return httpx.Response(
            status_code=200,
            request=request,
        )

    service, _, http_client = create_service(
        tmp_path,
        handler,
    )

    service.close()

    assert http_client.is_closed is False

    http_client.close()


def test_cache_movie_poster_downloads_and_stores_image(
    tmp_path: Path,
) -> None:
    """Download and store a movie poster in the local cache."""

    movie_id = uuid4()

    def handler(
        request: httpx.Request,
    ) -> httpx.Response:
        assert request.url == ("https://image.tmdb.org/t/p/w500/movie-poster.jpg")

        return httpx.Response(
            status_code=200,
            headers={
                "content-type": "image/jpeg",
            },
            content=IMAGE_BYTES,
            request=request,
        )

    service, storage, http_client = create_service(
        tmp_path,
        handler,
    )

    try:
        relative_path = service.cache_movie_poster(
            movie_id=movie_id,
            tmdb_path="/movie-poster.jpg",
        )
    finally:
        http_client.close()

    assert relative_path == (f"movies/{movie_id}/poster.jpg")

    absolute_path = storage.from_relative_path(
        relative_path,
    )

    assert absolute_path.is_file()
    assert absolute_path.read_bytes() == IMAGE_BYTES


def test_cache_movie_backdrop_uses_original_size(
    tmp_path: Path,
) -> None:
    """Request the original TMDB image size for movie backdrops."""

    movie_id = uuid4()

    def handler(
        request: httpx.Request,
    ) -> httpx.Response:
        assert request.url == ("https://image.tmdb.org/t/p/original/movie-backdrop.webp")

        return httpx.Response(
            status_code=200,
            headers={
                "content-type": "image/webp",
            },
            content=IMAGE_BYTES,
            request=request,
        )

    service, storage, http_client = create_service(
        tmp_path,
        handler,
    )

    try:
        relative_path = service.cache_movie_backdrop(
            movie_id=movie_id,
            tmdb_path="/movie-backdrop.webp",
        )
    finally:
        http_client.close()

    assert relative_path == (f"movies/{movie_id}/backdrop.webp")

    assert (
        storage.from_relative_path(
            relative_path,
        ).read_bytes()
        == IMAGE_BYTES
    )
