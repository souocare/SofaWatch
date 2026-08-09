from uuid import uuid4

import pytest
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.models.genre import Genre
from app.models.movie import Movie
from app.repositories.movie import MovieRepository


def make_movie(
    *,
    tmdb_id: int,
    title: str,
) -> Movie:
    return Movie(
        tmdb_id=tmdb_id,
        title=title,
        original_title=title,
        overview=f"Overview for {title}.",
        tagline="",
        original_language="en",
        runtime=120,
        status="Released",
        adult=False,
        video=False,
        popularity=10.0,
        vote_average=8.0,
        vote_count=100,
        metadata_language="en-US",
    )


def test_add_persists_movie(
    db_session: Session,
) -> None:
    repository = MovieRepository(db_session)

    movie = make_movie(
        tmdb_id=438631,
        title="Dune",
    )

    result = repository.add(movie)

    assert result is movie
    assert movie.id is not None

    persisted_movie = db_session.get(
        Movie,
        movie.id,
    )

    assert persisted_movie is not None
    assert persisted_movie.tmdb_id == 438631


def test_get_by_id_returns_movie(
    db_session: Session,
) -> None:
    repository = MovieRepository(db_session)

    movie = repository.add(
        make_movie(
            tmdb_id=438631,
            title="Dune",
        )
    )

    result = repository.get_by_id(movie.id)

    assert result is not None
    assert result.id == movie.id
    assert result.tmdb_id == 438631


def test_get_by_id_returns_none_when_movie_does_not_exist(
    db_session: Session,
) -> None:
    repository = MovieRepository(db_session)

    result = repository.get_by_id(
        uuid4(),
    )

    assert result is None


def test_get_by_tmdb_id_returns_movie(
    db_session: Session,
) -> None:
    repository = MovieRepository(db_session)

    movie = repository.add(
        make_movie(
            tmdb_id=438631,
            title="Dune",
        )
    )

    result = repository.get_by_tmdb_id(
        438631,
    )

    assert result is not None
    assert result.id == movie.id
    assert result.title == "Dune"


def test_get_by_tmdb_id_returns_none_when_movie_does_not_exist(
    db_session: Session,
) -> None:
    repository = MovieRepository(db_session)

    result = repository.get_by_tmdb_id(
        999999,
    )

    assert result is None


def test_exists_by_tmdb_id_returns_true(
    db_session: Session,
) -> None:
    repository = MovieRepository(db_session)

    repository.add(
        make_movie(
            tmdb_id=438631,
            title="Dune",
        )
    )

    assert repository.exists_by_tmdb_id(
        438631,
    )


def test_exists_by_tmdb_id_returns_false(
    db_session: Session,
) -> None:
    repository = MovieRepository(db_session)

    assert not repository.exists_by_tmdb_id(
        999999,
    )


def test_get_by_id_loads_movie_genres(
    db_session: Session,
) -> None:
    repository = MovieRepository(db_session)

    genre = Genre(
        name="Science Fiction",
        slug="science-fiction",
    )

    movie = make_movie(
        tmdb_id=438631,
        title="Dune",
    )

    movie.genres.append(genre)

    repository.add(movie)

    db_session.expire_all()

    result = repository.get_by_id(
        movie.id,
    )

    assert result is not None
    assert len(result.genres) == 1
    assert result.genres[0].name == "Science Fiction"


def test_list_all_returns_stored_movies(
    db_session: Session,
) -> None:
    repository = MovieRepository(db_session)

    repository.add(
        make_movie(
            tmdb_id=438631,
            title="Dune",
        )
    )

    repository.add(
        make_movie(
            tmdb_id=603,
            title="The Matrix",
        )
    )

    result = repository.list_all()

    assert len(result) == 2

    assert {movie.tmdb_id for movie in result} == {
        438631,
        603,
    }


def test_tmdb_id_must_be_unique(
    db_session: Session,
) -> None:
    repository = MovieRepository(db_session)

    repository.add(
        make_movie(
            tmdb_id=438631,
            title="Dune",
        )
    )

    duplicate = make_movie(
        tmdb_id=438631,
        title="Duplicate",
    )

    with pytest.raises(IntegrityError):
        repository.add(duplicate)

    db_session.rollback()
