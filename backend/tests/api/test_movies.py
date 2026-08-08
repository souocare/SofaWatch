from datetime import UTC, datetime
from unittest.mock import Mock
from uuid import uuid4

import pytest
from fastapi.testclient import TestClient

from app.api.dependencies import get_movie_import_service
from app.main import app
from app.models.movie import Movie
from app.providers.tmdb.exceptions import (
    TMDBConfigurationError,
    TMDBNotFoundError,
    TMDBRequestError,
    TMDBResponseError,
)
from app.services.movie_import import MovieImportService


@pytest.fixture
def movie_import_service() -> Mock:
    """Provide a mocked Movie import service."""

    return Mock(
        spec=MovieImportService,
    )


@pytest.fixture(autouse=True)
def override_movie_import_service(
    movie_import_service: Mock,
) -> None:
    """Override the Movie import dependency for API tests."""

    app.dependency_overrides[
        get_movie_import_service
    ] = lambda: movie_import_service

    yield

    app.dependency_overrides.pop(
        get_movie_import_service,
        None,
    )


def make_movie() -> Movie:
    """Create a representative locally stored Movie."""

    now = datetime.now(UTC)

    movie = Movie(
        tmdb_id=438631,
        title="Dune",
        original_title="Dune",
        overview="Paul Atreides travels to Arrakis.",
        tagline="Beyond fear, destiny awaits.",
        original_language="en",
        runtime=155,
        status="Released",
        adult=False,
        video=False,
        popularity=120.5,
        vote_average=7.8,
        vote_count=13000,
        metadata_language="en-US",
        metadata_updated_at=now,
    )

    movie.id = uuid4()
    movie.created_at = now
    movie.updated_at = now

    return movie


def test_import_movie_returns_local_movie(
    client: TestClient,
    movie_import_service: Mock,
) -> None:
    """Import a Movie and return its local SofaWatch representation."""

    movie = make_movie()

    movie_import_service.import_movie.return_value = movie

    response = client.post(
        "/api/v1/movies/import/tmdb/438631",
    )

    assert response.status_code == 200

    payload = response.json()

    assert payload["id"] == str(movie.id)
    assert payload["tmdb_id"] == 438631
    assert payload["title"] == "Dune"
    assert payload["original_title"] == "Dune"
    assert payload["runtime"] == 155
    assert payload["status"] == "Released"
    assert payload["vote_average"] == 7.8

    movie_import_service.import_movie.assert_called_once_with(
        tmdb_id=438631,
        language=None,
        force_refresh=False,
    )


def test_import_movie_forwards_language(
    client: TestClient,
    movie_import_service: Mock,
) -> None:
    """Forward the requested metadata language to the import service."""

    movie_import_service.import_movie.return_value = make_movie()

    response = client.post(
        "/api/v1/movies/import/tmdb/438631",
        params={
            "language": "pt-PT",
        },
    )

    assert response.status_code == 200

    movie_import_service.import_movie.assert_called_once_with(
        tmdb_id=438631,
        language="pt-PT",
        force_refresh=False,
    )


def test_import_movie_forwards_force_refresh(
    client: TestClient,
    movie_import_service: Mock,
) -> None:
    """Forward force_refresh to the import service."""

    movie_import_service.import_movie.return_value = make_movie()

    response = client.post(
        "/api/v1/movies/import/tmdb/438631",
        params={
            "force_refresh": True,
        },
    )

    assert response.status_code == 200

    movie_import_service.import_movie.assert_called_once_with(
        tmdb_id=438631,
        language=None,
        force_refresh=True,
    )


def test_import_movie_maps_tmdb_not_found(
    client: TestClient,
    movie_import_service: Mock,
) -> None:
    """Map a missing TMDB Movie to the public API error contract."""

    movie_import_service.import_movie.side_effect = (
        TMDBNotFoundError("Movie not found.")
    )

    response = client.post(
        "/api/v1/movies/import/tmdb/438631",
    )

    assert response.status_code == 404

    assert response.json() == {
        "error": {
            "code": "tmdb_not_found",
            "message": "The requested movie was not found.",
        }
    }


def test_import_movie_maps_tmdb_configuration_error(
    client: TestClient,
    movie_import_service: Mock,
) -> None:
    """Hide TMDB configuration details from API consumers."""

    movie_import_service.import_movie.side_effect = (
        TMDBConfigurationError(
            "Secret TMDB configuration details."
        )
    )

    response = client.post(
        "/api/v1/movies/import/tmdb/438631",
    )

    assert response.status_code == 500

    assert response.json() == {
        "error": {
            "code": "tmdb_not_configured",
            "message": "The TMDB provider is not configured.",
        }
    }

    assert "Secret TMDB configuration details" not in response.text


def test_import_movie_maps_tmdb_request_error(
    client: TestClient,
    movie_import_service: Mock,
) -> None:
    """Map an unavailable TMDB provider to a safe API response."""

    movie_import_service.import_movie.side_effect = (
        TMDBRequestError(
            "Upstream timeout with technical information."
        )
    )

    response = client.post(
        "/api/v1/movies/import/tmdb/438631",
    )

    assert response.status_code == 503

    assert response.json() == {
        "error": {
            "code": "tmdb_unavailable",
            "message": "The TMDB service is currently unavailable.",
        }
    }

    assert "technical information" not in response.text


def test_import_movie_maps_invalid_tmdb_response(
    client: TestClient,
    movie_import_service: Mock,
) -> None:
    """Map an invalid provider response without exposing details."""

    movie_import_service.import_movie.side_effect = (
        TMDBResponseError(
            "Unexpected TMDB payload structure."
        )
    )

    response = client.post(
        "/api/v1/movies/import/tmdb/438631",
    )

    assert response.status_code == 502

    assert response.json() == {
        "error": {
            "code": "tmdb_invalid_response",
            "message": "TMDB returned an invalid response.",
        }
    }

    assert "Unexpected TMDB payload structure" not in response.text


def test_import_movie_rejects_invalid_tmdb_id(
    client: TestClient,
    movie_import_service: Mock,
) -> None:
    """Reject invalid TMDB identifiers before calling the service."""

    response = client.post(
        "/api/v1/movies/import/tmdb/0",
    )

    assert response.status_code == 422

    payload = response.json()

    assert payload["error"]["code"] == "validation_error"

    movie_import_service.import_movie.assert_not_called()


def test_import_movie_rejects_invalid_language(
    client: TestClient,
    movie_import_service: Mock,
) -> None:
    """Reject invalid language query parameters."""

    response = client.post(
        "/api/v1/movies/import/tmdb/438631",
        params={
            "language": "x",
        },
    )

    assert response.status_code == 422

    assert response.json()["error"]["code"] == "validation_error"

    movie_import_service.import_movie.assert_not_called()