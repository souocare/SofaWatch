from datetime import date
from unittest.mock import Mock

import pytest
from app.schemas.tmdb_show import (
    ShowSearchResponse,
    ShowSearchResult,
)
from fastapi.testclient import TestClient

from app.api.dependencies import get_show_search_service
from app.main import app
from app.providers.tmdb.exceptions import (
    TMDBConfigurationError,
    TMDBRequestError,
    TMDBResponseError,
)
from app.services.tmdb_show_search import ShowSearchService

SEARCH_SHOWS_URL = "/search/shows"


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
        "detail": "The TMDB provider is not configured.",
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
        "detail": "The TMDB service is currently unavailable.",
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
        "detail": "TMDB returned an invalid response.",
    }
