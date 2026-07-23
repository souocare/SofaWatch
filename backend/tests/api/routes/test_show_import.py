from datetime import datetime, timezone
from unittest.mock import Mock

import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.api.dependencies import get_show_import_service
from app.main import app
from app.models.show import Show
from app.providers.tmdb.exceptions import (
    TMDBConfigurationError,
    TMDBNotFoundError,
    TMDBRequestError,
    TMDBResponseError,
)
from app.services.show_import import ShowImportService

IMPORT_SHOW_URL = "/shows/import/tmdb/{tmdb_id}"
TMDB_ID = 95396


@pytest.fixture
def show_import_service() -> Mock:
    """Provide a mocked show import service."""

    return Mock(spec=ShowImportService)


@pytest.fixture
def imported_show(
    db_session: Session,
) -> Show:
    """Provide a persisted show returned by the mocked import service."""

    show = Show(
        tmdb_id=TMDB_ID,
        title="Severance",
        original_title="Severance",
        overview="Employees undergo a severance procedure.",
        tagline="We're all different people at work.",
        original_language="en",
        metadata_language="en-US",
        metadata_updated_at=datetime.now(timezone.utc),
    )

    db_session.add(show)
    db_session.commit()
    db_session.refresh(show)

    return show


@pytest.fixture
def client_with_show_import_service(
    client: TestClient,
    show_import_service: Mock,
) -> TestClient:
    """Provide a test client using the mocked import service."""

    def override_get_show_import_service() -> Mock:
        return show_import_service

    app.dependency_overrides[
        get_show_import_service
    ] = override_get_show_import_service

    return client


def test_import_show_returns_imported_show(
    client_with_show_import_service: TestClient,
    show_import_service: Mock,
    imported_show: Show,
) -> None:
    """Return the imported local show."""

    show_import_service.import_show.return_value = imported_show

    response = client_with_show_import_service.post(
        IMPORT_SHOW_URL.format(
            tmdb_id=TMDB_ID,
        )
    )

    assert response.status_code == 201

    response_data = response.json()

    assert response_data["tmdb_id"] == TMDB_ID
    assert response_data["title"] == "Severance"
    assert response_data["original_title"] == "Severance"
    assert response_data["overview"] == (
        "Employees undergo a severance procedure."
    )
    assert response_data["metadata_language"] == "en-US"

    show_import_service.import_show.assert_called_once_with(
        tmdb_id=TMDB_ID,
        language=None,
        force_refresh=False,
    )


def test_import_show_forwards_optional_parameters(
    client_with_show_import_service: TestClient,
    show_import_service: Mock,
    imported_show: Show,
) -> None:
    """Forward language and refresh options to the service."""

    show_import_service.import_show.return_value = imported_show

    response = client_with_show_import_service.post(
        IMPORT_SHOW_URL.format(
            tmdb_id=TMDB_ID,
        ),
        params={
            "language": "pt-PT",
            "force_refresh": True,
        },
    )

    assert response.status_code == 201

    show_import_service.import_show.assert_called_once_with(
        tmdb_id=TMDB_ID,
        language="pt-PT",
        force_refresh=True,
    )


@pytest.mark.parametrize(
    "tmdb_id",
    [
        0,
        -1,
    ],
)
def test_import_show_rejects_invalid_tmdb_id(
    client_with_show_import_service: TestClient,
    show_import_service: Mock,
    tmdb_id: int,
) -> None:
    """Reject invalid TMDB identifiers."""

    response = client_with_show_import_service.post(
        IMPORT_SHOW_URL.format(
            tmdb_id=tmdb_id,
        )
    )

    assert response.status_code == 422
    show_import_service.import_show.assert_not_called()


def test_import_show_rejects_language_shorter_than_two_characters(
    client_with_show_import_service: TestClient,
    show_import_service: Mock,
) -> None:
    """Reject a metadata language shorter than two characters."""

    response = client_with_show_import_service.post(
        IMPORT_SHOW_URL.format(
            tmdb_id=TMDB_ID,
        ),
        params={
            "language": "e",
        },
    )

    assert response.status_code == 422
    show_import_service.import_show.assert_not_called()


def test_import_show_rejects_language_longer_than_ten_characters(
    client_with_show_import_service: TestClient,
    show_import_service: Mock,
) -> None:
    """Reject a metadata language longer than ten characters."""

    response = client_with_show_import_service.post(
        IMPORT_SHOW_URL.format(
            tmdb_id=TMDB_ID,
        ),
        params={
            "language": "a" * 11,
        },
    )

    assert response.status_code == 422
    show_import_service.import_show.assert_not_called()


def test_import_show_converts_not_found_error(
    client_with_show_import_service: TestClient,
    show_import_service: Mock,
) -> None:
    """Convert a missing TMDB show into an HTTP 404 response."""

    show_import_service.import_show.side_effect = TMDBNotFoundError(
        "TV series not found."
    )

    response = client_with_show_import_service.post(
        IMPORT_SHOW_URL.format(
            tmdb_id=TMDB_ID,
        )
    )

    assert response.status_code == 404
    assert response.json() == {
        "detail": "The requested TV series was not found.",
    }


def test_import_show_converts_configuration_error(
    client_with_show_import_service: TestClient,
    show_import_service: Mock,
) -> None:
    """Convert a TMDB configuration failure into HTTP 500."""

    show_import_service.import_show.side_effect = (
        TMDBConfigurationError(
            "TMDB API token is not configured."
        )
    )

    response = client_with_show_import_service.post(
        IMPORT_SHOW_URL.format(
            tmdb_id=TMDB_ID,
        )
    )

    assert response.status_code == 500
    assert response.json() == {
        "detail": "The TMDB provider is not configured.",
    }


def test_import_show_converts_request_error(
    client_with_show_import_service: TestClient,
    show_import_service: Mock,
) -> None:
    """Convert a TMDB request failure into HTTP 503."""

    show_import_service.import_show.side_effect = TMDBRequestError(
        "TMDB could not be reached."
    )

    response = client_with_show_import_service.post(
        IMPORT_SHOW_URL.format(
            tmdb_id=TMDB_ID,
        )
    )

    assert response.status_code == 503
    assert response.json() == {
        "detail": "The TMDB service is currently unavailable.",
    }


def test_import_show_converts_response_error(
    client_with_show_import_service: TestClient,
    show_import_service: Mock,
) -> None:
    """Convert an invalid TMDB response into HTTP 502."""

    show_import_service.import_show.side_effect = TMDBResponseError(
        "TMDB returned an invalid response."
    )

    response = client_with_show_import_service.post(
        IMPORT_SHOW_URL.format(
            tmdb_id=TMDB_ID,
        )
    )

    assert response.status_code == 502
    assert response.json() == {
        "detail": "TMDB returned an invalid response.",
    }