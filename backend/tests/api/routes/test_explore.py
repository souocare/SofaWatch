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
from app.services.explore import ExploreService
from app.schemas.explore import (
    ExploreMediaCollection,
    ExploreMediaItem,
    ExploreMediaType,
    ExploreTrendingResponse,
    ExploreTrendingWindow,
    ExploreGenre,
    ExploreGenreOptions,
)
from types import SimpleNamespace
from uuid import uuid4

from app.api.dependencies import (
    get_current_user,
    get_explore_service,
)

TEST_USER_ID = uuid4()

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

    def override_get_current_user() -> SimpleNamespace:
        return SimpleNamespace(
            id=TEST_USER_ID,
        )

    app.dependency_overrides[
        get_explore_service
    ] = override_get_explore_service

    app.dependency_overrides[
        get_current_user
    ] = override_get_current_user

    yield client

    app.dependency_overrides.pop(
        get_explore_service,
        None,
    )

    app.dependency_overrides.pop(
        get_current_user,
        None,
    )


def test_get_trending_returns_ordered_mixed_media(
    client_with_explore_service: TestClient,
    explore_service: Mock,
) -> None:
    explore_service.get_trending.return_value = (
        ExploreTrendingResponse(
            items=[
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

    assert len(body["items"]) == 2

    assert body["items"][0]["media_type"] == "show"
    assert body["items"][0]["tmdb_id"] == 95396
    assert body["items"][0]["title"] == "Severance"

    assert body["items"][1]["media_type"] == "movie"
    assert body["items"][1]["tmdb_id"] == 438631
    assert body["items"][1]["title"] == "Dune"

    explore_service.get_trending.assert_called_once_with(
        user_id=TEST_USER_ID,
        window=ExploreTrendingWindow.WEEK,
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
        user_id=TEST_USER_ID,
        window=ExploreTrendingWindow.WEEK,
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


def test_get_trending_supports_day_window(
    client_with_explore_service: TestClient,
    explore_service: Mock,
) -> None:
    explore_service.get_trending.return_value = (
        ExploreTrendingResponse()
    )

    response = client_with_explore_service.get(
        "/api/v1/explore/trending",
        params={
            "window": "day",
        },
    )

    assert response.status_code == 200

    explore_service.get_trending.assert_called_once_with(
        user_id=TEST_USER_ID,
        window=ExploreTrendingWindow.DAY,
        language=None,
    )

def test_get_trending_defaults_to_week(
    client_with_explore_service: TestClient,
    explore_service: Mock,
) -> None:
    explore_service.get_trending.return_value = (
        ExploreTrendingResponse()
    )

    response = client_with_explore_service.get(
        "/api/v1/explore/trending",
    )

    assert response.status_code == 200

    explore_service.get_trending.assert_called_once_with(
        user_id=TEST_USER_ID,
        window=ExploreTrendingWindow.WEEK,
        language=None,
    )

def test_get_popular_shows_returns_items(
    client_with_explore_service: TestClient,
    explore_service: Mock,
) -> None:
    explore_service.get_popular_shows.return_value = (
        ExploreMediaCollection(
            items=[
                ExploreMediaItem(
                    media_type=ExploreMediaType.SHOW,
                    tmdb_id=95396,
                    title="Severance",
                    original_title="Severance",
                    overview="",
                    release_date=date(
                        2022,
                        2,
                        17,
                    ),
                    poster_url=None,
                    backdrop_url=None,
                    original_language="en",
                    genre_ids=[18],
                    popularity=120,
                    vote_average=8.4,
                    vote_count=2100,
                ),
            ],
        )
    )

    response = client_with_explore_service.get(
        "/api/v1/explore/popular/shows",
    )

    assert response.status_code == 200

    body = response.json()

    assert len(body["items"]) == 1
    assert body["items"][0]["media_type"] == "show"
    assert body["items"][0]["tmdb_id"] == 95396

    explore_service.get_popular_shows.assert_called_once_with(
        user_id=TEST_USER_ID,
        genre_id=None,
        language=None,
    )

def test_get_popular_shows_forwards_language(
    client_with_explore_service: TestClient,
    explore_service: Mock,
) -> None:
    explore_service.get_popular_shows.return_value = (
        ExploreMediaCollection()
    )

    response = client_with_explore_service.get(
        "/api/v1/explore/popular/shows",
        params={
            "language": "pt-PT",
        },
    )

    assert response.status_code == 200

    explore_service.get_popular_shows.assert_called_once_with(
        user_id=TEST_USER_ID,
        genre_id=None,
        language="pt-PT",
    )

def test_get_popular_movies_returns_items(
    client_with_explore_service: TestClient,
    explore_service: Mock,
) -> None:
    """Return popular Movies."""

    explore_service.get_popular_movies.return_value = (
        ExploreMediaCollection(
            items=[
                ExploreMediaItem(
                    media_type=ExploreMediaType.MOVIE,
                    tmdb_id=438631,
                    title="Dune",
                    original_title="Dune",
                    overview=(
                        "Paul Atreides travels "
                        "to Arrakis."
                    ),
                    release_date=date(
                        2021,
                        9,
                        15,
                    ),
                    poster_url=None,
                    backdrop_url=None,
                    original_language="en",
                    genre_ids=[878],
                    popularity=95.4,
                    vote_average=7.8,
                    vote_count=13000,
                ),
            ],
        )
    )

    response = client_with_explore_service.get(
        "/api/v1/explore/popular/movies",
    )

    assert response.status_code == 200

    body = response.json()

    assert len(body["items"]) == 1
    assert body["items"][0]["media_type"] == "movie"
    assert body["items"][0]["tmdb_id"] == 438631
    assert body["items"][0]["title"] == "Dune"

    explore_service.get_popular_movies.assert_called_once_with(
        user_id=TEST_USER_ID,
        genre_id=None,
        language=None,
    )

def test_get_popular_movies_forwards_language(
    client_with_explore_service: TestClient,
    explore_service: Mock,
) -> None:
    """Forward language to the Explore service."""

    explore_service.get_popular_movies.return_value = (
        ExploreMediaCollection(
            items=[],
        )
    )

    response = client_with_explore_service.get(
        "/api/v1/explore/popular/movies",
        params={
            "language": "pt-PT",
        },
    )

    assert response.status_code == 200

    explore_service.get_popular_movies.assert_called_once_with(
        user_id=TEST_USER_ID,
        genre_id=None,
        language="pt-PT",
    )

def test_get_explore_genres_returns_show_and_movie_options(
    client_with_explore_service: TestClient,
    explore_service: Mock,
) -> None:
    explore_service.get_genres.return_value = (
        ExploreGenreOptions(
            shows=[
                ExploreGenre(
                    id=18,
                    name="Drama",
                ),
                ExploreGenre(
                    id=35,
                    name="Comedy",
                ),
            ],
            movies=[
                ExploreGenre(
                    id=28,
                    name="Action",
                ),
                ExploreGenre(
                    id=878,
                    name="Science Fiction",
                ),
            ],
        )
    )

    response = (
        client_with_explore_service.get(
            "/api/v1/explore/genres",
        )
    )

    assert response.status_code == 200

    body = response.json()

    assert body == {
        "shows": [
            {
                "id": 18,
                "name": "Drama",
            },
            {
                "id": 35,
                "name": "Comedy",
            },
        ],
        "movies": [
            {
                "id": 28,
                "name": "Action",
            },
            {
                "id": 878,
                "name": "Science Fiction",
            },
        ],
    }


def test_get_explore_genres_forwards_language(
    client_with_explore_service: TestClient,
    explore_service: Mock,
) -> None:
    explore_service.get_genres.return_value = (
        ExploreGenreOptions()
    )

    response = (
        client_with_explore_service.get(
            "/api/v1/explore/genres",
            params={
                "language": "pt-PT",
            },
        )
    )

    assert response.status_code == 200

    explore_service.get_genres.assert_called_once_with(
        language="pt-PT",
    )

def test_get_popular_shows_forwards_genre_id(
    client_with_explore_service: TestClient,
    explore_service: Mock,
) -> None:
    explore_service.get_popular_shows.return_value = ExploreMediaCollection()

    response = client_with_explore_service.get(
        "/api/v1/explore/popular/shows",
        params={
            "genre_id": 18,
        },
    )

    assert response.status_code == 200

    explore_service.get_popular_shows.assert_called_once_with(
        user_id=TEST_USER_ID,
        genre_id=18,
        language=None,
    )


def test_get_popular_movies_forwards_genre_id(
    client_with_explore_service: TestClient,
    explore_service: Mock,
) -> None:
    explore_service.get_popular_movies.return_value = ExploreMediaCollection()

    response = client_with_explore_service.get(
        "/api/v1/explore/popular/movies",
        params={
            "genre_id": 878,
        },
    )

    assert response.status_code == 200

    explore_service.get_popular_movies.assert_called_once_with(
        user_id=TEST_USER_ID,
        genre_id=878,
        language=None,
    )