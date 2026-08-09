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


def test_search_movies_returns_validated_response(
    settings: Settings,
) -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        assert request.method == "GET"
        assert request.url.path.endswith("/search/movie")

        assert request.url.params["query"] == "Dune"
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
                        "id": 438631,
                        "title": "Dune",
                        "original_title": "Dune",
                        "overview": "Paul Atreides travels to Arrakis.",
                        "release_date": "2021-09-15",
                        "poster_path": "/dune-poster.jpg",
                        "backdrop_path": "/dune-backdrop.jpg",
                        "original_language": "en",
                        "genre_ids": [878, 12],
                        "popularity": 95.4,
                        "vote_average": 7.8,
                        "vote_count": 13000,
                        "adult": False,
                        "video": False,
                    }
                ],
                "total_pages": 3,
                "total_results": 50,
            },
        )

    tmdb_client, http_client = create_tmdb_client(
        settings,
        handler,
    )

    try:
        response = tmdb_client.search_movies(
            query="Dune",
        )
    finally:
        http_client.close()

    assert response.page == 1
    assert response.total_pages == 3
    assert response.total_results == 50
    assert len(response.results) == 1

    movie = response.results[0]

    assert movie.id == 438631
    assert movie.title == "Dune"
    assert movie.original_title == "Dune"
    assert movie.release_date is not None
    assert movie.release_date.isoformat() == "2021-09-15"
    assert movie.genre_ids == [878, 12]


def test_search_movies_strips_query_and_uses_custom_parameters(
    settings: Settings,
) -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        assert request.url.path.endswith("/search/movie")
        assert request.url.params["query"] == "Blade Runner"
        assert request.url.params["page"] == "2"
        assert request.url.params["language"] == "pt-PT"

        return httpx.Response(
            status_code=200,
            request=request,
            json={
                "page": 2,
                "results": [],
                "total_pages": 2,
                "total_results": 30,
            },
        )

    tmdb_client, http_client = create_tmdb_client(
        settings,
        handler,
    )

    try:
        response = tmdb_client.search_movies(
            query="  Blade Runner  ",
            page=2,
            language="pt-PT",
        )
    finally:
        http_client.close()

    assert response.page == 2
    assert response.results == []


def test_search_movies_rejects_empty_query(
    settings: Settings,
) -> None:
    tmdb_client, http_client = create_tmdb_client(
        settings,
        lambda request: httpx.Response(
            200,
            request=request,
        ),
    )

    try:
        with pytest.raises(
            ValueError,
            match="search query cannot be empty",
        ):
            tmdb_client.search_movies(
                query="   ",
            )
    finally:
        http_client.close()


def test_search_movies_rejects_invalid_page(
    settings: Settings,
) -> None:
    tmdb_client, http_client = create_tmdb_client(
        settings,
        lambda request: httpx.Response(
            200,
            request=request,
        ),
    )

    try:
        with pytest.raises(
            ValueError,
            match="page must be greater than or equal to 1",
        ):
            tmdb_client.search_movies(
                query="Dune",
                page=0,
            )
    finally:
        http_client.close()


def test_search_multi_returns_movies_tv_and_people(
    settings: Settings,
) -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        assert request.method == "GET"
        assert request.url.path.endswith("/search/multi")

        assert request.url.params["query"] == "Dune"
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
                        "media_type": "movie",
                        "id": 438631,
                        "title": "Dune",
                        "original_title": "Dune",
                        "overview": "Paul Atreides travels to Arrakis.",
                        "release_date": "2021-09-15",
                        "poster_path": "/dune.jpg",
                        "backdrop_path": "/dune-backdrop.jpg",
                        "original_language": "en",
                        "genre_ids": [878, 12],
                        "popularity": 95.4,
                        "vote_average": 7.8,
                        "vote_count": 13000,
                    },
                    {
                        "media_type": "tv",
                        "id": 95396,
                        "name": "Severance",
                        "original_name": "Severance",
                        "overview": "Employees undergo a severance procedure.",
                        "first_air_date": "2022-02-17",
                        "poster_path": "/severance.jpg",
                        "backdrop_path": "/severance-backdrop.jpg",
                        "original_language": "en",
                        "genre_ids": [18, 9648],
                        "popularity": 120.5,
                        "vote_average": 8.4,
                        "vote_count": 2100,
                    },
                    {
                        "media_type": "person",
                        "id": 500,
                        "name": "Example Person",
                        "original_name": "Example Person",
                        "profile_path": "/person.jpg",
                        "known_for_department": "Acting",
                        "popularity": 50.0,
                    },
                ],
                "total_pages": 1,
                "total_results": 3,
            },
        )

    tmdb_client, http_client = create_tmdb_client(
        settings,
        handler,
    )

    try:
        response = tmdb_client.search_multi(
            query="Dune",
        )
    finally:
        http_client.close()

    assert response.page == 1
    assert response.total_results == 3
    assert len(response.results) == 3

    assert response.results[0].media_type == "movie"
    assert response.results[1].media_type == "tv"
    assert response.results[2].media_type == "person"


def test_search_multi_strips_query_and_uses_custom_parameters(
    settings: Settings,
) -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        assert request.url.path.endswith("/search/multi")
        assert request.url.params["query"] == "The Last of Us"
        assert request.url.params["page"] == "4"
        assert request.url.params["language"] == "pt-PT"

        return httpx.Response(
            status_code=200,
            request=request,
            json={
                "page": 4,
                "results": [],
                "total_pages": 4,
                "total_results": 75,
            },
        )

    tmdb_client, http_client = create_tmdb_client(
        settings,
        handler,
    )

    try:
        response = tmdb_client.search_multi(
            query="  The Last of Us  ",
            page=4,
            language="pt-PT",
        )
    finally:
        http_client.close()

    assert response.page == 4
    assert response.results == []


def test_search_multi_rejects_empty_query(
    settings: Settings,
) -> None:
    tmdb_client, http_client = create_tmdb_client(
        settings,
        lambda request: httpx.Response(
            200,
            request=request,
        ),
    )

    try:
        with pytest.raises(
            ValueError,
            match="search query cannot be empty",
        ):
            tmdb_client.search_multi(
                query="   ",
            )
    finally:
        http_client.close()


def test_search_multi_rejects_invalid_page(
    settings: Settings,
) -> None:
    tmdb_client, http_client = create_tmdb_client(
        settings,
        lambda request: httpx.Response(
            200,
            request=request,
        ),
    )

    try:
        with pytest.raises(
            ValueError,
            match="page must be greater than or equal to 1",
        ):
            tmdb_client.search_multi(
                query="Dune",
                page=0,
            )
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


def test_get_tv_show_details_returns_validated_response(
    settings: Settings,
) -> None:
    """Return validated details for an existing TMDB TV series."""

    def handler(request: httpx.Request) -> httpx.Response:
        assert request.method == "GET"
        assert request.url.path.endswith("/tv/95396")
        assert request.url.params["language"] == "en-US"

        return httpx.Response(
            status_code=200,
            request=request,
            json={
                "adult": False,
                "backdrop_path": "/backdrop.jpg",
                "episode_run_time": [50],
                "first_air_date": "2022-02-17",
                "genres": [
                    {
                        "id": 18,
                        "name": "Drama",
                    },
                    {
                        "id": 9648,
                        "name": "Mystery",
                    },
                ],
                "homepage": "https://tv.apple.com/show/severance",
                "id": 95396,
                "in_production": True,
                "languages": ["en"],
                "last_air_date": "2025-03-20",
                "name": "Severance",
                "networks": [
                    {
                        "id": 2552,
                        "logo_path": "/apple-tv-logo.png",
                        "name": "Apple TV+",
                        "origin_country": "US",
                    }
                ],
                "number_of_episodes": 19,
                "number_of_seasons": 2,
                "origin_country": ["US"],
                "original_language": "en",
                "original_name": "Severance",
                "overview": "Employees undergo a severance procedure.",
                "popularity": 120.5,
                "poster_path": "/poster.jpg",
                "production_countries": [
                    {
                        "iso_3166_1": "US",
                        "name": "United States of America",
                    }
                ],
                "seasons": [
                    {
                        "air_date": "2022-02-17",
                        "episode_count": 9,
                        "id": 126125,
                        "name": "Season 1",
                        "overview": "The first season.",
                        "poster_path": "/season-one.jpg",
                        "season_number": 1,
                        "vote_average": 8.4,
                    },
                    {
                        "air_date": "2025-01-17",
                        "episode_count": 10,
                        "id": 313055,
                        "name": "Season 2",
                        "overview": "The second season.",
                        "poster_path": "/season-two.jpg",
                        "season_number": 2,
                        "vote_average": 8.6,
                    },
                ],
                "spoken_languages": [
                    {
                        "english_name": "English",
                        "iso_639_1": "en",
                        "name": "English",
                    }
                ],
                "status": "Returning Series",
                "tagline": "We're all different people at work.",
                "type": "Scripted",
                "vote_average": 8.4,
                "vote_count": 2100,
            },
        )

    tmdb_client, http_client = create_tmdb_client(settings, handler)

    try:
        response = tmdb_client.get_tv_show_details(
            tmdb_id=95396,
        )
    finally:
        http_client.close()

    assert response.id == 95396
    assert response.name == "Severance"
    assert response.original_name == "Severance"
    assert response.original_language == "en"
    assert response.number_of_seasons == 2
    assert response.number_of_episodes == 19
    assert response.status == "Returning Series"
    assert response.in_production is True

    assert response.first_air_date is not None
    assert response.first_air_date.isoformat() == "2022-02-17"

    assert response.last_air_date is not None
    assert response.last_air_date.isoformat() == "2025-03-20"

    assert len(response.genres) == 2
    assert response.genres[0].id == 18
    assert response.genres[0].name == "Drama"

    assert len(response.seasons) == 2
    assert response.seasons[0].season_number == 1
    assert response.seasons[0].episode_count == 9

    assert len(response.networks) == 1
    assert response.networks[0].name == "Apple TV+"

    assert response.origin_country == ["US"]
    assert response.languages == ["en"]

    assert len(response.production_countries) == 1
    assert response.production_countries[0].iso_3166_1 == "US"

    assert len(response.spoken_languages) == 1
    assert response.spoken_languages[0].iso_639_1 == "en"


def test_get_tv_show_details_uses_custom_language(
    settings: Settings,
) -> None:
    """Send the requested language when retrieving TV series details."""

    def handler(request: httpx.Request) -> httpx.Response:
        assert request.url.path.endswith("/tv/95396")
        assert request.url.params["language"] == "pt-PT"

        return httpx.Response(
            status_code=200,
            request=request,
            json={
                "adult": False,
                "backdrop_path": None,
                "episode_run_time": [],
                "first_air_date": "2022-02-17",
                "genres": [],
                "homepage": "",
                "id": 95396,
                "in_production": True,
                "languages": ["en"],
                "last_air_date": None,
                "name": "Separação",
                "networks": [],
                "number_of_episodes": 19,
                "number_of_seasons": 2,
                "origin_country": ["US"],
                "original_language": "en",
                "original_name": "Severance",
                "overview": "Funcionários passam por um procedimento.",
                "popularity": 120.5,
                "poster_path": None,
                "production_countries": [],
                "seasons": [],
                "spoken_languages": [],
                "status": "Returning Series",
                "tagline": "",
                "type": "Scripted",
                "vote_average": 8.4,
                "vote_count": 2100,
            },
        )

    tmdb_client, http_client = create_tmdb_client(settings, handler)

    try:
        response = tmdb_client.get_tv_show_details(
            tmdb_id=95396,
            language="pt-PT",
        )
    finally:
        http_client.close()

    assert response.id == 95396
    assert response.name == "Separação"
    assert response.original_name == "Severance"


@pytest.mark.parametrize(
    "tmdb_id",
    [
        0,
        -1,
        -100,
    ],
)
def test_get_tv_show_details_rejects_invalid_id(
    settings: Settings,
    tmdb_id: int,
) -> None:
    """Reject TMDB identifiers lower than one."""

    request_was_made = False

    def handler(request: httpx.Request) -> httpx.Response:
        nonlocal request_was_made
        request_was_made = True

        return httpx.Response(
            status_code=200,
            request=request,
        )

    tmdb_client, http_client = create_tmdb_client(settings, handler)

    try:
        with pytest.raises(
            ValueError,
            match="TMDB ID must be greater than or equal to 1",
        ):
            tmdb_client.get_tv_show_details(
                tmdb_id=tmdb_id,
            )
    finally:
        http_client.close()

    assert request_was_made is False


def test_get_tv_show_details_converts_not_found_response(
    settings: Settings,
) -> None:
    """Convert a TMDB 404 response into a not-found provider error."""

    def handler(request: httpx.Request) -> httpx.Response:
        assert request.url.path.endswith("/tv/999999999")

        return httpx.Response(
            status_code=httpx.codes.NOT_FOUND,
            request=request,
            json={
                "status_code": 34,
                "status_message": ("The resource you requested could not be found."),
            },
        )

    tmdb_client, http_client = create_tmdb_client(settings, handler)

    try:
        with pytest.raises(
            TMDBNotFoundError,
            match="requested TMDB resource was not found",
        ):
            tmdb_client.get_tv_show_details(
                tmdb_id=999999999,
            )
    finally:
        http_client.close()


def test_get_tv_show_details_rejects_invalid_schema(
    settings: Settings,
) -> None:
    """Reject a TV details response that does not match the schema."""

    def handler(request: httpx.Request) -> httpx.Response:
        return httpx.Response(
            status_code=200,
            request=request,
            json={
                "id": 95396,
                "name": "Severance",
            },
        )

    tmdb_client, http_client = create_tmdb_client(settings, handler)

    try:
        with pytest.raises(
            TMDBResponseError,
            match="invalid response",
        ):
            tmdb_client.get_tv_show_details(
                tmdb_id=95396,
            )
    finally:
        http_client.close()


def test_get_tv_season_details_returns_validated_response(
    settings: Settings,
) -> None:
    """Return validated details for an existing TMDB TV season."""

    def handler(request: httpx.Request) -> httpx.Response:
        assert request.method == "GET"
        assert request.url.path.endswith("/tv/95396/season/1")
        assert request.url.params["language"] == "en-US"

        return httpx.Response(
            status_code=200,
            request=request,
            json={
                "_id": "season-internal-id",
                "air_date": "2022-02-18",
                "episodes": [
                    {
                        "air_date": "2022-02-18",
                        "episode_number": 1,
                        "episode_type": "standard",
                        "id": 2001,
                        "name": "Good News About Hell",
                        "overview": "Mark starts a new day at Lumon.",
                        "production_code": "",
                        "runtime": 57,
                        "season_number": 1,
                        "show_id": 95396,
                        "still_path": "/episode-1.jpg",
                        "vote_average": 8.1,
                        "vote_count": 42,
                    },
                    {
                        "air_date": "2022-02-25",
                        "episode_number": 2,
                        "episode_type": "standard",
                        "id": 2002,
                        "name": "Half Loop",
                        "overview": "The team continues its work.",
                        "production_code": "",
                        "runtime": 54,
                        "season_number": 1,
                        "show_id": 95396,
                        "still_path": "/episode-2.jpg",
                        "vote_average": 8.2,
                        "vote_count": 38,
                    },
                ],
                "id": 134792,
                "name": "Season 1",
                "overview": "The first season.",
                "poster_path": "/season-1.jpg",
                "season_number": 1,
            },
        )

    tmdb_client, http_client = create_tmdb_client(settings, handler)

    try:
        response = tmdb_client.get_tv_season_details(
            tmdb_id=95396,
            season_number=1,
        )
    finally:
        http_client.close()

    assert response.id == 134792
    assert response.name == "Season 1"
    assert response.season_number == 1
    assert response.air_date is not None
    assert response.air_date.isoformat() == "2022-02-18"

    assert len(response.episodes) == 2

    first_episode = response.episodes[0]

    assert first_episode.id == 2001
    assert first_episode.episode_number == 1
    assert first_episode.name == "Good News About Hell"
    assert first_episode.runtime == 57
    assert first_episode.vote_average == 8.1
    assert first_episode.vote_count == 42
    assert first_episode.still_path == "/episode-1.jpg"


def test_get_tv_season_details_uses_custom_language(
    settings: Settings,
) -> None:
    """Send the requested language when retrieving TV season details."""

    def handler(request: httpx.Request) -> httpx.Response:
        assert request.url.path.endswith("/tv/95396/season/1")
        assert request.url.params["language"] == "pt-PT"

        return httpx.Response(
            status_code=200,
            request=request,
            json={
                "air_date": "2022-02-18",
                "episodes": [],
                "id": 134792,
                "name": "Temporada 1",
                "overview": "A primeira temporada.",
                "poster_path": "/season-1.jpg",
                "season_number": 1,
            },
        )

    tmdb_client, http_client = create_tmdb_client(settings, handler)

    try:
        response = tmdb_client.get_tv_season_details(
            tmdb_id=95396,
            season_number=1,
            language="pt-PT",
        )
    finally:
        http_client.close()

    assert response.id == 134792
    assert response.name == "Temporada 1"


def test_get_tv_season_details_supports_specials(
    settings: Settings,
) -> None:
    """Allow season number zero for TV specials."""

    def handler(request: httpx.Request) -> httpx.Response:
        assert request.url.path.endswith("/tv/95396/season/0")
        assert request.url.params["language"] == "en-US"

        return httpx.Response(
            status_code=200,
            request=request,
            json={
                "air_date": None,
                "episodes": [],
                "id": 1000,
                "name": "Specials",
                "overview": "Special episodes.",
                "poster_path": None,
                "season_number": 0,
            },
        )

    tmdb_client, http_client = create_tmdb_client(settings, handler)

    try:
        response = tmdb_client.get_tv_season_details(
            tmdb_id=95396,
            season_number=0,
        )
    finally:
        http_client.close()

    assert response.id == 1000
    assert response.season_number == 0
    assert response.name == "Specials"


@pytest.mark.parametrize(
    "tmdb_id",
    [
        0,
        -1,
        -100,
    ],
)
def test_get_tv_season_details_rejects_invalid_tmdb_id(
    settings: Settings,
    tmdb_id: int,
) -> None:
    """Reject TMDB identifiers lower than one."""

    request_was_made = False

    def handler(request: httpx.Request) -> httpx.Response:
        nonlocal request_was_made
        request_was_made = True

        return httpx.Response(
            status_code=200,
            request=request,
        )

    tmdb_client, http_client = create_tmdb_client(settings, handler)

    try:
        with pytest.raises(
            ValueError,
            match="TMDB ID must be greater than or equal to 1",
        ):
            tmdb_client.get_tv_season_details(
                tmdb_id=tmdb_id,
                season_number=1,
            )
    finally:
        http_client.close()

    assert request_was_made is False


@pytest.mark.parametrize(
    "season_number",
    [
        -1,
        -10,
    ],
)
def test_get_tv_season_details_rejects_invalid_season_number(
    settings: Settings,
    season_number: int,
) -> None:
    """Reject season numbers lower than zero."""

    request_was_made = False

    def handler(request: httpx.Request) -> httpx.Response:
        nonlocal request_was_made
        request_was_made = True

        return httpx.Response(
            status_code=200,
            request=request,
        )

    tmdb_client, http_client = create_tmdb_client(settings, handler)

    try:
        with pytest.raises(
            ValueError,
            match="season number must be greater than or equal to 0",
        ):
            tmdb_client.get_tv_season_details(
                tmdb_id=95396,
                season_number=season_number,
            )
    finally:
        http_client.close()

    assert request_was_made is False


def test_get_tv_season_details_normalizes_empty_dates(
    settings: Settings,
) -> None:
    """Convert empty TMDB date strings into null values."""

    def handler(request: httpx.Request) -> httpx.Response:
        return httpx.Response(
            status_code=200,
            request=request,
            json={
                "air_date": "",
                "episodes": [
                    {
                        "air_date": "",
                        "episode_number": 1,
                        "episode_type": "standard",
                        "id": 2001,
                        "name": "Future Episode",
                        "overview": "",
                        "production_code": "",
                        "runtime": None,
                        "season_number": 1,
                        "show_id": 95396,
                        "still_path": None,
                        "vote_average": 0.0,
                        "vote_count": 0,
                    }
                ],
                "id": 134792,
                "name": "Season 1",
                "overview": "",
                "poster_path": None,
                "season_number": 1,
            },
        )

    tmdb_client, http_client = create_tmdb_client(settings, handler)

    try:
        response = tmdb_client.get_tv_season_details(
            tmdb_id=95396,
            season_number=1,
        )
    finally:
        http_client.close()

    assert response.air_date is None
    assert len(response.episodes) == 1
    assert response.episodes[0].air_date is None
    assert response.episodes[0].runtime is None


def test_get_tv_season_details_converts_not_found_response(
    settings: Settings,
) -> None:
    """Convert a TMDB 404 response into a not-found provider error."""

    def handler(request: httpx.Request) -> httpx.Response:
        assert request.url.path.endswith(
            "/tv/95396/season/999",
        )

        return httpx.Response(
            status_code=httpx.codes.NOT_FOUND,
            request=request,
            json={
                "status_code": 34,
                "status_message": ("The resource you requested could not be found."),
            },
        )

    tmdb_client, http_client = create_tmdb_client(settings, handler)

    try:
        with pytest.raises(
            TMDBNotFoundError,
            match="requested TMDB resource was not found",
        ):
            tmdb_client.get_tv_season_details(
                tmdb_id=95396,
                season_number=999,
            )
    finally:
        http_client.close()


def test_get_tv_season_details_rejects_invalid_schema(
    settings: Settings,
) -> None:
    """Reject a TV season response that does not match the schema."""

    def handler(request: httpx.Request) -> httpx.Response:
        return httpx.Response(
            status_code=200,
            request=request,
            json={
                "id": 134792,
                "name": "Season 1",
            },
        )

    tmdb_client, http_client = create_tmdb_client(settings, handler)

    try:
        with pytest.raises(
            TMDBResponseError,
            match="invalid response",
        ):
            tmdb_client.get_tv_season_details(
                tmdb_id=95396,
                season_number=1,
            )
    finally:
        http_client.close()

def test_get_trending_shows_returns_validated_response(
    settings: Settings,
) -> None:
    """Return weekly trending TV series from TMDB."""

    def handler(request: httpx.Request) -> httpx.Response:
        assert request.method == "GET"
        assert request.url.path.endswith("/trending/tv/week")
        assert request.url.params["language"] == "en-US"

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
                        "poster_path": "/severance.jpg",
                        "backdrop_path": "/severance-backdrop.jpg",
                        "original_language": "en",
                        "genre_ids": [18, 9648],
                        "popularity": 120.5,
                        "vote_average": 8.4,
                        "vote_count": 2100,
                    }
                ],
                "total_pages": 1,
                "total_results": 1,
            },
        )

    tmdb_client, http_client = create_tmdb_client(
        settings,
        handler,
    )

    try:
        response = tmdb_client.get_trending_shows()
    finally:
        http_client.close()

    assert response.page == 1
    assert response.total_results == 1
    assert len(response.results) == 1

    show = response.results[0]

    assert show.id == 95396
    assert show.name == "Severance"
    assert show.first_air_date is not None
    assert show.first_air_date.isoformat() == "2022-02-17"


def test_get_trending_movies_returns_validated_response(
    settings: Settings,
) -> None:
    """Return weekly trending Movies from TMDB."""

    def handler(request: httpx.Request) -> httpx.Response:
        assert request.method == "GET"
        assert request.url.path.endswith("/trending/movie/week")
        assert request.url.params["language"] == "en-US"

        return httpx.Response(
            status_code=200,
            request=request,
            json={
                "page": 1,
                "results": [
                    {
                        "id": 438631,
                        "title": "Dune",
                        "original_title": "Dune",
                        "overview": "Paul Atreides travels to Arrakis.",
                        "release_date": "2021-09-15",
                        "poster_path": "/dune.jpg",
                        "backdrop_path": "/dune-backdrop.jpg",
                        "original_language": "en",
                        "genre_ids": [878, 12],
                        "popularity": 95.4,
                        "vote_average": 7.8,
                        "vote_count": 13000,
                        "adult": False,
                        "video": False,
                    }
                ],
                "total_pages": 1,
                "total_results": 1,
            },
        )

    tmdb_client, http_client = create_tmdb_client(
        settings,
        handler,
    )

    try:
        response = tmdb_client.get_trending_movies()
    finally:
        http_client.close()

    assert response.page == 1
    assert response.total_results == 1
    assert len(response.results) == 1

    movie = response.results[0]

    assert movie.id == 438631
    assert movie.title == "Dune"
    assert movie.release_date is not None
    assert movie.release_date.isoformat() == "2021-09-15"