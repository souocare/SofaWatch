from datetime import date

import pytest
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.models.episode import Episode
from app.models.season import Season
from app.models.show import Show
from app.repositories.episode import EpisodeRepository


def make_show(
    *,
    tmdb_id: int = 95396,
    title: str = "Severance",
) -> Show:
    """Create a TV series for repository tests."""

    return Show(
        tmdb_id=tmdb_id,
        title=title,
        original_title=title,
        original_language="en",
        metadata_language="en-US",
    )


def make_season(
    *,
    show_id,
    tmdb_id: int = 134792,
    season_number: int = 1,
    title: str = "Season 1",
) -> Season:
    """Create a TV season for repository tests."""

    return Season(
        show_id=show_id,
        tmdb_id=tmdb_id,
        season_number=season_number,
        title=title,
        overview=None,
        air_date=None,
        episode_count=9,
        vote_average=8.4,
    )


def make_episode(
    *,
    season_id,
    tmdb_id: int = 4023112,
    episode_number: int = 1,
    title: str = "Good News About Hell",
    air_date: date | None = date(2022, 2, 18),
) -> Episode:
    """Create a TV episode for repository tests."""

    return Episode(
        season_id=season_id,
        tmdb_id=tmdb_id,
        episode_number=episode_number,
        title=title,
        overview="Episode overview.",
        runtime=57,
        vote_average=8.1,
        vote_count=42,
        tmdb_still_path="/episode.jpg",
        local_still_path=None,
        air_date=air_date,
    )


def persist_show(
    db_session: Session,
    *,
    tmdb_id: int = 95396,
    title: str = "Severance",
) -> Show:
    """Create and persist a TV series."""

    show = make_show(
        tmdb_id=tmdb_id,
        title=title,
    )

    db_session.add(show)
    db_session.commit()
    db_session.refresh(show)

    return show


def persist_season(
    db_session: Session,
    *,
    show: Show,
    tmdb_id: int = 134792,
    season_number: int = 1,
    title: str = "Season 1",
) -> Season:
    """Create and persist a TV season."""

    season = make_season(
        show_id=show.id,
        tmdb_id=tmdb_id,
        season_number=season_number,
        title=title,
    )

    db_session.add(season)
    db_session.commit()
    db_session.refresh(season)

    return season


def test_add_persists_episode(
    db_session: Session,
) -> None:
    """Persist an episode added through the repository."""

    show = persist_show(db_session)
    season = persist_season(
        db_session,
        show=show,
    )

    repository = EpisodeRepository(db_session)

    episode = make_episode(
        season_id=season.id,
    )

    repository.add(episode)

    db_session.commit()
    db_session.refresh(episode)

    assert episode.id is not None
    assert episode.season_id == season.id
    assert episode.tmdb_id == 4023112
    assert episode.episode_number == 1
    assert episode.title == "Good News About Hell"


def test_get_by_id_returns_episode(
    db_session: Session,
) -> None:
    """Return an episode by its internal identifier."""

    show = persist_show(db_session)
    season = persist_season(
        db_session,
        show=show,
    )

    episode = make_episode(
        season_id=season.id,
    )

    db_session.add(episode)
    db_session.commit()
    db_session.refresh(episode)

    repository = EpisodeRepository(db_session)

    result = repository.get_by_id(
        episode.id,
    )

    assert result is not None
    assert result.id == episode.id
    assert result.tmdb_id == episode.tmdb_id


def test_get_by_id_returns_none_when_missing(
    db_session: Session,
) -> None:
    """Return None when an internal episode identifier does not exist."""

    from uuid import uuid4

    repository = EpisodeRepository(db_session)

    result = repository.get_by_id(
        uuid4(),
    )

    assert result is None


def test_get_by_tmdb_id_returns_episode(
    db_session: Session,
) -> None:
    """Return an episode by its TMDB identifier."""

    show = persist_show(db_session)
    season = persist_season(
        db_session,
        show=show,
    )

    episode = make_episode(
        season_id=season.id,
        tmdb_id=4023112,
    )

    db_session.add(episode)
    db_session.commit()

    repository = EpisodeRepository(db_session)

    result = repository.get_by_tmdb_id(
        4023112,
    )

    assert result is not None
    assert result.id == episode.id
    assert result.tmdb_id == 4023112


def test_get_by_tmdb_id_returns_none_when_missing(
    db_session: Session,
) -> None:
    """Return None when a TMDB episode identifier does not exist."""

    repository = EpisodeRepository(db_session)

    result = repository.get_by_tmdb_id(
        999999999,
    )

    assert result is None


def test_get_by_number_returns_episode(
    db_session: Session,
) -> None:
    """Return an episode by season and episode number."""

    show = persist_show(db_session)
    season = persist_season(
        db_session,
        show=show,
    )

    episode = make_episode(
        season_id=season.id,
        episode_number=3,
    )

    db_session.add(episode)
    db_session.commit()

    repository = EpisodeRepository(db_session)

    result = repository.get_by_number(
        season_id=season.id,
        episode_number=3,
    )

    assert result is not None
    assert result.id == episode.id
    assert result.episode_number == 3


def test_get_by_number_returns_none_when_missing(
    db_session: Session,
) -> None:
    """Return None when the requested episode number does not exist."""

    show = persist_show(db_session)
    season = persist_season(
        db_session,
        show=show,
    )

    repository = EpisodeRepository(db_session)

    result = repository.get_by_number(
        season_id=season.id,
        episode_number=10,
    )

    assert result is None


def test_get_by_number_isolated_between_seasons(
    db_session: Session,
) -> None:
    """Match an episode number only within the requested season."""

    show = persist_show(db_session)

    first_season = persist_season(
        db_session,
        show=show,
        tmdb_id=1001,
        season_number=1,
        title="Season 1",
    )

    second_season = persist_season(
        db_session,
        show=show,
        tmdb_id=1002,
        season_number=2,
        title="Season 2",
    )

    first_episode = make_episode(
        season_id=first_season.id,
        tmdb_id=2001,
        episode_number=1,
        title="Season 1 Episode 1",
    )

    second_episode = make_episode(
        season_id=second_season.id,
        tmdb_id=2002,
        episode_number=1,
        title="Season 2 Episode 1",
    )

    db_session.add_all(
        [
            first_episode,
            second_episode,
        ]
    )
    db_session.commit()

    repository = EpisodeRepository(db_session)

    result = repository.get_by_number(
        season_id=second_season.id,
        episode_number=1,
    )

    assert result is not None
    assert result.id == second_episode.id
    assert result.id != first_episode.id
    assert result.title == "Season 2 Episode 1"


def test_list_by_season_id_returns_empty_list(
    db_session: Session,
) -> None:
    """Return an empty list when a season has no episodes."""

    show = persist_show(db_session)
    season = persist_season(
        db_session,
        show=show,
    )

    repository = EpisodeRepository(db_session)

    result = repository.list_by_season_id(
        season.id,
    )

    assert result == []


def test_list_by_season_id_returns_episodes(
    db_session: Session,
) -> None:
    """Return all episodes belonging to a season."""

    show = persist_show(db_session)
    season = persist_season(
        db_session,
        show=show,
    )

    episodes = [
        make_episode(
            season_id=season.id,
            tmdb_id=2001,
            episode_number=1,
            title="Episode 1",
        ),
        make_episode(
            season_id=season.id,
            tmdb_id=2002,
            episode_number=2,
            title="Episode 2",
        ),
    ]

    db_session.add_all(episodes)
    db_session.commit()

    repository = EpisodeRepository(db_session)

    result = repository.list_by_season_id(
        season.id,
    )

    assert len(result) == 2
    assert [episode.title for episode in result] == [
        "Episode 1",
        "Episode 2",
    ]


def test_list_by_season_id_orders_by_episode_number(
    db_session: Session,
) -> None:
    """Order episodes by episode number in ascending order."""

    show = persist_show(db_session)
    season = persist_season(
        db_session,
        show=show,
    )

    db_session.add_all(
        [
            make_episode(
                season_id=season.id,
                tmdb_id=2003,
                episode_number=3,
                title="Episode 3",
            ),
            make_episode(
                season_id=season.id,
                tmdb_id=2001,
                episode_number=1,
                title="Episode 1",
            ),
            make_episode(
                season_id=season.id,
                tmdb_id=2002,
                episode_number=2,
                title="Episode 2",
            ),
        ]
    )
    db_session.commit()

    repository = EpisodeRepository(db_session)

    result = repository.list_by_season_id(
        season.id,
    )

    assert [episode.episode_number for episode in result] == [
        1,
        2,
        3,
    ]


def test_list_by_season_id_only_returns_requested_season(
    db_session: Session,
) -> None:
    """Do not return episodes belonging to another season."""

    show = persist_show(db_session)

    first_season = persist_season(
        db_session,
        show=show,
        tmdb_id=1001,
        season_number=1,
    )
    second_season = persist_season(
        db_session,
        show=show,
        tmdb_id=1002,
        season_number=2,
    )

    db_session.add_all(
        [
            make_episode(
                season_id=first_season.id,
                tmdb_id=2001,
                episode_number=1,
                title="First season episode",
            ),
            make_episode(
                season_id=second_season.id,
                tmdb_id=3001,
                episode_number=1,
                title="Second season episode",
            ),
        ]
    )
    db_session.commit()

    repository = EpisodeRepository(db_session)

    result = repository.list_by_season_id(
        first_season.id,
    )

    assert len(result) == 1
    assert result[0].title == "First season episode"
    assert result[0].season_id == first_season.id


def test_tmdb_id_must_be_unique(
    db_session: Session,
) -> None:
    """Reject duplicate TMDB episode identifiers."""

    show = persist_show(db_session)

    first_season = persist_season(
        db_session,
        show=show,
        tmdb_id=1001,
        season_number=1,
    )
    second_season = persist_season(
        db_session,
        show=show,
        tmdb_id=1002,
        season_number=2,
    )

    db_session.add(
        make_episode(
            season_id=first_season.id,
            tmdb_id=2001,
            episode_number=1,
        )
    )
    db_session.commit()

    db_session.add(
        make_episode(
            season_id=second_season.id,
            tmdb_id=2001,
            episode_number=1,
        )
    )

    with pytest.raises(IntegrityError):
        db_session.commit()

    db_session.rollback()


def test_episode_number_must_be_unique_within_season(
    db_session: Session,
) -> None:
    """Reject duplicate episode numbers within the same season."""

    show = persist_show(db_session)
    season = persist_season(
        db_session,
        show=show,
    )

    db_session.add(
        make_episode(
            season_id=season.id,
            tmdb_id=2001,
            episode_number=1,
        )
    )
    db_session.commit()

    db_session.add(
        make_episode(
            season_id=season.id,
            tmdb_id=2002,
            episode_number=1,
        )
    )

    with pytest.raises(IntegrityError):
        db_session.commit()

    db_session.rollback()


def test_episode_number_can_repeat_across_seasons(
    db_session: Session,
) -> None:
    """Allow the same episode number in different seasons."""

    show = persist_show(db_session)

    first_season = persist_season(
        db_session,
        show=show,
        tmdb_id=1001,
        season_number=1,
    )
    second_season = persist_season(
        db_session,
        show=show,
        tmdb_id=1002,
        season_number=2,
    )

    db_session.add_all(
        [
            make_episode(
                season_id=first_season.id,
                tmdb_id=2001,
                episode_number=1,
            ),
            make_episode(
                season_id=second_season.id,
                tmdb_id=2002,
                episode_number=1,
            ),
        ]
    )

    db_session.commit()


@pytest.mark.parametrize(
    ("field", "value"),
    [
        ("episode_number", -1),
        ("runtime", -1),
        ("vote_average", -0.1),
        ("vote_average", 10.1),
        ("vote_count", -1),
    ],
)
def test_episode_rejects_invalid_numeric_values(
    db_session: Session,
    field: str,
    value: int | float,
) -> None:
    """Reject episode metadata outside the database constraints."""

    show = persist_show(db_session)
    season = persist_season(
        db_session,
        show=show,
    )

    episode = make_episode(
        season_id=season.id,
    )

    setattr(
        episode,
        field,
        value,
    )

    db_session.add(episode)

    with pytest.raises(IntegrityError):
        db_session.commit()

    db_session.rollback()


def test_episode_allows_missing_runtime(
    db_session: Session,
) -> None:
    """Allow episodes whose runtime is unknown."""

    show = persist_show(db_session)
    season = persist_season(
        db_session,
        show=show,
    )

    episode = make_episode(
        season_id=season.id,
    )
    episode.runtime = None

    db_session.add(episode)
    db_session.commit()
    db_session.refresh(episode)

    assert episode.runtime is None


def test_count_aired_by_season_id_counts_only_aired_episodes(
    db_session: Session,
) -> None:
    """Count only episodes aired on or before the requested date."""

    show = persist_show(db_session)

    season = persist_season(
        db_session,
        show=show,
    )

    db_session.add_all(
        [
            make_episode(
                season_id=season.id,
                tmdb_id=1001,
                episode_number=1,
                air_date=date(2026, 7, 1),
            ),
            make_episode(
                season_id=season.id,
                tmdb_id=1002,
                episode_number=2,
                air_date=date(2026, 7, 29),
            ),
            make_episode(
                season_id=season.id,
                tmdb_id=1003,
                episode_number=3,
                air_date=date(2026, 8, 1),
            ),
            make_episode(
                season_id=season.id,
                tmdb_id=1004,
                episode_number=4,
                air_date=None,
            ),
        ]
    )

    db_session.commit()

    repository = EpisodeRepository(db_session)

    result = repository.count_aired_by_season_id(
        season.id,
        as_of=date(2026, 7, 29),
    )

    assert result == 2


def test_count_regular_by_show_id_excludes_specials(
    db_session: Session,
) -> None:
    """Exclude season zero from show-level episode totals."""

    show = persist_show(db_session)

    specials = persist_season(
        db_session,
        show=show,
        tmdb_id=1000,
        season_number=0,
        title="Specials",
    )

    regular = persist_season(
        db_session,
        show=show,
        tmdb_id=1001,
        season_number=1,
        title="Season 1",
    )

    db_session.add_all(
        [
            make_episode(
                season_id=specials.id,
                tmdb_id=2001,
                episode_number=1,
            ),
            make_episode(
                season_id=regular.id,
                tmdb_id=2101,
                episode_number=1,
            ),
            make_episode(
                season_id=regular.id,
                tmdb_id=2102,
                episode_number=2,
            ),
        ]
    )

    db_session.commit()

    repository = EpisodeRepository(db_session)

    assert (
        repository.count_regular_by_show_id(
            show.id,
        )
        == 2
    )


def test_count_aired_by_show_id_excludes_future_unknown_and_specials(
    db_session: Session,
) -> None:
    """Count only aired regular episodes at show level."""

    show = persist_show(db_session)

    specials = persist_season(
        db_session,
        show=show,
        tmdb_id=1000,
        season_number=0,
        title="Specials",
    )

    regular = persist_season(
        db_session,
        show=show,
        tmdb_id=1001,
        season_number=1,
        title="Season 1",
    )

    db_session.add_all(
        [
            make_episode(
                season_id=specials.id,
                tmdb_id=2001,
                episode_number=1,
                air_date=date(2026, 7, 1),
            ),
            make_episode(
                season_id=regular.id,
                tmdb_id=2101,
                episode_number=1,
                air_date=date(2026, 7, 1),
            ),
            make_episode(
                season_id=regular.id,
                tmdb_id=2102,
                episode_number=2,
                air_date=date(2026, 8, 1),
            ),
            make_episode(
                season_id=regular.id,
                tmdb_id=2103,
                episode_number=3,
                air_date=None,
            ),
        ]
    )

    db_session.commit()

    repository = EpisodeRepository(db_session)

    assert (
        repository.count_aired_by_show_id(
            show.id,
            as_of=date(2026, 7, 29),
        )
        == 1
    )

def test_get_counts_by_show_id_groups_episode_counts_by_season(
    db_session: Session,
) -> None:
    """Return total and aired Episode counts grouped by Season."""

    show = persist_show(
        db_session,
    )

    first_season = persist_season(
        db_session,
        show=show,
        tmdb_id=1001,
        season_number=1,
        title="Season 1",
    )

    second_season = persist_season(
        db_session,
        show=show,
        tmdb_id=1002,
        season_number=2,
        title="Season 2",
    )

    empty_season = persist_season(
        db_session,
        show=show,
        tmdb_id=1003,
        season_number=3,
        title="Season 3",
    )

    db_session.add_all(
        [
            make_episode(
                season_id=first_season.id,
                tmdb_id=2001,
                episode_number=1,
                air_date=date(2026, 7, 1),
            ),
            make_episode(
                season_id=first_season.id,
                tmdb_id=2002,
                episode_number=2,
                air_date=date(2026, 8, 20),
            ),
            make_episode(
                season_id=first_season.id,
                tmdb_id=2003,
                episode_number=3,
                air_date=None,
            ),
            make_episode(
                season_id=second_season.id,
                tmdb_id=3001,
                episode_number=1,
                air_date=date(2026, 7, 15),
            ),
            make_episode(
                season_id=second_season.id,
                tmdb_id=3002,
                episode_number=2,
                air_date=date(2026, 7, 22),
            ),
        ]
    )

    db_session.commit()

    repository = EpisodeRepository(
        db_session,
    )

    result = repository.get_counts_by_show_id(
        show.id,
        as_of=date(2026, 8, 10),
    )

    assert result[first_season.id] == (3, 1)
    assert result[second_season.id] == (2, 2)

    # Seasons without locally stored Episodes do not need a row.
    # The service treats a missing entry as (0, 0).
    assert empty_season.id not in result


def test_get_counts_by_show_id_does_not_include_another_show(
    db_session: Session,
) -> None:
    """Do not include Episode counts belonging to another TV series."""

    first_show = persist_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    second_show = persist_show(
        db_session,
        tmdb_id=1620,
        title="CSI",
    )

    first_season = persist_season(
        db_session,
        show=first_show,
        tmdb_id=1001,
        season_number=1,
    )

    second_season = persist_season(
        db_session,
        show=second_show,
        tmdb_id=1002,
        season_number=1,
    )

    db_session.add_all(
        [
            make_episode(
                season_id=first_season.id,
                tmdb_id=2001,
                episode_number=1,
                air_date=date(2026, 7, 1),
            ),
            make_episode(
                season_id=second_season.id,
                tmdb_id=3001,
                episode_number=1,
                air_date=date(2026, 7, 1),
            ),
        ]
    )

    db_session.commit()

    repository = EpisodeRepository(
        db_session,
    )

    result = repository.get_counts_by_show_id(
        first_show.id,
        as_of=date(2026, 8, 10),
    )

    assert result == {
        first_season.id: (1, 1),
    }


def test_get_aired_counts_by_show_ids_groups_counts_by_show(
    db_session: Session,
) -> None:
    """Return aired regular Episode counts for multiple Shows in one query."""

    first_show = persist_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    second_show = persist_show(
        db_session,
        tmdb_id=100088,
        title="The Last of Us",
    )

    first_season = persist_season(
        db_session,
        show=first_show,
        tmdb_id=1001,
        season_number=1,
        title="Season 1",
    )

    second_season = persist_season(
        db_session,
        show=second_show,
        tmdb_id=2001,
        season_number=1,
        title="Season 1",
    )

    db_session.add_all(
        [
            make_episode(
                season_id=first_season.id,
                tmdb_id=3001,
                episode_number=1,
                air_date=date(2026, 7, 1),
            ),
            make_episode(
                season_id=first_season.id,
                tmdb_id=3002,
                episode_number=2,
                air_date=date(2026, 7, 8),
            ),
            make_episode(
                season_id=second_season.id,
                tmdb_id=4001,
                episode_number=1,
                air_date=date(2026, 7, 5),
            ),
        ]
    )

    db_session.commit()

    repository = EpisodeRepository(db_session)

    result = repository.get_aired_counts_by_show_ids(
        show_ids=[
            first_show.id,
            second_show.id,
        ],
        as_of=date(2026, 8, 13),
    )

    assert result == {
        first_show.id: 2,
        second_show.id: 1,
    }


def test_get_aired_counts_by_show_ids_excludes_future_unknown_and_specials(
    db_session: Session,
) -> None:
    """Count only aired regular Episodes for the requested Shows."""

    show = persist_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    specials = persist_season(
        db_session,
        show=show,
        tmdb_id=1000,
        season_number=0,
        title="Specials",
    )

    regular = persist_season(
        db_session,
        show=show,
        tmdb_id=1001,
        season_number=1,
        title="Season 1",
    )

    db_session.add_all(
        [
            make_episode(
                season_id=specials.id,
                tmdb_id=2001,
                episode_number=1,
                air_date=date(2026, 7, 1),
            ),
            make_episode(
                season_id=regular.id,
                tmdb_id=2101,
                episode_number=1,
                air_date=date(2026, 7, 1),
            ),
            make_episode(
                season_id=regular.id,
                tmdb_id=2102,
                episode_number=2,
                air_date=date(2026, 8, 20),
            ),
            make_episode(
                season_id=regular.id,
                tmdb_id=2103,
                episode_number=3,
                air_date=None,
            ),
        ]
    )

    db_session.commit()

    repository = EpisodeRepository(db_session)

    result = repository.get_aired_counts_by_show_ids(
        show_ids=[show.id],
        as_of=date(2026, 8, 13),
    )

    assert result == {
        show.id: 1,
    }


def test_get_aired_counts_by_show_ids_returns_empty_for_empty_input(
    db_session: Session,
) -> None:
    """Avoid querying Episode counts when no Shows are requested."""

    repository = EpisodeRepository(db_session)

    result = repository.get_aired_counts_by_show_ids(
        show_ids=[],
        as_of=date(2026, 8, 13),
    )

    assert result == {}

def test_list_regular_for_shows_between_returns_inclusive_date_range(
    db_session: Session,
) -> None:
    """Return regular Episodes whose air date falls inside the range."""

    show = persist_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    season = persist_season(
        db_session,
        show=show,
        tmdb_id=1001,
        season_number=1,
        title="Season 1",
    )

    before = make_episode(
        season_id=season.id,
        tmdb_id=2101,
        episode_number=1,
        air_date=date(2026, 8, 9),
    )

    first = make_episode(
        season_id=season.id,
        tmdb_id=2102,
        episode_number=2,
        air_date=date(2026, 8, 10),
    )

    second = make_episode(
        season_id=season.id,
        tmdb_id=2103,
        episode_number=3,
        air_date=date(2026, 8, 15),
    )

    after = make_episode(
        season_id=season.id,
        tmdb_id=2104,
        episode_number=4,
        air_date=date(2026, 8, 16),
    )

    db_session.add_all([
        before,
        first,
        second,
        after,
    ])
    db_session.commit()

    repository = EpisodeRepository(db_session)

    result = repository.list_regular_for_shows_between(
        show_ids=[show.id],
        from_date=date(2026, 8, 10),
        to_date=date(2026, 8, 15),
    )

    assert [item.episode.id for item in result] == [
        first.id,
        second.id,
    ]

    assert all(item.show_id == show.id for item in result)
    assert all(item.season_number == 1 for item in result)


def test_list_regular_for_shows_between_returns_all_known_future_episodes(
    db_session: Session,
) -> None:
    """Omitting the end date returns every known Episode from the start date."""

    show = persist_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    season = persist_season(
        db_session,
        show=show,
        tmdb_id=1001,
        season_number=1,
        title="Season 1",
    )

    first = make_episode(
        season_id=season.id,
        tmdb_id=2101,
        episode_number=1,
        air_date=date(2026, 8, 15),
    )

    second = make_episode(
        season_id=season.id,
        tmdb_id=2102,
        episode_number=2,
        air_date=date(2026, 8, 22),
    )

    db_session.add_all([
        first,
        second,
    ])
    db_session.commit()

    repository = EpisodeRepository(db_session)

    result = repository.list_regular_for_shows_between(
        show_ids=[show.id],
        from_date=date(2026, 8, 15),
    )

    assert [item.episode.id for item in result] == [
        first.id,
        second.id,
    ]


def test_list_regular_for_shows_between_excludes_specials_and_unknown_dates(
    db_session: Session,
) -> None:
    """Exclude Specials and Episodes without a known air date."""

    show = persist_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    specials = persist_season(
        db_session,
        show=show,
        tmdb_id=1000,
        season_number=0,
        title="Specials",
    )

    regular = persist_season(
        db_session,
        show=show,
        tmdb_id=1001,
        season_number=1,
        title="Season 1",
    )

    special_episode = make_episode(
        season_id=specials.id,
        tmdb_id=2001,
        episode_number=1,
        air_date=date(2026, 8, 16),
    )

    unknown_date = make_episode(
        season_id=regular.id,
        tmdb_id=2101,
        episode_number=1,
        air_date=None,
    )

    valid_episode = make_episode(
        season_id=regular.id,
        tmdb_id=2102,
        episode_number=2,
        air_date=date(2026, 8, 17),
    )

    db_session.add_all([
        special_episode,
        unknown_date,
        valid_episode,
    ])
    db_session.commit()

    repository = EpisodeRepository(db_session)

    result = repository.list_regular_for_shows_between(
        show_ids=[show.id],
        from_date=date(2026, 8, 15),
    )

    assert [item.episode.id for item in result] == [
        valid_episode.id,
    ]

    assert result[0].season_number == 1

def test_list_regular_for_shows_between_excludes_unrequested_shows(
    db_session: Session,
) -> None:
    """Return Episodes only for the requested Shows."""

    requested_show = persist_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    other_show = persist_show(
        db_session,
        tmdb_id=100088,
        title="The Last of Us",
    )

    requested_season = persist_season(
        db_session,
        show=requested_show,
        tmdb_id=1001,
        season_number=1,
        title="Season 1",
    )

    other_season = persist_season(
        db_session,
        show=other_show,
        tmdb_id=2001,
        season_number=1,
        title="Season 1",
    )

    requested_episode = make_episode(
        season_id=requested_season.id,
        tmdb_id=2101,
        episode_number=1,
        air_date=date(2026, 8, 16),
    )

    other_episode = make_episode(
        season_id=other_season.id,
        tmdb_id=3101,
        episode_number=1,
        air_date=date(2026, 8, 16),
    )

    db_session.add_all([
        requested_episode,
        other_episode,
    ])
    db_session.commit()

    repository = EpisodeRepository(db_session)

    result = repository.list_regular_for_shows_between(
        show_ids=[requested_show.id],
        from_date=date(2026, 8, 15),
    )

    assert [item.episode.id for item in result] == [
        requested_episode.id,
    ]

def test_list_regular_for_shows_between_orders_chronologically(
    db_session: Session,
) -> None:
    """Order timeline Episodes by date, Show, Season and Episode number."""

    first_show = persist_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    second_show = persist_show(
        db_session,
        tmdb_id=100088,
        title="The Last of Us",
    )

    first_season = persist_season(
        db_session,
        show=first_show,
        tmdb_id=1001,
        season_number=2,
        title="Season 2",
    )

    second_season = persist_season(
        db_session,
        show=second_show,
        tmdb_id=2001,
        season_number=1,
        title="Season 1",
    )

    later_episode = make_episode(
        season_id=first_season.id,
        tmdb_id=2102,
        episode_number=2,
        air_date=date(2026, 8, 20),
    )

    earlier_episode = make_episode(
        season_id=second_season.id,
        tmdb_id=3101,
        episode_number=1,
        air_date=date(2026, 8, 16),
    )

    db_session.add_all([
        later_episode,
        earlier_episode,
    ])
    db_session.commit()

    repository = EpisodeRepository(db_session)

    result = repository.list_regular_for_shows_between(
        show_ids=[
            first_show.id,
            second_show.id,
        ],
        from_date=date(2026, 8, 15),
    )

    assert [item.episode.id for item in result] == [
        earlier_episode.id,
        later_episode.id,
    ]

def test_list_regular_for_shows_between_returns_empty_for_empty_input(
    db_session: Session,
) -> None:
    """Return no timeline Episodes when no Shows are requested."""

    repository = EpisodeRepository(db_session)

    result = repository.list_regular_for_shows_between(
        show_ids=[],
        from_date=date(2026, 8, 15),
    )

    assert result == []