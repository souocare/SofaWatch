from datetime import date

import pytest
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.models.season import Season
from app.models.show import Show
from app.repositories.season import SeasonRepository
from app.repositories.show import ShowRepository


def make_show(
    *,
    tmdb_id: int,
    title: str,
) -> Show:
    """Create a TV series model suitable for repository tests."""

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
        number_of_seasons=2,
        number_of_episodes=20,
        popularity=10.0,
        vote_average=8.0,
        vote_count=100,
        metadata_language="en-US",
    )


def make_season(
    *,
    show_id,
    tmdb_id: int,
    season_number: int,
    title: str,
) -> Season:
    """Create a TV season model suitable for repository tests."""

    return Season(
        show_id=show_id,
        tmdb_id=tmdb_id,
        season_number=season_number,
        title=title,
        overview=f"Overview for {title}.",
        air_date=date(2024, 1, 1),
        episode_count=10,
        vote_average=8.0,
        tmdb_poster_path=f"/season-{season_number}.jpg",
        local_poster_path=None,
    )


def persist_show(
    db_session: Session,
    *,
    tmdb_id: int = 1399,
    title: str = "Game of Thrones",
) -> Show:
    """Create and persist a TV series required by season tests."""

    repository = ShowRepository(db_session)

    return repository.add(
        make_show(
            tmdb_id=tmdb_id,
            title=title,
        )
    )


def test_add_persists_season(
    db_session: Session,
) -> None:
    show = persist_show(db_session)
    repository = SeasonRepository(db_session)

    season = make_season(
        show_id=show.id,
        tmdb_id=3624,
        season_number=1,
        title="Season 1",
    )

    result = repository.add(season)

    assert result is season
    assert season.id is not None

    persisted_season = db_session.get(
        Season,
        season.id,
    )

    assert persisted_season is not None
    assert persisted_season.show_id == show.id
    assert persisted_season.tmdb_id == 3624
    assert persisted_season.season_number == 1


def test_get_by_tmdb_id_returns_season(
    db_session: Session,
) -> None:
    show = persist_show(db_session)
    repository = SeasonRepository(db_session)

    season = repository.add(
        make_season(
            show_id=show.id,
            tmdb_id=3624,
            season_number=1,
            title="Season 1",
        )
    )

    result = repository.get_by_tmdb_id(
        show_id=show.id,
        tmdb_id=3624,
    )

    assert result is not None
    assert result.id == season.id
    assert result.title == "Season 1"


def test_get_by_tmdb_id_returns_none_when_season_does_not_exist(
    db_session: Session,
) -> None:
    show = persist_show(db_session)
    repository = SeasonRepository(db_session)

    result = repository.get_by_tmdb_id(
        show_id=show.id,
        tmdb_id=999999,
    )

    assert result is None


def test_get_by_tmdb_id_does_not_return_season_from_another_show(
    db_session: Session,
) -> None:
    first_show = persist_show(
        db_session,
        tmdb_id=1001,
        title="First Show",
    )
    second_show = persist_show(
        db_session,
        tmdb_id=1002,
        title="Second Show",
    )

    repository = SeasonRepository(db_session)

    repository.add(
        make_season(
            show_id=first_show.id,
            tmdb_id=2001,
            season_number=1,
            title="First Show Season",
        )
    )

    result = repository.get_by_tmdb_id(
        show_id=second_show.id,
        tmdb_id=2001,
    )

    assert result is None


def test_get_by_number_returns_season(
    db_session: Session,
) -> None:
    show = persist_show(db_session)
    repository = SeasonRepository(db_session)

    season = repository.add(
        make_season(
            show_id=show.id,
            tmdb_id=3624,
            season_number=1,
            title="Season 1",
        )
    )

    result = repository.get_by_number(
        show_id=show.id,
        season_number=1,
    )

    assert result is not None
    assert result.id == season.id
    assert result.season_number == 1


def test_get_by_number_returns_none_when_season_does_not_exist(
    db_session: Session,
) -> None:
    show = persist_show(db_session)
    repository = SeasonRepository(db_session)

    result = repository.get_by_number(
        show_id=show.id,
        season_number=5,
    )

    assert result is None


def test_get_by_number_does_not_return_season_from_another_show(
    db_session: Session,
) -> None:
    first_show = persist_show(
        db_session,
        tmdb_id=1001,
        title="First Show",
    )
    second_show = persist_show(
        db_session,
        tmdb_id=1002,
        title="Second Show",
    )

    repository = SeasonRepository(db_session)

    repository.add(
        make_season(
            show_id=first_show.id,
            tmdb_id=2001,
            season_number=1,
            title="First Show Season",
        )
    )

    result = repository.get_by_number(
        show_id=second_show.id,
        season_number=1,
    )

    assert result is None


def test_list_by_show_id_returns_empty_list(
    db_session: Session,
) -> None:
    show = persist_show(db_session)
    repository = SeasonRepository(db_session)

    result = repository.list_by_show_id(show.id)

    assert result == []


def test_list_by_show_id_returns_stored_seasons(
    db_session: Session,
) -> None:
    show = persist_show(db_session)
    repository = SeasonRepository(db_session)

    repository.add(
        make_season(
            show_id=show.id,
            tmdb_id=2001,
            season_number=1,
            title="Season 1",
        )
    )
    repository.add(
        make_season(
            show_id=show.id,
            tmdb_id=2002,
            season_number=2,
            title="Season 2",
        )
    )

    result = repository.list_by_show_id(show.id)

    assert len(result) == 2
    assert {season.tmdb_id for season in result} == {
        2001,
        2002,
    }


def test_list_by_show_id_orders_seasons_by_season_number(
    db_session: Session,
) -> None:
    show = persist_show(db_session)
    repository = SeasonRepository(db_session)

    repository.add(
        make_season(
            show_id=show.id,
            tmdb_id=2002,
            season_number=2,
            title="Season 2",
        )
    )
    repository.add(
        make_season(
            show_id=show.id,
            tmdb_id=2000,
            season_number=0,
            title="Specials",
        )
    )
    repository.add(
        make_season(
            show_id=show.id,
            tmdb_id=2001,
            season_number=1,
            title="Season 1",
        )
    )

    result = repository.list_by_show_id(show.id)

    assert [
        season.season_number
        for season in result
    ] == [
        0,
        1,
        2,
    ]


def test_list_by_show_id_only_returns_requested_show_seasons(
    db_session: Session,
) -> None:
    first_show = persist_show(
        db_session,
        tmdb_id=1001,
        title="First Show",
    )
    second_show = persist_show(
        db_session,
        tmdb_id=1002,
        title="Second Show",
    )

    repository = SeasonRepository(db_session)

    repository.add(
        make_season(
            show_id=first_show.id,
            tmdb_id=2001,
            season_number=1,
            title="First Show Season",
        )
    )
    repository.add(
        make_season(
            show_id=second_show.id,
            tmdb_id=3001,
            season_number=1,
            title="Second Show Season",
        )
    )

    result = repository.list_by_show_id(first_show.id)

    assert len(result) == 1
    assert result[0].title == "First Show Season"
    assert result[0].show_id == first_show.id


def test_season_number_must_be_unique_per_show(
    db_session: Session,
) -> None:
    show = persist_show(db_session)
    repository = SeasonRepository(db_session)

    repository.add(
        make_season(
            show_id=show.id,
            tmdb_id=2001,
            season_number=1,
            title="Season 1",
        )
    )

    duplicate = make_season(
        show_id=show.id,
        tmdb_id=2002,
        season_number=1,
        title="Duplicate Season 1",
    )

    with pytest.raises(IntegrityError):
        repository.add(duplicate)

    db_session.rollback()


def test_tmdb_id_must_be_unique(
    db_session: Session,
) -> None:
    show = persist_show(db_session)
    repository = SeasonRepository(db_session)

    repository.add(
        make_season(
            show_id=show.id,
            tmdb_id=2001,
            season_number=1,
            title="Season 1",
        )
    )

    duplicate = make_season(
        show_id=show.id,
        tmdb_id=2001,
        season_number=2,
        title="Season 2",
    )

    with pytest.raises(IntegrityError):
        repository.add(duplicate)

    db_session.rollback()