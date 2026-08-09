from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models import Genre
from app.models.genre_provider_mapping import (
    GenreProviderMapping,
)
from app.repositories.genre import GenreRepository
from app.repositories.genre_provider_mapping import (
    GenreProviderMappingRepository,
)
from app.services.genre_mapping import GenreMappingService


def create_service(
    db_session: Session,
) -> GenreMappingService:
    return GenreMappingService(
        genre_repository=GenreRepository(
            db_session,
        ),
        mapping_repository=GenreProviderMappingRepository(
            db_session,
        ),
    )


def test_resolve_reuses_existing_mapping(
    db_session: Session,
) -> None:
    genre = Genre(
        name="Drama",
        slug="drama",
    )

    db_session.add(genre)
    db_session.flush()

    mapping = GenreProviderMapping(
        genre_id=genre.id,
        provider="tmdb",
        media_type="show",
        provider_genre_id=18,
    )

    db_session.add(mapping)
    db_session.flush()

    service = create_service(
        db_session,
    )

    result = service.resolve(
        provider="tmdb",
        media_type="show",
        provider_genre_id=18,
        name="Drama",
    )

    assert result.id == genre.id

    genre_count = db_session.scalar(
        select(func.count())
        .select_from(Genre)
    )

    mapping_count = db_session.scalar(
        select(func.count())
        .select_from(
            GenreProviderMapping,
        )
    )

    assert genre_count == 1
    assert mapping_count == 1


def test_resolve_reuses_existing_genre_and_creates_mapping(
    db_session: Session,
) -> None:
    genre = Genre(
        name="Drama",
        slug="drama",
    )

    db_session.add(genre)
    db_session.flush()

    service = create_service(
        db_session,
    )

    result = service.resolve(
        provider="tmdb",
        media_type="show",
        provider_genre_id=18,
        name="Drama",
    )

    assert result.id == genre.id

    mapping = db_session.scalar(
        select(
            GenreProviderMapping,
        )
    )

    assert mapping is not None
    assert mapping.genre_id == genre.id
    assert mapping.provider == "tmdb"
    assert mapping.media_type == "show"
    assert mapping.provider_genre_id == 18


def test_resolve_creates_genre_and_mapping(
    db_session: Session,
) -> None:
    service = create_service(
        db_session,
    )

    result = service.resolve(
        provider="tmdb",
        media_type="show",
        provider_genre_id=18,
        name="Drama",
    )

    assert result.id is not None
    assert result.name == "Drama"
    assert result.slug == "drama"

    mapping = db_session.scalar(
        select(
            GenreProviderMapping,
        )
    )

    assert mapping is not None
    assert mapping.genre_id == result.id
    assert mapping.provider == "tmdb"
    assert mapping.media_type == "show"
    assert mapping.provider_genre_id == 18


def test_show_and_movie_mappings_share_same_local_genre(
    db_session: Session,
) -> None:
    service = create_service(
        db_session,
    )

    show_genre = service.resolve(
        provider="tmdb",
        media_type="show",
        provider_genre_id=18,
        name="Drama",
    )

    movie_genre = service.resolve(
        provider="tmdb",
        media_type="movie",
        provider_genre_id=18,
        name="Drama",
    )

    assert show_genre.id == movie_genre.id

    genre_count = db_session.scalar(
        select(func.count())
        .select_from(Genre)
    )

    mappings = list(
        db_session.scalars(
            select(
                GenreProviderMapping,
            ).order_by(
                GenreProviderMapping.media_type,
            )
        ).all()
    )

    assert genre_count == 1
    assert len(mappings) == 2

    assert {
        mapping.media_type
        for mapping in mappings
    } == {
        "show",
        "movie",
    }

    assert all(
        mapping.genre_id == show_genre.id
        for mapping in mappings
    )


def test_different_provider_genres_create_different_local_genres(
    db_session: Session,
) -> None:
    service = create_service(
        db_session,
    )

    drama = service.resolve(
        provider="tmdb",
        media_type="show",
        provider_genre_id=18,
        name="Drama",
    )

    comedy = service.resolve(
        provider="tmdb",
        media_type="show",
        provider_genre_id=35,
        name="Comedy",
    )

    assert drama.id != comedy.id
    assert drama.name == "Drama"
    assert comedy.name == "Comedy"