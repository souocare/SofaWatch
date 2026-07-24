from collections.abc import Generator
from datetime import date
from uuid import uuid4

from sqlalchemy.orm import Session

from app.models.genre import Genre
from app.models.show import Show

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


def create_local_show(
    db_session: Session,
    *,
    tmdb_id: int,
    title: str,
    original_title: str | None = None,
    status: str = "Returning Series",
    first_air_date: date | None = None,
    popularity: float = 0.0,
    vote_average: float = 0.0,
    genres: list[Genre] | None = None,
) -> Show:
    """Create and persist a locally stored TV series for route tests."""

    show = Show(
        tmdb_id=tmdb_id,
        title=title,
        original_title=original_title or title,
        overview=f"Overview for {title}.",
        tagline=f"Tagline for {title}.",
        first_air_date=first_air_date,
        last_air_date=None,
        tmdb_poster_path=f"/posters/{tmdb_id}.jpg",
        tmdb_backdrop_path=f"/backdrops/{tmdb_id}.jpg",
        local_poster_path=None,
        local_backdrop_path=None,
        homepage_url=None,
        original_language="en",
        status=status,
        show_type="Scripted",
        in_production=status == "Returning Series",
        number_of_seasons=1,
        number_of_episodes=10,
        episode_run_time=50,
        popularity=popularity,
        vote_average=vote_average,
        vote_count=100,
        metadata_language="en-US",
        genres=genres or [],
    )

    db_session.add(show)
    db_session.commit()
    db_session.refresh(show)

    return show

def create_genre(
    db_session: Session,
    *,
    tmdb_id: int,
    name: str,
    slug: str,
) -> Genre:
    """Create and persist a TV series genre for route tests."""

    genre = Genre(
        tmdb_id=tmdb_id,
        name=name,
        slug=slug,
    )

    db_session.add(genre)
    db_session.commit()
    db_session.refresh(genre)

    return genre


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


def test_list_shows_returns_empty_paginated_response(
    client: TestClient,
) -> None:
    """Return an empty paginated response when no local shows exist."""

    response = client.get("/shows")

    assert response.status_code == 200
    assert response.json() == {
        "items": [],
        "total": 0,
        "offset": 0,
        "limit": 50,
        "has_next": False,
    }

def test_list_shows_returns_locally_stored_shows(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return locally stored TV series."""

    create_local_show(
        db_session,
        tmdb_id=1396,
        title="Breaking Bad",
        first_air_date=date(2008, 1, 20),
        vote_average=8.9,
    )
    create_local_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
        first_air_date=date(2022, 2, 17),
        vote_average=8.4,
    )

    response = client.get("/shows")

    assert response.status_code == 200

    body = response.json()

    assert body["total"] == 2
    assert body["offset"] == 0
    assert body["limit"] == 50
    assert body["has_next"] is False

    assert [item["title"] for item in body["items"]] == [
        "Breaking Bad",
        "Severance",
    ]


def test_list_shows_returns_empty_paginated_response(
    client: TestClient,
) -> None:
    """Return an empty paginated response when no local shows exist."""

    response = client.get("/shows")

    assert response.status_code == 200
    assert response.json() == {
        "items": [],
        "total": 0,
        "offset": 0,
        "limit": 50,
        "has_next": False,
    }


def test_list_shows_returns_locally_stored_shows(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return locally stored TV series."""

    create_local_show(
        db_session,
        tmdb_id=1396,
        title="Breaking Bad",
        first_air_date=date(2008, 1, 20),
        vote_average=8.9,
    )
    create_local_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
        first_air_date=date(2022, 2, 17),
        vote_average=8.4,
    )

    response = client.get("/shows")

    assert response.status_code == 200

    body = response.json()

    assert body["total"] == 2
    assert body["offset"] == 0
    assert body["limit"] == 50
    assert body["has_next"] is False

    assert [item["title"] for item in body["items"]] == [
        "Breaking Bad",
        "Severance",
    ]

def test_list_shows_applies_pagination(
    client: TestClient,
    db_session: Session,
) -> None:
    """Apply offset and limit to the local TV series listing."""

    create_local_show(
        db_session,
        tmdb_id=1,
        title="Alpha",
    )
    create_local_show(
        db_session,
        tmdb_id=2,
        title="Bravo",
    )
    create_local_show(
        db_session,
        tmdb_id=3,
        title="Charlie",
    )

    response = client.get(
        "/shows",
        params={
            "offset": 1,
            "limit": 1,
        },
    )

    assert response.status_code == 200

    body = response.json()

    assert body["total"] == 3
    assert body["offset"] == 1
    assert body["limit"] == 1
    assert body["has_next"] is True
    assert len(body["items"]) == 1
    assert body["items"][0]["title"] == "Bravo"


def test_list_shows_reports_no_next_page_on_last_page(
    client: TestClient,
    db_session: Session,
) -> None:
    """Report that no further page exists when returning the final item."""

    create_local_show(
        db_session,
        tmdb_id=1,
        title="Alpha",
    )
    create_local_show(
        db_session,
        tmdb_id=2,
        title="Bravo",
    )

    response = client.get(
        "/shows",
        params={
            "offset": 1,
            "limit": 1,
        },
    )

    assert response.status_code == 200

    body = response.json()

    assert body["total"] == 2
    assert body["has_next"] is False
    assert body["items"][0]["title"] == "Bravo"


def test_list_shows_sorts_by_popularity_descending(
    client: TestClient,
    db_session: Session,
) -> None:
    """Sort local TV series by popularity in descending order."""

    create_local_show(
        db_session,
        tmdb_id=1,
        title="Less Popular",
        popularity=20.0,
    )
    create_local_show(
        db_session,
        tmdb_id=2,
        title="Most Popular",
        popularity=100.0,
    )
    create_local_show(
        db_session,
        tmdb_id=3,
        title="Moderately Popular",
        popularity=50.0,
    )

    response = client.get(
        "/shows",
        params={
            "sort_by": "popularity",
            "sort_direction": "desc",
        },
    )

    assert response.status_code == 200

    body = response.json()

    assert [item["title"] for item in body["items"]] == [
        "Most Popular",
        "Moderately Popular",
        "Less Popular",
    ]


def test_list_shows_filters_by_title(
    client: TestClient,
    db_session: Session,
) -> None:
    """Filter local TV series by their localized title."""

    create_local_show(
        db_session,
        tmdb_id=1,
        title="House of the Dragon",
    )
    create_local_show(
        db_session,
        tmdb_id=2,
        title="Severance",
    )

    response = client.get(
        "/shows",
        params={
            "query": "dragon",
        },
    )

    assert response.status_code == 200

    body = response.json()

    assert body["total"] == 1
    assert len(body["items"]) == 1
    assert body["items"][0]["title"] == "House of the Dragon"


def test_list_shows_filters_by_genre_slug(
    client: TestClient,
    db_session: Session,
) -> None:
    """Filter local TV series by genre slug."""

    drama = create_genre(
        db_session,
        tmdb_id=18,
        name="Drama",
        slug="drama",
    )
    comedy = create_genre(
        db_session,
        tmdb_id=35,
        name="Comedy",
        slug="comedy",
    )

    create_local_show(
        db_session,
        tmdb_id=1,
        title="Severance",
        genres=[drama],
    )
    create_local_show(
        db_session,
        tmdb_id=2,
        title="The Office",
        genres=[comedy],
    )

    response = client.get(
        "/shows",
        params={
            "genre": "drama",
        },
    )

    assert response.status_code == 200

    body = response.json()

    assert body["total"] == 1
    assert len(body["items"]) == 1
    assert body["items"][0]["title"] == "Severance"


def test_list_shows_filters_by_status(
    client: TestClient,
    db_session: Session,
) -> None:
    """Filter local TV series by their current status."""

    create_local_show(
        db_session,
        tmdb_id=1,
        title="Severance",
        status="Returning Series",
    )
    create_local_show(
        db_session,
        tmdb_id=2,
        title="Breaking Bad",
        status="Ended",
    )

    response = client.get(
        "/shows",
        params={
            "status": "Ended",
        },
    )

    assert response.status_code == 200

    body = response.json()

    assert body["total"] == 1
    assert len(body["items"]) == 1
    assert body["items"][0]["title"] == "Breaking Bad"
    assert body["items"][0]["status"] == "Ended"


def test_list_shows_combines_query_genre_and_status_filters(
    client: TestClient,
    db_session: Session,
) -> None:
    """Apply title, genre, and status filters together."""

    drama = create_genre(
        db_session,
        tmdb_id=18,
        name="Drama",
        slug="drama",
    )
    comedy = create_genre(
        db_session,
        tmdb_id=35,
        name="Comedy",
        slug="comedy",
    )

    create_local_show(
        db_session,
        tmdb_id=1,
        title="The Last Kingdom",
        status="Ended",
        genres=[drama],
    )
    create_local_show(
        db_session,
        tmdb_id=2,
        title="The Last of Us",
        status="Returning Series",
        genres=[drama],
    )
    create_local_show(
        db_session,
        tmdb_id=3,
        title="The Last Man on Earth",
        status="Ended",
        genres=[comedy],
    )

    response = client.get(
        "/shows",
        params={
            "query": "The Last",
            "genre": "drama",
            "status": "Ended",
        },
    )

    assert response.status_code == 200

    body = response.json()

    assert body["total"] == 1
    assert len(body["items"]) == 1
    assert body["items"][0]["title"] == "The Last Kingdom"


def test_get_local_show_returns_detailed_response(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return detailed information about a locally stored TV series."""

    drama = create_genre(
        db_session,
        tmdb_id=18,
        name="Drama",
        slug="drama",
    )

    show = create_local_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
        status="Returning Series",
        first_air_date=date(2022, 2, 17),
        popularity=120.5,
        vote_average=8.4,
        genres=[drama],
    )

    response = client.get(f"/shows/{show.id}")

    assert response.status_code == 200

    body = response.json()

    assert body["id"] == str(show.id)
    assert body["tmdb_id"] == 95396
    assert body["title"] == "Severance"
    assert body["original_title"] == "Severance"
    assert body["overview"] == "Overview for Severance."
    assert body["tagline"] == "Tagline for Severance."
    assert body["first_air_date"] == "2022-02-17"
    assert body["status"] == "Returning Series"
    assert body["vote_average"] == 8.4
    assert body["metadata_language"] == "en-US"

    assert len(body["genres"]) == 1
    assert body["genres"][0]["name"] == "Drama"
    assert body["genres"][0]["slug"] == "drama"


def test_get_local_show_rejects_invalid_uuid(
    client: TestClient,
) -> None:
    """Reject an invalid local TV series identifier."""

    response = client.get("/shows/not-a-valid-uuid")

    assert response.status_code == 422