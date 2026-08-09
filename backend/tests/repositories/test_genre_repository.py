from sqlalchemy.orm import Session

from app.models import Genre
from app.repositories.genre import GenreRepository


def test_list_all_returns_genres_ordered_by_name(
    db_session: Session,
) -> None:
    repository = GenreRepository(
        db_session,
    )

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

    db_session.flush()

    genres = repository.list_all()

    assert [
        genre.name
        for genre in genres
    ] == [
        "Action",
        "Drama",
        "Science Fiction",
    ]


def test_get_by_name_returns_matching_genre(
    db_session: Session,
) -> None:
    repository = GenreRepository(
        db_session,
    )

    genre = Genre(
        name="Drama",
        slug="drama",
    )

    db_session.add(genre)
    db_session.flush()

    result = repository.get_by_name(
        "Drama",
    )

    assert result is genre


def test_get_by_name_returns_none_when_missing(
    db_session: Session,
) -> None:
    repository = GenreRepository(
        db_session,
    )

    result = repository.get_by_name(
        "Drama",
    )

    assert result is None


def test_get_or_create_reuses_existing_genre(
    db_session: Session,
) -> None:
    repository = GenreRepository(
        db_session,
    )

    existing = Genre(
        name="Science Fiction",
        slug="science-fiction",
    )

    db_session.add(existing)
    db_session.flush()

    result = repository.get_or_create(
        name="Science Fiction",
    )

    assert result.id == existing.id

    genres = repository.list_all()

    assert len(genres) == 1


def test_get_or_create_creates_missing_genre(
    db_session: Session,
) -> None:
    repository = GenreRepository(
        db_session,
    )

    result = repository.get_or_create(
        name="Science Fiction",
    )

    assert result.id is not None
    assert result.name == "Science Fiction"
    assert result.slug == "science-fiction"

    genres = repository.list_all()

    assert len(genres) == 1