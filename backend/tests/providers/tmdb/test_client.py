from collections.abc import Callable

import httpx
import pytest

from app.core.config import Settings
from app.providers.tmdb.client import TMDBClient
from app.providers.tmdb.exceptions import (
    TMDBConfigurationError,
    TMDBNotFoundError,
    TMDBRequestError,
    TMDBResponseError,
)


def create_tmdb_client(
    settings: Settings,
    handler: Callable[[httpx.Request], httpx.Response],
) -> tuple[TMDBClient, httpx.Client]:
    """Create a TMDB client backed by an HTTPX mock transport."""

    transport = httpx.MockTransport(handler)

    http_client = httpx.Client(
        base_url=settings.tmdb_base_url,
        transport=transport,
    )

    tmdb_client = TMDBClient(
        settings=settings,
        http_client=http_client,
    )

    return tmdb_client, http_client


def test_search_tv_shows_returns_validated_response(
    settings: Settings,
) -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        assert request.method == "GET"
        assert request.url.path.endswith("/search/tv")

        assert request.url.params["query"] == "Severance"
        assert request.url.params["page"] == "1"
        assert request.url.params["language"] == "en-US"
        assert request.url.params["include_adult"] == "false"

        return httpx.Response(
            status_code=200,
            request=request,
            json={
                "page": 1,
                "results": [
                    {
                        "id": 95396,
                        "name": "Severance",
                        "original_name": "Severance",
                        "overview": "Employees undergo a severance procedure.",
                        "first_air_date": "2022-02-17",
                        "poster_path": "/poster.jpg",
                        "backdrop_path": "/backdrop.jpg",
                        "original_language": "en",
                        "genre_ids": [18, 9648],
                        "popularity": 120.5,
                        "vote_average": 8.4,
                        "vote_count": 2100,
                    }
                ],
                "total_pages": 2,
                "total_results": 25,
            },
        )

    tmdb_client, http_client = create_tmdb_client(settings, handler)

    try:
        response = tmdb_client.search_tv_shows(
            query="Severance",
        )
    finally:
        http_client.close()

    assert response.page == 1
    assert response.total_pages == 2
    assert response.total_results == 25
    assert len(response.results) == 1

    show = response.results[0]

    assert show.id == 95396
    assert show.name == "Severance"
    assert show.original_name == "Severance"
    assert show.first_air_date is not None
    assert show.first_air_date.isoformat() == "2022-02-17"
    assert show.genre_ids == [18, 9648]


def test_search_tv_shows_strips_query_and_uses_custom_parameters(
    settings: Settings,
) -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        assert request.url.params["query"] == "The Office"
        assert request.url.params["page"] == "3"
        assert request.url.params["language"] == "pt-PT"

        return httpx.Response(
            status_code=200,
            request=request,
            json={
                "page": 3,
                "results": [],
                "total_pages": 3,
                "total_results": 50,
            },
        )

    tmdb_client, http_client = create_tmdb_client(settings, handler)

    try:
        response = tmdb_client.search_tv_shows(
            query="  The Office  ",
            page=3,
            language="pt-PT",
        )
    finally:
        http_client.close()

    assert response.page == 3
    assert response.results == []


def test_search_tv_shows_rejects_empty_query(
    settings: Settings,
) -> None:
    tmdb_client, http_client = create_tmdb_client(
        settings,
        lambda request: httpx.Response(200, request=request),
    )

    try:
        with pytest.raises(
            ValueError,
            match="search query cannot be empty",
        ):
            tmdb_client.search_tv_shows(query="   ")
    finally:
        http_client.close()


def test_search_tv_shows_rejects_invalid_page(
    settings: Settings,
) -> None:
    tmdb_client, http_client = create_tmdb_client(
        settings,
        lambda request: httpx.Response(200, request=request),
    )

    try:
        with pytest.raises(
            ValueError,
            match="page must be greater than or equal to 1",
        ):
            tmdb_client.search_tv_shows(
                query="Severance",
                page=0,
            )
    finally:
        http_client.close()


def test_search_tv_shows_converts_timeout_error(
    settings: Settings,
) -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        raise httpx.ReadTimeout(
            "The request timed out.",
            request=request,
        )

    tmdb_client, http_client = create_tmdb_client(settings, handler)

    try:
        with pytest.raises(
            TMDBRequestError,
            match="timed out",
        ):
            tmdb_client.search_tv_shows(query="Severance")
    finally:
        http_client.close()


def test_search_tv_shows_converts_connection_error(
    settings: Settings,
) -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        raise httpx.ConnectError(
            "Unable to connect.",
            request=request,
        )

    tmdb_client, http_client = create_tmdb_client(settings, handler)

    try:
        with pytest.raises(
            TMDBRequestError,
            match="could not be reached",
        ):
            tmdb_client.search_tv_shows(query="Severance")
    finally:
        http_client.close()


def test_search_tv_shows_converts_not_found_response(
    settings: Settings,
) -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        return httpx.Response(
            status_code=404,
            request=request,
            json={
                "status_message": "The resource was not found.",
            },
        )

    tmdb_client, http_client = create_tmdb_client(settings, handler)

    try:
        with pytest.raises(TMDBNotFoundError):
            tmdb_client.search_tv_shows(query="Severance")
    finally:
        http_client.close()


def test_search_tv_shows_converts_unsuccessful_response(
    settings: Settings,
) -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        return httpx.Response(
            status_code=500,
            request=request,
            json={
                "status_message": "Internal error.",
            },
        )

    tmdb_client, http_client = create_tmdb_client(settings, handler)

    try:
        with pytest.raises(
            TMDBResponseError,
            match="status code 500",
        ):
            tmdb_client.search_tv_shows(query="Severance")
    finally:
        http_client.close()


def test_search_tv_shows_rejects_invalid_json(
    settings: Settings,
) -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        return httpx.Response(
            status_code=200,
            request=request,
            content=b"not-valid-json",
            headers={
                "Content-Type": "application/json",
            },
        )

    tmdb_client, http_client = create_tmdb_client(settings, handler)

    try:
        with pytest.raises(
            TMDBResponseError,
            match="invalid response",
        ):
            tmdb_client.search_tv_shows(query="Severance")
    finally:
        http_client.close()


def test_search_tv_shows_rejects_invalid_schema(
    settings: Settings,
) -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        return httpx.Response(
            status_code=200,
            request=request,
            json={
                "page": 1,
                "results": [
                    {
                        "name": "Missing required fields",
                    }
                ],
                "total_pages": 1,
                "total_results": 1,
            },
        )

    tmdb_client, http_client = create_tmdb_client(settings, handler)

    try:
        with pytest.raises(
            TMDBResponseError,
            match="invalid response",
        ):
            tmdb_client.search_tv_shows(query="Severance")
    finally:
        http_client.close()


def test_tmdb_client_requires_api_token(
    settings: Settings,
) -> None:
    settings_without_token = settings.model_copy(
        update={
            "tmdb_api_token": None,
        }
    )

    with pytest.raises(
        TMDBConfigurationError,
        match="API token is not configured",
    ):
        TMDBClient(settings=settings_without_token)


def test_close_does_not_close_injected_http_client(
    settings: Settings,
) -> None:
    http_client = httpx.Client(
        base_url=settings.tmdb_base_url,
        transport=httpx.MockTransport(
            lambda request: httpx.Response(
                status_code=200,
                request=request,
                json={
                    "page": 1,
                    "results": [],
                    "total_pages": 0,
                    "total_results": 0,
                },
            )
        ),
    )

    tmdb_client = TMDBClient(
        settings=settings,
        http_client=http_client,
    )

    tmdb_client.close()

    assert http_client.is_closed is False

    http_client.close()
