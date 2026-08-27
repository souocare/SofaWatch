import pytest
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.models import Genre
from app.models.genre_provider_mapping import (
    GenreProviderMapping,
)
from app.repositories.genre_provider_mapping import (
    GenreProviderMappingRepository,
)


def test_add_and_get_provider_mapping(
    db_session: Session,
) -> None:
    genre = Genre(
        name="Drama",
        slug="drama",
    )

    db_session.add(genre)
    db_session.flush()

    repository = GenreProviderMappingRepository(
        db_session,
    )

    mapping = repository.add(
        GenreProviderMapping(
            genre_id=genre.id,
            provider="tmdb",
            media_type="show",
            provider_genre_id=18,
        )
    )

    result = repository.get(
        provider="tmdb",
        media_type="show",
        provider_genre_id=18,
    )

    assert result is mapping
    assert result.genre_id == genre.id
    assert result.genre.name == "Drama"


def test_get_returns_none_when_mapping_does_not_exist(
    db_session: Session,
) -> None:
    repository = GenreProviderMappingRepository(
        db_session,
    )

    result = repository.get(
        provider="tmdb",
        media_type="show",
        provider_genre_id=18,
    )

    assert result is None


def test_mapping_distinguishes_media_type(
    db_session: Session,
) -> None:
    genre = Genre(
        name="Drama",
        slug="drama",
    )

    db_session.add(genre)
    db_session.flush()

    repository = GenreProviderMappingRepository(
        db_session,
    )

    show_mapping = repository.add(
        GenreProviderMapping(
            genre_id=genre.id,
            provider="tmdb",
            media_type="show",
            provider_genre_id=18,
        )
    )

    movie_mapping = repository.add(
        GenreProviderMapping(
            genre_id=genre.id,
            provider="tmdb",
            media_type="movie",
            provider_genre_id=18,
        )
    )

    show_result = repository.get(
        provider="tmdb",
        media_type="show",
        provider_genre_id=18,
    )

    movie_result = repository.get(
        provider="tmdb",
        media_type="movie",
        provider_genre_id=18,
    )

    assert show_result is show_mapping
    assert movie_result is movie_mapping

    assert show_result.id != movie_result.id

    assert show_result.genre_id == movie_result.genre_id == genre.id


def test_duplicate_provider_mapping_is_rejected(
    db_session: Session,
) -> None:
    genre = Genre(
        name="Drama",
        slug="drama",
    )

    db_session.add(genre)
    db_session.flush()

    repository = GenreProviderMappingRepository(
        db_session,
    )

    repository.add(
        GenreProviderMapping(
            genre_id=genre.id,
            provider="tmdb",
            media_type="show",
            provider_genre_id=18,
        )
    )

    with pytest.raises(IntegrityError):
        repository.add(
            GenreProviderMapping(
                genre_id=genre.id,
                provider="tmdb",
                media_type="show",
                provider_genre_id=18,
            )
        )
