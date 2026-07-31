"""Tests for standardized API error responses."""

from fastapi import APIRouter
from fastapi.testclient import TestClient

from app.core.exceptions import APIError
from app.main import app


router = APIRouter()


@router.get("/test-api-error")
def raise_api_error() -> None:
    """Raise an expected API error."""

    raise APIError(
        status_code=409,
        code="test_conflict",
        message="A test conflict occurred.",
    )


app.include_router(
    router,
    prefix="/__tests__",
)


def test_api_error_uses_standard_response(
    client: TestClient,
) -> None:
    """Return the standard error envelope for API errors."""

    response = client.get(
        "/__tests__/test-api-error",
    )

    assert response.status_code == 409
    assert response.json() == {
        "error": {
            "code": "test_conflict",
            "message": "A test conflict occurred.",
        }
    }


def test_http_exception_uses_standard_response(
    client: TestClient,
) -> None:
    """Normalize missing routes into the standard error envelope."""

    response = client.get(
        "/this-route-does-not-exist",
    )

    assert response.status_code == 404
    assert response.json() == {
        "error": {
            "code": "http_error",
            "message": "Not Found",
        }
    }


def test_validation_error_uses_standard_response(
    client: TestClient,
) -> None:
    """Normalize FastAPI request validation errors."""

    response = client.get(
        "/api/v1/shows/not-a-valid-uuid",
    )

    assert response.status_code == 422

    response_data = response.json()

    assert response_data["error"]["code"] == "validation_error"
    assert response_data["error"]["message"] == (
        "The request contains invalid data."
    )

    assert response_data["error"]["details"]

    assert response_data["error"]["details"][0]["field"] == "show_id"