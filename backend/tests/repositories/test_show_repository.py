from uuid import uuid4

import pytest
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.models.genre import Genre
from app.models.show import Show
from app.repositories.show import ShowRepository


def make_show(
    *,
    tmdb_id: int,
    title: str,
) -> Show:
    return Show(
        tmdb_id=tmdb_id,
        title=title,
        original_title=title,
        overview=f"Overview for {title}.",
        tagline="",
        original_language="en",
        status="Ended",
        show_type="Scripted",
        in_production=False,
        number_of_seasons=1,
        number_of_episodes=10,
        popularity=10.0,
        vote_average=8.0,
        vote_count=100,
        metadata_language="en-US",
    )


def test_add_persists_show(
    db_session: Session,
) -> None:
    repository = ShowRepository(db_session)
    show = make_show(
        tmdb_id=1399,
        title="Game of Thrones",
    )

    result = repository.add(show)

    assert result is show
    assert show.id is not None

    persisted_show = db_session.get(Show, show.id)

    assert persisted_show is not None
    assert persisted_show.tmdb_id == 1399


def test_get_by_id_returns_show(
    db_session: Session,
) -> None:
    repository = ShowRepository(db_session)
    show = repository.add(
        make_show(
            tmdb_id=1399,
            title="Game of Thrones",
        )
    )

    result = repository.get_by_id(show.id)

    assert result is not None
    assert result.id == show.id
    assert result.tmdb_id == 1399


def test_get_by_id_returns_none_when_show_does_not_exist(
    db_session: Session,
) -> None:
    repository = ShowRepository(db_session)

    result = repository.get_by_id(uuid4())

    assert result is None


def test_get_by_tmdb_id_returns_show(
    db_session: Session,
) -> None:
    repository = ShowRepository(db_session)
    show = repository.add(
        make_show(
            tmdb_id=1399,
            title="Game of Thrones",
        )
    )

    result = repository.get_by_tmdb_id(1399)

    assert result is not None
    assert result.id == show.id
    assert result.title == "Game of Thrones"


def test_get_by_tmdb_id_returns_none_when_show_does_not_exist(
    db_session: Session,
) -> None:
    repository = ShowRepository(db_session)

    result = repository.get_by_tmdb_id(999999)

    assert result is None


def test_exists_by_tmdb_id_returns_true(
    db_session: Session,
) -> None:
    repository = ShowRepository(db_session)
    repository.add(
        make_show(
            tmdb_id=1399,
            title="Game of Thrones",
        )
    )

    result = repository.exists_by_tmdb_id(1399)

    assert result is True


def test_exists_by_tmdb_id_returns_false(
    db_session: Session,
) -> None:
    repository = ShowRepository(db_session)

    result = repository.exists_by_tmdb_id(999999)

    assert result is False


def test_list_returns_stored_shows(
    db_session: Session,
) -> None:
    repository = ShowRepository(db_session)

    repository.add(
        make_show(
            tmdb_id=1399,
            title="Game of Thrones",
        )
    )
    repository.add(
        make_show(
            tmdb_id=66732,
            title="Stranger Things",
        )
    )

    result = repository.list()

    assert len(result) == 2
    assert {show.tmdb_id for show in result} == {
        1399,
        66732,
    }


def test_list_orders_shows_by_title(
    db_session: Session,
) -> None:
    repository = ShowRepository(db_session)

    repository.add(
        make_show(
            tmdb_id=2,
            title="Stranger Things",
        )
    )
    repository.add(
        make_show(
            tmdb_id=1,
            title="Breaking Bad",
        )
    )
    repository.add(
        make_show(
            tmdb_id=3,
            title="The Last of Us",
        )
    )

    result = repository.list()

    assert [show.title for show in result] == [
        "Breaking Bad",
        "Stranger Things",
        "The Last of Us",
    ]


def test_list_applies_offset_and_limit(
    db_session: Session,
) -> None:
    repository = ShowRepository(db_session)

    repository.add(
        make_show(
            tmdb_id=1,
            title="Alpha",
        )
    )
    repository.add(
        make_show(
            tmdb_id=2,
            title="Bravo",
        )
    )
    repository.add(
        make_show(
            tmdb_id=3,
            title="Charlie",
        )
    )

    result = repository.list(
        offset=1,
        limit=1,
    )

    assert len(result) == 1
    assert result[0].title == "Bravo"


def test_get_by_id_loads_show_genres(
    db_session: Session,
) -> None:
    repository = ShowRepository(db_session)

    genre = Genre(
        tmdb_id=18,
        name="Drama",
        slug="drama",
    )

    show = make_show(
        tmdb_id=1399,
        title="Game of Thrones",
    )
    show.genres.append(genre)

    repository.add(show)
    db_session.expire_all()

    result = repository.get_by_id(show.id)

    assert result is not None
    assert len(result.genres) == 1
    assert result.genres[0].name == "Drama"


def test_tmdb_id_must_be_unique(
    db_session: Session,
) -> None:
    repository = ShowRepository(db_session)

    repository.add(
        make_show(
            tmdb_id=1399,
            title="Game of Thrones",
        )
    )

    duplicate = make_show(
        tmdb_id=1399,
        title="Duplicate",
    )

    with pytest.raises(IntegrityError):
        repository.add(duplicate)

    db_session.rollback()
