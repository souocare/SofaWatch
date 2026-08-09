from datetime import date
from unittest.mock import Mock

import pytest
from fastapi.testclient import TestClient

from app.api.dependencies import get_explore_service
from app.main import app
from app.providers.tmdb.exceptions import (
    TMDBConfigurationError,
    TMDBRequestError,
    TMDBResponseError,
)
from app.schemas.explore import (
    ExploreMediaItem,
    ExploreMediaType,
    ExploreTrendingResponse,
)
from app.services.explore import ExploreService


EXPLORE_TRENDING_URL = "/api/v1/explore/trending"


@pytest.fixture
def explore_service() -> Mock:
    return Mock(spec=ExploreService)


@pytest.fixture
def client_with_explore_service(
    client: TestClient,
    explore_service: Mock,
) -> TestClient:
    def override_get_explore_service() -> Mock:
        return explore_service

    app.dependency_overrides[
        get_explore_service
    ] = override_get_explore_service

    return client


def test_get_trending_returns_shows_and_movies(
    client_with_explore_service: TestClient,
    explore_service: Mock,
) -> None:
    explore_service.get_trending.return_value = (
        ExploreTrendingResponse(
            shows=[
                ExploreMediaItem(
                    media_type=ExploreMediaType.SHOW,
                    tmdb_id=95396,
                    title="Severance",
                    original_title="Severance",
                    overview="Employees undergo a severance procedure.",
                    release_date=date(2022, 2, 17),
                    poster_url=(
                        "https://image.tmdb.org/t/p/w500/severance.jpg"
                    ),
                    backdrop_url=None,
                    original_language="en",
                    genre_ids=[18, 9648],
                    popularity=120.5,
                    vote_average=8.4,
                    vote_count=2100,
                ),
            ],
            movies=[
                ExploreMediaItem(
                    media_type=ExploreMediaType.MOVIE,
                    tmdb_id=438631,
                    title="Dune",
                    original_title="Dune",
                    overview="Paul Atreides travels to Arrakis.",
                    release_date=date(2021, 9, 15),
                    poster_url=(
                        "https://image.tmdb.org/t/p/w500/dune.jpg"
                    ),
                    backdrop_url=None,
                    original_language="en",
                    genre_ids=[878, 12],
                    popularity=95.4,
                    vote_average=7.8,
                    vote_count=13000,
                ),
            ],
        )
    )

    response = client_with_explore_service.get(
        EXPLORE_TRENDING_URL,
    )

    assert response.status_code == 200

    body = response.json()

    assert len(body["shows"]) == 1
    assert len(body["movies"]) == 1

    assert body["shows"][0]["media_type"] == "show"
    assert body["shows"][0]["tmdb_id"] == 95396

    assert body["movies"][0]["media_type"] == "movie"
    assert body["movies"][0]["tmdb_id"] == 438631

    explore_service.get_trending.assert_called_once_with(
        language=None,
    )


def test_get_trending_forwards_language(
    client_with_explore_service: TestClient,
    explore_service: Mock,
) -> None:
    explore_service.get_trending.return_value = (
        ExploreTrendingResponse()
    )

    response = client_with_explore_service.get(
        EXPLORE_TRENDING_URL,
        params={
            "language": "pt-PT",
        },
    )

    assert response.status_code == 200

    explore_service.get_trending.assert_called_once_with(
        language="pt-PT",
    )


@pytest.mark.parametrize(
    ("exception", "expected_status", "expected_code"),
    [
        (
            TMDBConfigurationError(
                "TMDB API token is not configured.",
            ),
            500,
            "tmdb_not_configured",
        ),
        (
            TMDBRequestError(
                "TMDB could not be reached.",
            ),
            503,
            "tmdb_unavailable",
        ),
        (
            TMDBResponseError(
                "TMDB returned an invalid response.",
            ),
            502,
            "tmdb_invalid_response",
        ),
    ],
)
def test_get_trending_converts_tmdb_errors(
    client_with_explore_service: TestClient,
    explore_service: Mock,
    exception: Exception,
    expected_status: int,
    expected_code: str,
) -> None:
    explore_service.get_trending.side_effect = exception

    response = client_with_explore_service.get(
        EXPLORE_TRENDING_URL,
    )

    assert response.status_code == expected_status
    assert response.json()["error"]["code"] == expected_code


@pytest.mark.parametrize(
    "language",
    [
        "e",
        "a" * 11,
    ],
)
def test_get_trending_rejects_invalid_language(
    client_with_explore_service: TestClient,
    explore_service: Mock,
    language: str,
) -> None:
    response = client_with_explore_service.get(
        EXPLORE_TRENDING_URL,
        params={
            "language": language,
        },
    )

    assert response.status_code == 422

    explore_service.get_trending.assert_not_called()