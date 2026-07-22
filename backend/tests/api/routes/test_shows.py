from collections.abc import Generator
from datetime import date

import pytest
from app.schemas.tmdb_show import (
    ShowCountry,
    ShowDetailsResponse,
    ShowGenre,
    ShowLanguage,
    ShowNetwork,
    ShowSeasonSummary,
)
from fastapi.testclient import TestClient

from app.api.dependencies import get_show_details_service
from app.main import app as application
from app.providers.tmdb.exceptions import (
    TMDBConfigurationError,
    TMDBNotFoundError,
    TMDBRequestError,
    TMDBResponseError,
)


class SuccessfulShowDetailsService:
    """Test double returning valid TV series details."""

    def __init__(self) -> None:
        self.received_tmdb_id: int | None = None
        self.received_language: str | None = None

    def get_details(
        self,
        *,
        tmdb_id: int,
        language: str | None = None,
    ) -> ShowDetailsResponse:
        self.received_tmdb_id = tmdb_id
        self.received_language = language

        return ShowDetailsResponse(
            tmdb_id=95396,
            title="Severance",
            original_title="Severance",
            overview="Employees undergo a severance procedure.",
            tagline="We're all different people at work.",
            first_air_date=date(2022, 2, 17),
            last_air_date=date(2025, 3, 20),
            poster_url=("https://image.tmdb.org/t/p/w500/poster.jpg"),
            backdrop_url=("https://image.tmdb.org/t/p/original/backdrop.jpg"),
            homepage_url="https://tv.apple.com/show/severance",
            genres=[
                ShowGenre(
                    tmdb_id=18,
                    name="Drama",
                ),
                ShowGenre(
                    tmdb_id=9648,
                    name="Mystery",
                ),
            ],
            seasons=[
                ShowSeasonSummary(
                    tmdb_id=126125,
                    season_number=1,
                    title="Season 1",
                    overview="The first season.",
                    air_date=date(2022, 2, 17),
                    episode_count=9,
                    poster_url=("https://image.tmdb.org/t/p/w500/season-one.jpg"),
                    vote_average=8.4,
                ),
                ShowSeasonSummary(
                    tmdb_id=313055,
                    season_number=2,
                    title="Season 2",
                    overview="The second season.",
                    air_date=date(2025, 1, 17),
                    episode_count=10,
                    poster_url=("https://image.tmdb.org/t/p/w500/season-two.jpg"),
                    vote_average=8.6,
                ),
            ],
            networks=[
                ShowNetwork(
                    tmdb_id=2552,
                    name="Apple TV+",
                    logo_url=("https://image.tmdb.org/t/p/w500/apple-tv-logo.png"),
                    origin_country="US",
                ),
            ],
            origin_countries=["US"],
            production_countries=[
                ShowCountry(
                    code="US",
                    name="United States of America",
                ),
            ],
            languages=["en"],
            spoken_languages=[
                ShowLanguage(
                    code="en",
                    name="English",
                    english_name="English",
                ),
            ],
            original_language="en",
            episode_run_times=[50],
            number_of_episodes=19,
            number_of_seasons=2,
            in_production=True,
            status="Returning Series",
            show_type="Scripted",
            popularity=120.5,
            vote_average=8.4,
            vote_count=2100,
        )


class NotFoundShowDetailsService:
    """Test double for a TV series that does not exist in TMDB."""

    def get_details(
        self,
        *,
        tmdb_id: int,
        language: str | None = None,
    ) -> None:
        raise TMDBNotFoundError("The requested TMDB resource was not found.")


class ConfigurationErrorShowDetailsService:
    """Test double simulating an invalid TMDB configuration."""

    def get_details(
        self,
        *,
        tmdb_id: int,
        language: str | None = None,
    ) -> None:
        raise TMDBConfigurationError("TMDB API token is not configured.")


class RequestErrorShowDetailsService:
    """Test double simulating an unavailable TMDB service."""

    def get_details(
        self,
        *,
        tmdb_id: int,
        language: str | None = None,
    ) -> None:
        raise TMDBRequestError("TMDB could not be reached.")


class ResponseErrorShowDetailsService:
    """Test double simulating an invalid TMDB response."""

    def get_details(
        self,
        *,
        tmdb_id: int,
        language: str | None = None,
    ) -> None:
        raise TMDBResponseError("TMDB returned an invalid response.")


@pytest.fixture
def successful_show_details_service() -> Generator[SuccessfulShowDetailsService, None, None]:
    """Override the details service with a successful test double."""

    service = SuccessfulShowDetailsService()

    def override() -> SuccessfulShowDetailsService:
        return service

    application.dependency_overrides[get_show_details_service] = override

    yield service

    application.dependency_overrides.pop(
        get_show_details_service,
        None,
    )


@pytest.fixture
def not_found_show_details_service() -> Generator[None, None, None]:
    """Override the details service with a not-found test double."""

    def override() -> NotFoundShowDetailsService:
        return NotFoundShowDetailsService()

    application.dependency_overrides[get_show_details_service] = override

    yield

    application.dependency_overrides.pop(
        get_show_details_service,
        None,
    )


@pytest.fixture
def configuration_error_show_details_service() -> Generator[None, None, None]:
    """Override the details service with a configuration-error double."""

    def override() -> ConfigurationErrorShowDetailsService:
        return ConfigurationErrorShowDetailsService()

    application.dependency_overrides[get_show_details_service] = override

    yield

    application.dependency_overrides.pop(
        get_show_details_service,
        None,
    )


@pytest.fixture
def request_error_show_details_service() -> Generator[None, None, None]:
    """Override the details service with a request-error test double."""

    def override() -> RequestErrorShowDetailsService:
        return RequestErrorShowDetailsService()

    application.dependency_overrides[get_show_details_service] = override

    yield

    application.dependency_overrides.pop(
        get_show_details_service,
        None,
    )


@pytest.fixture
def response_error_show_details_service() -> Generator[None, None, None]:
    """Override the details service with a response-error test double."""

    def override() -> ResponseErrorShowDetailsService:
        return ResponseErrorShowDetailsService()

    application.dependency_overrides[get_show_details_service] = override

    yield

    application.dependency_overrides.pop(
        get_show_details_service,
        None,
    )


def test_get_show_details_returns_valid_response(
    client: TestClient,
    successful_show_details_service: SuccessfulShowDetailsService,
) -> None:
    """Return detailed information about an existing TV series."""

    response = client.get("/shows/tmdb/95396")

    assert response.status_code == 200

    body = response.json()

    assert body["tmdb_id"] == 95396
    assert body["title"] == "Severance"
    assert body["original_title"] == "Severance"
    assert body["first_air_date"] == "2022-02-17"
    assert body["last_air_date"] == "2025-03-20"
    assert body["number_of_episodes"] == 19
    assert body["number_of_seasons"] == 2
    assert body["in_production"] is True
    assert body["status"] == "Returning Series"
    assert body["show_type"] == "Scripted"

    assert len(body["genres"]) == 2
    assert body["genres"][0] == {
        "tmdb_id": 18,
        "name": "Drama",
    }

    assert len(body["seasons"]) == 2
    assert body["seasons"][0]["season_number"] == 1
    assert body["seasons"][0]["episode_count"] == 9

    assert len(body["networks"]) == 1
    assert body["networks"][0]["name"] == "Apple TV+"

    assert successful_show_details_service.received_tmdb_id == 95396
    assert successful_show_details_service.received_language is None


def test_get_show_details_passes_language_to_service(
    client: TestClient,
    successful_show_details_service: SuccessfulShowDetailsService,
) -> None:
    """Pass the requested response language to the details service."""

    response = client.get(
        "/shows/tmdb/95396",
        params={
            "language": "pt-PT",
        },
    )

    assert response.status_code == 200
    assert successful_show_details_service.received_tmdb_id == 95396
    assert successful_show_details_service.received_language == "pt-PT"


def test_get_show_details_returns_404_when_show_does_not_exist(
    client: TestClient,
    not_found_show_details_service: None,
) -> None:
    """Return HTTP 404 when the requested TMDB series does not exist."""

    response = client.get("/shows/tmdb/999999999")

    assert response.status_code == 404
    assert response.json() == {
        "detail": "The requested TV series was not found.",
    }


def test_get_show_details_returns_500_when_tmdb_is_not_configured(
    client: TestClient,
    configuration_error_show_details_service: None,
) -> None:
    """Return HTTP 500 when the TMDB provider is not configured."""

    response = client.get("/shows/tmdb/95396")

    assert response.status_code == 500
    assert response.json() == {
        "detail": "The TMDB provider is not configured.",
    }


def test_get_show_details_returns_503_when_tmdb_is_unavailable(
    client: TestClient,
    request_error_show_details_service: None,
) -> None:
    """Return HTTP 503 when TMDB cannot be reached."""

    response = client.get("/shows/tmdb/95396")

    assert response.status_code == 503
    assert response.json() == {
        "detail": "The TMDB service is currently unavailable.",
    }


def test_get_show_details_returns_502_for_invalid_tmdb_response(
    client: TestClient,
    response_error_show_details_service: None,
) -> None:
    """Return HTTP 502 when TMDB returns an invalid response."""

    response = client.get("/shows/tmdb/95396")

    assert response.status_code == 502
    assert response.json() == {
        "detail": "TMDB returned an invalid response.",
    }


@pytest.mark.parametrize(
    "tmdb_id",
    [
        0,
        -1,
        -100,
    ],
)
def test_get_show_details_rejects_invalid_tmdb_id(
    client: TestClient,
    tmdb_id: int,
) -> None:
    """Reject TMDB identifiers lower than one."""

    response = client.get(f"/shows/tmdb/{tmdb_id}")

    assert response.status_code == 422


@pytest.mark.parametrize(
    "language",
    [
        "e",
        "this-language-is-too-long",
    ],
)
def test_get_show_details_rejects_invalid_language(
    client: TestClient,
    language: str,
) -> None:
    """Reject languages outside the accepted length limits."""

    response = client.get(
        "/shows/tmdb/95396",
        params={
            "language": language,
        },
    )

    assert response.status_code == 422
