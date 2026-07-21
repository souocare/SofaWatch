from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.models import Genre


def test_list_genres_returns_empty_list_when_none_exist(
    client: TestClient,
) -> None:
    """The genres endpoint returns an empty list when no genres exist."""

    response = client.get("/genres/")

    assert response.status_code == 200
    assert response.json() == []


def test_list_genres_returns_genres_ordered_by_name(
    client: TestClient,
    db_session: Session,
) -> None:
    """The genres endpoint returns all genres ordered by name."""

    db_session.add_all(
        [
            Genre(
                name="Science Fiction",
                slug="science-fiction",
            ),
            Genre(
                name="Action",
                slug="action",
            ),
            Genre(
                name="Drama",
                slug="drama",
            ),
        ]
    )
    db_session.commit()

    response = client.get("/genres/")

    assert response.status_code == 200

    response_data = response.json()

    assert [genre["name"] for genre in response_data] == [
        "Action",
        "Drama",
        "Science Fiction",
    ]

    assert [genre["slug"] for genre in response_data] == [
        "action",
        "drama",
        "science-fiction",
    ]

    assert all(isinstance(genre["id"], int) for genre in response_data)
