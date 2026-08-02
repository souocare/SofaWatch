from pathlib import Path
from unittest.mock import Mock
from uuid import uuid4

import pytest
from fastapi.testclient import TestClient

from app.api.dependencies import get_image_service
from app.main import app
from app.services.image import (
    ImageNotAvailableError,
    ImageOwnerNotFoundError,
    ImageService,
)
from app.services.image_cache import ImageCacheError


@pytest.fixture
def image_service() -> Mock:
    """Provide a mocked image service."""

    return Mock(spec=ImageService)


@pytest.fixture
def client_with_image_service(
    client: TestClient,
    image_service: Mock,
) -> TestClient:
    """Provide a client using the mocked image service."""

    def override_get_image_service() -> Mock:
        return image_service

    app.dependency_overrides[get_image_service] = (
        override_get_image_service
    )

    return client


def test_get_show_poster_returns_image_file(
    tmp_path: Path,
    client_with_image_service: TestClient,
    image_service: Mock,
) -> None:
    """Return a show poster file."""

    show_id = uuid4()
    poster_path = tmp_path / "poster.jpg"

    poster_path.write_bytes(
        b"poster-image",
    )

    image_service.resolve_show_poster.return_value = poster_path

    response = client_with_image_service.get(
        f"/api/v1/images/shows/{show_id}/poster",
    )

    assert response.status_code == 200
    assert response.content == b"poster-image"
    assert response.headers["content-type"] == "image/jpeg"

    image_service.resolve_show_poster.assert_called_once_with(
        show_id,
    )


def test_get_show_backdrop_returns_image_file(
    tmp_path: Path,
    client_with_image_service: TestClient,
    image_service: Mock,
) -> None:
    """Return a show backdrop file."""

    show_id = uuid4()
    backdrop_path = tmp_path / "backdrop.webp"

    backdrop_path.write_bytes(
        b"backdrop-image",
    )

    image_service.resolve_show_backdrop.return_value = backdrop_path

    response = client_with_image_service.get(
        f"/api/v1/images/shows/{show_id}/backdrop",
    )

    assert response.status_code == 200
    assert response.content == b"backdrop-image"
    assert response.headers["content-type"] == "image/webp"


def test_get_season_poster_returns_image_file(
    tmp_path: Path,
    client_with_image_service: TestClient,
    image_service: Mock,
) -> None:
    """Return a season poster file."""

    season_id = uuid4()
    poster_path = tmp_path / "season.png"

    poster_path.write_bytes(
        b"season-poster",
    )

    image_service.resolve_season_poster.return_value = poster_path

    response = client_with_image_service.get(
        f"/api/v1/images/seasons/{season_id}/poster",
    )

    assert response.status_code == 200
    assert response.content == b"season-poster"
    assert response.headers["content-type"] == "image/png"


def test_get_episode_still_returns_image_file(
    tmp_path: Path,
    client_with_image_service: TestClient,
    image_service: Mock,
) -> None:
    """Return an episode still file."""

    episode_id = uuid4()
    still_path = tmp_path / "still.jpg"

    still_path.write_bytes(
        b"episode-still",
    )

    image_service.resolve_episode_still.return_value = still_path

    response = client_with_image_service.get(
        f"/api/v1/images/episodes/{episode_id}/still",
    )

    assert response.status_code == 200
    assert response.content == b"episode-still"
    assert response.headers["content-type"] == "image/jpeg"


@pytest.mark.parametrize(
    (
        "url",
        "method_name",
        "message",
        "code",
    ),
    [
        (
            "/api/v1/images/shows/{id}/poster",
            "resolve_show_poster",
            "TV series not found.",
            "show_not_found",
        ),
        (
            "/api/v1/images/shows/{id}/backdrop",
            "resolve_show_backdrop",
            "TV series not found.",
            "show_not_found",
        ),
        (
            "/api/v1/images/seasons/{id}/poster",
            "resolve_season_poster",
            "TV season not found.",
            "season_not_found",
        ),
        (
            "/api/v1/images/episodes/{id}/still",
            "resolve_episode_still",
            "TV episode not found.",
            "episode_not_found",
        ),
    ],
)
def test_image_endpoint_returns_owner_not_found_error(
    client_with_image_service: TestClient,
    image_service: Mock,
    url: str,
    method_name: str,
    message: str,
    code: str,
) -> None:
    """Return a semantic error when the image owner does not exist."""

    resource_id = uuid4()

    method = getattr(
        image_service,
        method_name,
    )

    method.side_effect = ImageOwnerNotFoundError(
        message,
    )

    response = client_with_image_service.get(
        url.format(
            id=resource_id,
        ),
    )

    assert response.status_code == 404
    assert response.json() == {
        "error": {
            "code": code,
            "message": message,
        }
    }


@pytest.mark.parametrize(
    (
        "url",
        "method_name",
    ),
    [
        (
            "/api/v1/images/shows/{id}/poster",
            "resolve_show_poster",
        ),
        (
            "/api/v1/images/shows/{id}/backdrop",
            "resolve_show_backdrop",
        ),
        (
            "/api/v1/images/seasons/{id}/poster",
            "resolve_season_poster",
        ),
        (
            "/api/v1/images/episodes/{id}/still",
            "resolve_episode_still",
        ),
    ],
)
def test_image_endpoint_returns_image_not_found_error(
    client_with_image_service: TestClient,
    image_service: Mock,
    url: str,
    method_name: str,
) -> None:
    """Return a semantic error when no image is available."""

    resource_id = uuid4()

    method = getattr(
        image_service,
        method_name,
    )

    method.side_effect = ImageNotAvailableError(
        "The requested image is not available."
    )

    response = client_with_image_service.get(
        url.format(
            id=resource_id,
        ),
    )

    assert response.status_code == 404
    assert response.json() == {
        "error": {
            "code": "image_not_found",
            "message": "The requested image is not available.",
        }
    }


def test_image_endpoint_returns_download_failure(
    client_with_image_service: TestClient,
    image_service: Mock,
) -> None:
    """Return HTTP 502 when the provider image cannot be cached."""

    show_id = uuid4()

    image_service.resolve_show_poster.side_effect = (
        ImageCacheError(
            "The provider image could not be downloaded."
        )
    )

    response = client_with_image_service.get(
        f"/api/v1/images/shows/{show_id}/poster",
    )

    assert response.status_code == 502
    assert response.json() == {
        "error": {
            "code": "image_download_failed",
            "message": "The requested image could not be retrieved.",
        }
    }


def test_image_endpoint_rejects_invalid_uuid(
    client_with_image_service: TestClient,
    image_service: Mock,
) -> None:
    """Reject an invalid resource identifier."""

    response = client_with_image_service.get(
        "/api/v1/images/shows/not-a-uuid/poster",
    )

    assert response.status_code == 422

    response_data = response.json()

    assert response_data["error"]["code"] == "validation_error"
    assert response_data["error"]["message"] == (
        "The request contains invalid data."
    )

    image_service.resolve_show_poster.assert_not_called()