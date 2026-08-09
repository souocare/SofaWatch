from datetime import UTC, date, datetime, timedelta
from types import SimpleNamespace
from unittest.mock import Mock

import pytest
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.config import Settings
from app.models.genre import Genre
from app.models.genre_provider_mapping import GenreProviderMapping
from app.models.movie import Movie
from app.repositories.genre import GenreRepository
from app.repositories.movie import MovieRepository
from app.services.movie_import import MovieImportService
from app.services.tmdb_movie_details import (
    TMDBMovieDetailsService,
)


TMDB_ID = 438631


@pytest.fixture
def movie_details() -> SimpleNamespace:
    """Provide representative TMDB movie metadata."""

    return SimpleNamespace(
        tmdb_id=TMDB_ID,
        title="Dune",
        original_title="Dune",
        overview="Paul Atreides travels to Arrakis.",
        tagline="Beyond fear, destiny awaits.",
        release_date=date(
            2021,
            9,
            15,
        ),
        poster_path="/poster.jpg",
        backdrop_path="/backdrop.jpg",
        original_language="en",
        runtime=155,
        status="Released",
        adult=False,
        video=False,
        popularity=120.5,
        vote_average=7.8,
        vote_count=13000,
        genres=[
            SimpleNamespace(
                tmdb_id=878,
                name="Science Fiction",
            ),
            SimpleNamespace(
                tmdb_id=12,
                name="Adventure",
            ),
        ],
    )


@pytest.fixture
def tmdb_movie_details_service(
    movie_details: SimpleNamespace,
) -> Mock:
    """Provide a mocked TMDB movie details service."""

    service = Mock(
        spec=TMDBMovieDetailsService,
    )

    service.get_details.return_value = (
        movie_details
    )

    return service


@pytest.fixture
def movie_import_service(
    db_session: Session,
    settings: Settings,
    tmdb_movie_details_service: Mock,
) -> MovieImportService:
    """Provide a Movie import service using the test database."""

    return MovieImportService(
        session=db_session,
        settings=settings,
        movie_repository=MovieRepository(
            db_session,
        ),
        genre_repository=GenreRepository(
            db_session,
        ),
        tmdb_movie_details_service=(
            tmdb_movie_details_service
        ),
    )


def test_import_movie_creates_new_movie(
    db_session: Session,
    movie_import_service: MovieImportService,
    tmdb_movie_details_service: Mock,
) -> None:
    """Import a movie that does not yet exist locally."""

    movie = movie_import_service.import_movie(
        tmdb_id=TMDB_ID,
    )

    stored_movie = db_session.scalar(
        select(Movie).where(
            Movie.tmdb_id == TMDB_ID,
        )
    )

    assert stored_movie is not None

    assert movie.id == stored_movie.id
    assert movie.tmdb_id == TMDB_ID
    assert movie.title == "Dune"
    assert movie.original_title == "Dune"

    assert movie.metadata_language == "en-US"
    assert movie.metadata_updated_at is not None

    tmdb_movie_details_service.get_details.assert_called_once_with(
        tmdb_id=TMDB_ID,
        language="en-US",
    )


def test_import_movie_persists_metadata(
    movie_import_service: MovieImportService,
) -> None:
    """Persist movie metadata returned by TMDB."""

    movie = movie_import_service.import_movie(
        tmdb_id=TMDB_ID,
    )

    assert movie.overview == (
        "Paul Atreides travels to Arrakis."
    )

    assert movie.tagline == (
        "Beyond fear, destiny awaits."
    )

    assert movie.release_date == date(
        2021,
        9,
        15,
    )

    assert movie.tmdb_poster_path == "/poster.jpg"
    assert movie.tmdb_backdrop_path == "/backdrop.jpg"

    assert movie.original_language == "en"
    assert movie.runtime == 155
    assert movie.status == "Released"

    assert movie.adult is False
    assert movie.video is False

    assert movie.popularity == 120.5
    assert movie.vote_average == 7.8
    assert movie.vote_count == 13000


def test_import_movie_creates_and_associates_genres(
    db_session: Session,
    movie_import_service: MovieImportService,
) -> None:
    """Create missing genres and associate them with the Movie."""

    movie = movie_import_service.import_movie(
        tmdb_id=TMDB_ID,
    )

    genre_count = db_session.scalar(
        select(func.count()).select_from(
            Genre,
        )
    )

    assert genre_count == 2

    genres_by_name = {
        genre.name: genre
        for genre in movie.genres
    }

    assert set(genres_by_name) == {
        "Science Fiction",
        "Adventure",
    }

    assert (
        genres_by_name[
            "Science Fiction"
        ].slug
        == "science-fiction"
    )

    assert (
        genres_by_name[
            "Adventure"
        ].slug
        == "adventure"
    )

    mappings = list(
        db_session.scalars(
            select(
                GenreProviderMapping,
            ).where(
                GenreProviderMapping.provider
                == "tmdb",
                GenreProviderMapping.media_type
                == "movie",
            )
        ).all()
    )

    mappings_by_provider_id = {
        mapping.provider_genre_id: mapping
        for mapping in mappings
    }

    assert set(
        mappings_by_provider_id
    ) == {
        878,
        12,
    }

    science_fiction_mapping = (
        mappings_by_provider_id[878]
    )

    adventure_mapping = (
        mappings_by_provider_id[12]
    )

    assert (
        science_fiction_mapping.genre_id
        == genres_by_name[
            "Science Fiction"
        ].id
    )

    assert (
        adventure_mapping.genre_id
        == genres_by_name[
            "Adventure"
        ].id
    )

    assert (
        science_fiction_mapping.genre.name
        == "Science Fiction"
    )

    assert (
        adventure_mapping.genre.name
        == "Adventure"
    )


def test_import_movie_does_not_create_duplicate(
    db_session: Session,
    movie_import_service: MovieImportService,
    tmdb_movie_details_service: Mock,
) -> None:
    """Return the existing Movie instead of creating a duplicate."""

    first_movie = (
        movie_import_service.import_movie(
            tmdb_id=TMDB_ID,
        )
    )

    second_movie = (
        movie_import_service.import_movie(
            tmdb_id=TMDB_ID,
        )
    )

    movie_count = db_session.scalar(
        select(func.count()).select_from(
            Movie,
        )
    )

    assert movie_count == 1
    assert first_movie.id == second_movie.id

    tmdb_movie_details_service.get_details.assert_called_once_with(
        tmdb_id=TMDB_ID,
        language="en-US",
    )


def test_import_movie_returns_recent_movie_without_tmdb_request(
    db_session: Session,
    settings: Settings,
    tmdb_movie_details_service: Mock,
) -> None:
    """Avoid refreshing recently imported metadata."""

    existing_movie = Movie(
        tmdb_id=TMDB_ID,
        title="Existing Dune",
        original_title="Dune",
        original_language="en",
        status="Released",
        metadata_language="en-US",
        metadata_updated_at=datetime.now(
            UTC,
        ),
    )

    db_session.add(
        existing_movie,
    )

    db_session.commit()
    db_session.refresh(
        existing_movie,
    )

    service = MovieImportService(
        session=db_session,
        settings=settings,
        movie_repository=MovieRepository(
            db_session,
        ),
        genre_repository=GenreRepository(
            db_session,
        ),
        tmdb_movie_details_service=(
            tmdb_movie_details_service
        ),
    )

    imported_movie = service.import_movie(
        tmdb_id=TMDB_ID,
    )

    assert imported_movie.id == existing_movie.id
    assert imported_movie.title == "Existing Dune"

    tmdb_movie_details_service.get_details.assert_not_called()


def test_import_movie_refreshes_old_metadata(
    db_session: Session,
    settings: Settings,
    tmdb_movie_details_service: Mock,
) -> None:
    """Refresh Movie metadata after the configured TTL."""

    existing_movie = Movie(
        tmdb_id=TMDB_ID,
        title="Old title",
        original_title="Old title",
        original_language="en",
        status="Released",
        metadata_language="en-US",
        metadata_updated_at=(
            datetime.now(UTC)
            - timedelta(
                days=(
                    settings.metadata_refresh_days
                    + 1
                ),
            )
        ),
    )

    db_session.add(
        existing_movie,
    )

    db_session.commit()
    db_session.refresh(
        existing_movie,
    )

    service = MovieImportService(
        session=db_session,
        settings=settings,
        movie_repository=MovieRepository(
            db_session,
        ),
        genre_repository=GenreRepository(
            db_session,
        ),
        tmdb_movie_details_service=(
            tmdb_movie_details_service
        ),
    )

    imported_movie = service.import_movie(
        tmdb_id=TMDB_ID,
    )

    assert imported_movie.id == existing_movie.id
    assert imported_movie.title == "Dune"

    tmdb_movie_details_service.get_details.assert_called_once_with(
        tmdb_id=TMDB_ID,
        language="en-US",
    )


def test_import_movie_force_refreshes_recent_metadata(
    db_session: Session,
    settings: Settings,
    tmdb_movie_details_service: Mock,
) -> None:
    """Refresh recent metadata when explicitly requested."""

    existing_movie = Movie(
        tmdb_id=TMDB_ID,
        title="Existing title",
        original_title="Existing title",
        original_language="en",
        status="Released",
        metadata_language="en-US",
        metadata_updated_at=datetime.now(
            UTC,
        ),
    )

    db_session.add(
        existing_movie,
    )

    db_session.commit()
    db_session.refresh(
        existing_movie,
    )

    service = MovieImportService(
        session=db_session,
        settings=settings,
        movie_repository=MovieRepository(
            db_session,
        ),
        genre_repository=GenreRepository(
            db_session,
        ),
        tmdb_movie_details_service=(
            tmdb_movie_details_service
        ),
    )

    imported_movie = service.import_movie(
        tmdb_id=TMDB_ID,
        force_refresh=True,
    )

    assert imported_movie.id == existing_movie.id
    assert imported_movie.title == "Dune"

    tmdb_movie_details_service.get_details.assert_called_once_with(
        tmdb_id=TMDB_ID,
        language="en-US",
    )


def test_import_movie_forwards_selected_language(
    movie_import_service: MovieImportService,
    tmdb_movie_details_service: Mock,
) -> None:
    """Use the explicitly selected metadata language."""

    movie = movie_import_service.import_movie(
        tmdb_id=TMDB_ID,
        language="pt-PT",
    )

    assert movie.metadata_language == "pt-PT"

    tmdb_movie_details_service.get_details.assert_called_once_with(
        tmdb_id=TMDB_ID,
        language="pt-PT",
    )


def test_import_movie_rolls_back_when_persistence_fails(
    db_session: Session,
    settings: Settings,
    tmdb_movie_details_service: Mock,
) -> None:
    """Rollback Movie and Genre changes when persistence fails."""

    movie_repository = Mock(
        spec=MovieRepository,
    )

    movie_repository.get_by_tmdb_id.return_value = (
        None
    )

    movie_repository.add.side_effect = RuntimeError(
        "Database write failed."
    )

    service = MovieImportService(
        session=db_session,
        settings=settings,
        movie_repository=movie_repository,
        genre_repository=GenreRepository(
            db_session,
        ),
        tmdb_movie_details_service=(
            tmdb_movie_details_service
        ),
    )

    with pytest.raises(
        RuntimeError,
        match="Database write failed",
    ):
        service.import_movie(
            tmdb_id=TMDB_ID,
        )

    movie_count = db_session.scalar(
        select(func.count()).select_from(
            Movie,
        )
    )

    genre_count = db_session.scalar(
        select(func.count()).select_from(
            Genre,
        )
    )

    assert movie_count == 0
    assert genre_count == 0