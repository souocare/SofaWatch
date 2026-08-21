
from fastapi.testclient import TestClient


def test_auth_setup_is_public(
    client: TestClient,
) -> None:
    response = client.get(
        "/api/v1/auth/setup",
    )

    assert response.status_code == 200


def test_login_endpoint_is_public(
    client: TestClient,
) -> None:
    response = client.post(
        "/api/v1/auth/login",
        json={
            "username": "missing-user",
            "password": "invalid-password",
        },
    )

    # The request reached the authentication endpoint.
    # Invalid credentials are different from missing authentication.
    assert response.status_code == 401
    assert response.json()["error"]["code"] == "invalid_credentials"


def test_genres_require_authentication(
    unauthenticated_client: TestClient,
) -> None:
    response = unauthenticated_client.get(
        "/api/v1/genres/",
    )

    assert response.status_code == 401
    assert response.json()["error"]["code"] == "authentication_required"


def test_movie_details_require_authentication(
    unauthenticated_client: TestClient,
) -> None:
    response = unauthenticated_client.get(
        "/api/v1/movies/tmdb/438631",
    )

    assert response.status_code == 401
    assert response.json()["error"]["code"] == "authentication_required"


def test_cached_images_require_authentication(
    unauthenticated_client: TestClient,
) -> None:
    response = unauthenticated_client.get(
        "/api/v1/images/shows/00000000-0000-0000-0000-000000000001/poster",
    )

    assert response.status_code == 401
    assert response.json()["error"]["code"] == "authentication_required"

def test_private_endpoint_with_explicit_current_user_still_requires_authentication(
    unauthenticated_client: TestClient,
) -> None:
    response = unauthenticated_client.get(
        "/api/v1/statistics/summary",
    )

    assert response.status_code == 401
    assert response.json()["error"]["code"] == "authentication_required"