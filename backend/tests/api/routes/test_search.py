from datetime import date
from unittest.mock import Mock
from uuid import uuid4

import pytest
from fastapi.testclient import TestClient

from app.api.dependencies import (
    get_current_user,
    get_media_search_service,
    get_show_search_service,
)
from app.models.user import User
from app.main import app
from app.providers.tmdb.exceptions import (
    TMDBConfigurationError,
    TMDBRequestError,
    TMDBResponseError,
)
from app.schemas.tmdb_show import (
    ShowSearchResponse,
    ShowSearchResult,
)
from app.services.tmdb_show_search import ShowSearchService
from app.schemas.search import (
    SearchMediaType,
    SearchMediaTypeFilter,
    SearchResponse,
    SearchResult,
)
from app.services.media_search import MediaSearchService

SEARCH_SHOWS_URL = "/api/v1/search/shows"
SEARCH_URL = "/api/v1/search"


@pytest.fixture
def show_search_service() -> Mock:
    """Provide a mocked show search service."""

    return Mock(spec=ShowSearchService)


@pytest.fixture
def client_with_show_search_service(
    client: TestClient,
    show_search_service: Mock,
) -> TestClient:
    """Provide a test client using the mocked show search service."""

    def override_get_show_search_service() -> Mock:
        return show_search_service

    app.dependency_overrides[get_show_search_service] = override_get_show_search_service

    return client


@pytest.fixture
def current_user() -> User:
    """Provide the current SofaWatch user for Search route tests."""

    return User(
        id=uuid4(),
        display_name="Local User",
        is_local=True,
    )


def test_search_shows_returns_results(
    client_with_show_search_service: TestClient,
    show_search_service: Mock,
) -> None:
    show_search_service.search.return_value = ShowSearchResponse(
        page=1,
        results=[
            ShowSearchResult(
                tmdb_id=95396,
                title="Severance",
                original_title="Severance",
                overview="Employees undergo a severance procedure.",
                first_air_date=date(2022, 2, 17),
                poster_url=("https://image.tmdb.org/t/p/w500/poster.jpg"),
                backdrop_url=("https://image.tmdb.org/t/p/original/backdrop.jpg"),
                original_language="en",
                genre_ids=[18, 9648],
                popularity=120.5,
                vote_average=8.4,
                vote_count=2100,
            )
        ],
        total_pages=2,
        total_results=25,
    )

    response = client_with_show_search_service.get(
        SEARCH_SHOWS_URL,
        params={
            "query": "Severance",
        },
    )

    assert response.status_code == 200
    assert response.json() == {
        "page": 1,
        "results": [
            {
                "tmdb_id": 95396,
                "title": "Severance",
                "original_title": "Severance",
                "overview": "Employees undergo a severance procedure.",
                "first_air_date": "2022-02-17",
                "poster_url": ("https://image.tmdb.org/t/p/w500/poster.jpg"),
                "backdrop_url": ("https://image.tmdb.org/t/p/original/backdrop.jpg"),
                "original_language": "en",
                "genre_ids": [18, 9648],
                "popularity": 120.5,
                "vote_average": 8.4,
                "vote_count": 2100,
            }
        ],
        "total_pages": 2,
        "total_results": 25,
    }

    show_search_service.search.assert_called_once_with(
        query="Severance",
        page=1,
        language=None,
    )


def test_search_shows_forwards_optional_parameters(
    client_with_show_search_service: TestClient,
    show_search_service: Mock,
) -> None:
    show_search_service.search.return_value = ShowSearchResponse(
        page=3,
        results=[],
        total_pages=3,
        total_results=50,
    )

    response = client_with_show_search_service.get(
        SEARCH_SHOWS_URL,
        params={
            "query": "The Office",
            "page": 3,
            "language": "pt-PT",
        },
    )

    assert response.status_code == 200
    assert response.json() == {
        "page": 3,
        "results": [],
        "total_pages": 3,
        "total_results": 50,
    }

    show_search_service.search.assert_called_once_with(
        query="The Office",
        page=3,
        language="pt-PT",
    )


def test_search_shows_requires_query(
    client_with_show_search_service: TestClient,
    show_search_service: Mock,
) -> None:
    response = client_with_show_search_service.get(
        SEARCH_SHOWS_URL,
    )

    assert response.status_code == 422
    show_search_service.search.assert_not_called()


def test_search_shows_rejects_empty_query(
    client_with_show_search_service: TestClient,
    show_search_service: Mock,
) -> None:
    response = client_with_show_search_service.get(
        SEARCH_SHOWS_URL,
        params={
            "query": "",
        },
    )

    assert response.status_code == 422
    show_search_service.search.assert_not_called()


def test_search_shows_rejects_query_longer_than_200_characters(
    client_with_show_search_service: TestClient,
    show_search_service: Mock,
) -> None:
    response = client_with_show_search_service.get(
        SEARCH_SHOWS_URL,
        params={
            "query": "a" * 201,
        },
    )

    assert response.status_code == 422
    show_search_service.search.assert_not_called()


@pytest.mark.parametrize(
    "page",
    [
        0,
        -1,
    ],
)
def test_search_shows_rejects_invalid_page(
    client_with_show_search_service: TestClient,
    show_search_service: Mock,
    page: int,
) -> None:
    response = client_with_show_search_service.get(
        SEARCH_SHOWS_URL,
        params={
            "query": "Severance",
            "page": page,
        },
    )

    assert response.status_code == 422
    show_search_service.search.assert_not_called()


def test_search_shows_rejects_language_shorter_than_two_characters(
    client_with_show_search_service: TestClient,
    show_search_service: Mock,
) -> None:
    response = client_with_show_search_service.get(
        SEARCH_SHOWS_URL,
        params={
            "query": "Severance",
            "language": "e",
        },
    )

    assert response.status_code == 422
    show_search_service.search.assert_not_called()


def test_search_shows_rejects_language_longer_than_ten_characters(
    client_with_show_search_service: TestClient,
    show_search_service: Mock,
) -> None:
    response = client_with_show_search_service.get(
        SEARCH_SHOWS_URL,
        params={
            "query": "Severance",
            "language": "a" * 11,
        },
    )

    assert response.status_code == 422
    show_search_service.search.assert_not_called()


def test_search_shows_converts_configuration_error(
    client_with_show_search_service: TestClient,
    show_search_service: Mock,
) -> None:
    show_search_service.search.side_effect = TMDBConfigurationError(
        "TMDB API token is not configured."
    )

    response = client_with_show_search_service.get(
        SEARCH_SHOWS_URL,
        params={
            "query": "Severance",
        },
    )

    assert response.status_code == 500
    assert response.json() == {
        "error": {
            "code": "tmdb_not_configured",
            "message": "The TMDB provider is not configured.",
        }
    }


def test_search_shows_converts_request_error(
    client_with_show_search_service: TestClient,
    show_search_service: Mock,
) -> None:
    show_search_service.search.side_effect = TMDBRequestError("TMDB could not be reached.")

    response = client_with_show_search_service.get(
        SEARCH_SHOWS_URL,
        params={
            "query": "Severance",
        },
    )

    assert response.status_code == 503
    assert response.json() == {
        "error": {
            "code": "tmdb_unavailable",
            "message": "The TMDB service is currently unavailable.",
        }
    }


def test_search_shows_converts_response_error(
    client_with_show_search_service: TestClient,
    show_search_service: Mock,
) -> None:
    show_search_service.search.side_effect = TMDBResponseError("TMDB returned an invalid response.")

    response = client_with_show_search_service.get(
        SEARCH_SHOWS_URL,
        params={
            "query": "Severance",
        },
    )

    assert response.status_code == 502
    assert response.json() == {
        "error": {
            "code": "tmdb_invalid_response",
            "message": "TMDB returned an invalid response.",
        }
    }


@pytest.fixture
def media_search_service() -> Mock:
    """Provide a mocked general media search service."""

    return Mock(spec=MediaSearchService)


@pytest.fixture
def client_with_media_search_service(
    client: TestClient,
    media_search_service: Mock,
    current_user: User,
) -> TestClient:
    """Provide a test client using the mocked media search service."""

    def override_get_media_search_service() -> Mock:
        return media_search_service

    def override_get_current_user() -> User:
        return current_user

    app.dependency_overrides[get_media_search_service] = override_get_media_search_service

    app.dependency_overrides[get_current_user] = override_get_current_user

    return client


def test_search_media_returns_mixed_results(
    client_with_media_search_service: TestClient,
    media_search_service: Mock,
    current_user: User,
) -> None:
    media_search_service.search.return_value = SearchResponse(
        page=1,
        results=[
            SearchResult(
                media_type=SearchMediaType.SHOW,
                tmdb_id=95396,
                title="Severance",
                original_title="Severance",
                overview="Employees undergo a severance procedure.",
                release_date=date(2022, 2, 17),
                poster_url=("https://image.tmdb.org/t/p/w500/severance.jpg"),
                backdrop_url=("https://image.tmdb.org/t/p/original/severance-backdrop.jpg"),
                original_language="en",
                genre_ids=[18, 9648],
                popularity=120.5,
                vote_average=8.4,
                vote_count=2100,
                in_library=False,
            ),
            SearchResult(
                media_type=SearchMediaType.MOVIE,
                tmdb_id=438631,
                title="Dune",
                original_title="Dune",
                overview="Paul Atreides travels to Arrakis.",
                release_date=date(2021, 9, 15),
                poster_url="https://image.tmdb.org/t/p/w500/dune.jpg",
                backdrop_url=("https://image.tmdb.org/t/p/original/dune-backdrop.jpg"),
                original_language="en",
                genre_ids=[878, 12],
                popularity=95.4,
                vote_average=7.8,
                vote_count=13000,
                in_library=False,
            ),
        ],
        total_pages=2,
        total_results=25,
    )

    response = client_with_media_search_service.get(
        SEARCH_URL,
        params={
            "query": "Dune",
        },
    )

    assert response.status_code == 200

    body = response.json()

    assert body["page"] == 1
    assert body["total_pages"] == 2
    assert body["total_results"] == 25
    assert len(body["results"]) == 2
    assert body["results"][0]["in_library"] is False
    assert body["results"][1]["in_library"] is False

    assert body["results"][0]["media_type"] == "show"
    assert body["results"][0]["poster_url"] == ("https://image.tmdb.org/t/p/w500/severance.jpg")

    assert body["results"][1]["media_type"] == "movie"
    assert body["results"][1]["poster_url"] == ("https://image.tmdb.org/t/p/w500/dune.jpg")

    media_search_service.search.assert_called_once_with(
        user_id=current_user.id,
        query="Dune",
        page=1,
        language=None,
        media_type=SearchMediaTypeFilter.ALL,
    )


def test_search_media_forwards_optional_parameters(
    client_with_media_search_service: TestClient,
    media_search_service: Mock,
    current_user: User,
) -> None:
    media_search_service.search.return_value = SearchResponse(
        page=3,
        results=[],
        total_pages=3,
        total_results=50,
    )

    response = client_with_media_search_service.get(
        SEARCH_URL,
        params={
            "query": "The Office",
            "page": 3,
            "language": "pt-PT",
            "media_type": "show",
        },
    )

    assert response.status_code == 200

    media_search_service.search.assert_called_once_with(
        user_id=current_user.id,
        query="The Office",
        page=3,
        language="pt-PT",
        media_type=SearchMediaTypeFilter.SHOW,
    )


def test_search_media_rejects_an_invalid_media_type(
    client_with_media_search_service: TestClient,
    media_search_service: Mock,
) -> None:
    response = client_with_media_search_service.get(
        SEARCH_URL,
        params={
            "query": "Dune",
            "media_type": "person",
        },
    )

    assert response.status_code == 422
    media_search_service.search.assert_not_called()


def test_search_media_requires_query(
    client_with_media_search_service: TestClient,
    media_search_service: Mock,
) -> None:
    response = client_with_media_search_service.get(
        SEARCH_URL,
    )

    assert response.status_code == 422
    media_search_service.search.assert_not_called()


def test_search_media_rejects_empty_query(
    client_with_media_search_service: TestClient,
    media_search_service: Mock,
) -> None:
    response = client_with_media_search_service.get(
        SEARCH_URL,
        params={
            "query": "",
        },
    )

    assert response.status_code == 422
    media_search_service.search.assert_not_called()


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
def test_search_media_converts_tmdb_errors(
    client_with_media_search_service: TestClient,
    media_search_service: Mock,
    exception: Exception,
    expected_status: int,
    expected_code: str,
) -> None:
    media_search_service.search.side_effect = exception

    response = client_with_media_search_service.get(
        SEARCH_URL,
        params={
            "query": "Dune",
        },
    )

    assert response.status_code == expected_status
    assert response.json()["error"]["code"] == expected_code
