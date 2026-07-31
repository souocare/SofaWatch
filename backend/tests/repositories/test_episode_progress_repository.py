from datetime import UTC, date, datetime

from sqlalchemy.orm import Session

from app.models.episode import Episode
from app.models.episode_progress import EpisodeProgress
from app.models.season import Season
from app.models.show import Show
from app.models.user import User
from app.repositories.episode_progress import EpisodeProgressRepository


def create_user(
    db_session: Session,
    *,
    display_name: str = "Test User",
) -> User:
    """Create and persist a user for progress repository tests."""

    user = User(
        display_name=display_name,
        is_local=False,
    )

    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)

    return user


def create_show(
    db_session: Session,
    *,
    tmdb_id: int,
    title: str,
) -> Show:
    """Create and persist a locally stored TV series."""

    show = Show(
        tmdb_id=tmdb_id,
        title=title,
        original_title=title,
        original_language="en",
        metadata_language="en-US",
    )

    db_session.add(show)
    db_session.commit()
    db_session.refresh(show)

    return show


def create_season(
    db_session: Session,
    *,
    show: Show,
    tmdb_id: int,
    season_number: int,
    title: str,
) -> Season:
    """Create and persist a TV season."""

    season = Season(
        show_id=show.id,
        tmdb_id=tmdb_id,
        season_number=season_number,
        title=title,
        overview=None,
        air_date=None,
        episode_count=0,
        vote_average=0.0,
    )

    db_session.add(season)
    db_session.commit()
    db_session.refresh(season)

    return season


def create_episode(
    db_session: Session,
    *,
    season: Season,
    tmdb_id: int,
    episode_number: int,
    title: str,
    air_date: date | None = None,
) -> Episode:
    """Create and persist a TV episode."""

    episode = Episode(
        season_id=season.id,
        tmdb_id=tmdb_id,
        episode_number=episode_number,
        title=title,
        overview=None,
        runtime=None,
        vote_average=0.0,
        vote_count=0,
        tmdb_still_path=None,
        local_still_path=None,
        air_date=air_date,
    )

    db_session.add(episode)
    db_session.commit()
    db_session.refresh(episode)

    return episode


def create_progress(
    db_session: Session,
    *,
    user: User,
    episode: Episode,
    is_watched: bool,
) -> EpisodeProgress:
    """Create and persist episode viewing progress."""

    progress = EpisodeProgress(
        user_id=user.id,
        episode_id=episode.id,
        is_watched=is_watched,
        watched_at=(datetime.now(UTC) if is_watched else None),
    )

    db_session.add(progress)
    db_session.commit()
    db_session.refresh(progress)

    return progress


def test_add_and_get_episode_progress(
    db_session: Session,
) -> None:
    """Add and retrieve episode viewing progress."""

    user = create_user(db_session)

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    season = create_season(
        db_session,
        show=show,
        tmdb_id=134792,
        season_number=1,
        title="Season 1",
    )

    episode = create_episode(
        db_session,
        season=season,
        tmdb_id=2101,
        episode_number=1,
        title="Episode 1",
    )

    repository = EpisodeProgressRepository(db_session)

    progress = EpisodeProgress(
        user_id=user.id,
        episode_id=episode.id,
        is_watched=True,
        watched_at=datetime.now(UTC),
    )

    repository.add(progress)

    db_session.commit()
    db_session.refresh(progress)

    result = repository.get_by_user_and_episode(
        user_id=user.id,
        episode_id=episode.id,
    )

    assert result is not None
    assert result.id == progress.id
    assert result.user_id == user.id
    assert result.episode_id == episode.id
    assert result.is_watched is True
    assert result.watched_at is not None


def test_get_by_user_and_episode_returns_none_when_missing(
    db_session: Session,
) -> None:
    """Return None when no progress exists for the episode."""

    user = create_user(db_session)

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    season = create_season(
        db_session,
        show=show,
        tmdb_id=134792,
        season_number=1,
        title="Season 1",
    )

    episode = create_episode(
        db_session,
        season=season,
        tmdb_id=2101,
        episode_number=1,
        title="Episode 1",
    )

    repository = EpisodeProgressRepository(db_session)

    result = repository.get_by_user_and_episode(
        user_id=user.id,
        episode_id=episode.id,
    )

    assert result is None


def test_get_by_user_and_episode_is_isolated_by_user(
    db_session: Session,
) -> None:
    """Do not return another user's episode progress."""

    first_user = create_user(
        db_session,
        display_name="First User",
    )
    second_user = create_user(
        db_session,
        display_name="Second User",
    )

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    season = create_season(
        db_session,
        show=show,
        tmdb_id=134792,
        season_number=1,
        title="Season 1",
    )

    episode = create_episode(
        db_session,
        season=season,
        tmdb_id=2101,
        episode_number=1,
        title="Episode 1",
    )

    create_progress(
        db_session,
        user=first_user,
        episode=episode,
        is_watched=True,
    )

    repository = EpisodeProgressRepository(db_session)

    result = repository.get_by_user_and_episode(
        user_id=second_user.id,
        episode_id=episode.id,
    )

    assert result is None


def test_count_watched_for_season(
    db_session: Session,
) -> None:
    """Count watched episodes belonging to a season."""

    user = create_user(db_session)

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    season = create_season(
        db_session,
        show=show,
        tmdb_id=134792,
        season_number=1,
        title="Season 1",
    )

    first_episode = create_episode(
        db_session,
        season=season,
        tmdb_id=2101,
        episode_number=1,
        title="Episode 1",
    )
    second_episode = create_episode(
        db_session,
        season=season,
        tmdb_id=2102,
        episode_number=2,
        title="Episode 2",
    )
    third_episode = create_episode(
        db_session,
        season=season,
        tmdb_id=2103,
        episode_number=3,
        title="Episode 3",
    )

    create_progress(
        db_session,
        user=user,
        episode=first_episode,
        is_watched=True,
    )
    create_progress(
        db_session,
        user=user,
        episode=second_episode,
        is_watched=True,
    )
    create_progress(
        db_session,
        user=user,
        episode=third_episode,
        is_watched=False,
    )

    repository = EpisodeProgressRepository(db_session)

    count = repository.count_watched_for_season(
        user_id=user.id,
        season_id=season.id,
    )

    assert count == 2


def test_count_watched_for_season_ignores_other_users(
    db_session: Session,
) -> None:
    """Count only episodes watched by the requested user."""

    user = create_user(
        db_session,
        display_name="First User",
    )
    other_user = create_user(
        db_session,
        display_name="Second User",
    )

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    season = create_season(
        db_session,
        show=show,
        tmdb_id=134792,
        season_number=1,
        title="Season 1",
    )

    first_episode = create_episode(
        db_session,
        season=season,
        tmdb_id=2101,
        episode_number=1,
        title="Episode 1",
    )
    second_episode = create_episode(
        db_session,
        season=season,
        tmdb_id=2102,
        episode_number=2,
        title="Episode 2",
    )

    create_progress(
        db_session,
        user=user,
        episode=first_episode,
        is_watched=True,
    )
    create_progress(
        db_session,
        user=other_user,
        episode=second_episode,
        is_watched=True,
    )

    repository = EpisodeProgressRepository(db_session)

    count = repository.count_watched_for_season(
        user_id=user.id,
        season_id=season.id,
    )

    assert count == 1


def test_count_watched_for_show_across_seasons(
    db_session: Session,
) -> None:
    """Count watched episodes across every season of a TV series."""

    user = create_user(db_session)

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    first_season = create_season(
        db_session,
        show=show,
        tmdb_id=134792,
        season_number=1,
        title="Season 1",
    )
    second_season = create_season(
        db_session,
        show=show,
        tmdb_id=234792,
        season_number=2,
        title="Season 2",
    )

    first_episode = create_episode(
        db_session,
        season=first_season,
        tmdb_id=2101,
        episode_number=1,
        title="S01E01",
    )
    second_episode = create_episode(
        db_session,
        season=first_season,
        tmdb_id=2102,
        episode_number=2,
        title="S01E02",
    )
    third_episode = create_episode(
        db_session,
        season=second_season,
        tmdb_id=2201,
        episode_number=1,
        title="S02E01",
    )

    create_progress(
        db_session,
        user=user,
        episode=first_episode,
        is_watched=True,
    )
    create_progress(
        db_session,
        user=user,
        episode=second_episode,
        is_watched=False,
    )
    create_progress(
        db_session,
        user=user,
        episode=third_episode,
        is_watched=True,
    )

    repository = EpisodeProgressRepository(db_session)

    count = repository.count_watched_for_show(
        user_id=user.id,
        show_id=show.id,
    )

    assert count == 2


def test_get_next_unwatched_for_show_returns_first_episode_without_progress(
    db_session: Session,
) -> None:
    """Return the first unwatched episode when no progress exists."""

    user = create_user(db_session)

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    season = create_season(
        db_session,
        show=show,
        tmdb_id=134792,
        season_number=1,
        title="Season 1",
    )

    first_episode = create_episode(
        db_session,
        season=season,
        tmdb_id=2101,
        episode_number=1,
        title="Episode 1",
        air_date=date(2026, 7, 1),
    )
    create_episode(
        db_session,
        season=season,
        tmdb_id=2102,
        episode_number=2,
        title="Episode 2",
    )

    repository = EpisodeProgressRepository(db_session)

    result = repository.get_next_unwatched_for_show(
        user_id=user.id,
        show_id=show.id,
        as_of=date(2026, 7, 29),
    )

    assert result is not None
    assert result.id == first_episode.id
    assert result.episode_number == 1


def test_get_next_unwatched_for_show_skips_watched_episodes(
    db_session: Session,
) -> None:
    """Skip watched episodes when finding the next episode."""

    user = create_user(db_session)

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    season = create_season(
        db_session,
        show=show,
        tmdb_id=134792,
        season_number=1,
        title="Season 1",
    )

    first_episode = create_episode(
        db_session,
        season=season,
        tmdb_id=2101,
        episode_number=1,
        title="Episode 1",
        air_date=date(2026, 7, 1),
    )
    second_episode = create_episode(
        db_session,
        season=season,
        tmdb_id=2102,
        episode_number=2,
        title="Episode 2",
        air_date=date(2026, 7, 2),
    )

    create_progress(
        db_session,
        user=user,
        episode=first_episode,
        is_watched=True,
    )

    repository = EpisodeProgressRepository(db_session)

    result = repository.get_next_unwatched_for_show(
        user_id=user.id,
        show_id=show.id,
        as_of=date(2026, 7, 2),
    )

    assert result is not None
    assert result.id == second_episode.id
    assert result.episode_number == 2


def test_get_next_unwatched_for_show_treats_explicit_unwatched_as_unwatched(
    db_session: Session,
) -> None:
    """Return episodes explicitly marked as not watched."""

    user = create_user(db_session)

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    season = create_season(
        db_session,
        show=show,
        tmdb_id=134792,
        season_number=1,
        title="Season 1",
    )

    first_episode = create_episode(
        db_session,
        season=season,
        tmdb_id=2101,
        episode_number=1,
        title="Episode 1",
        air_date=date(2026, 7, 1),
    )

    create_progress(
        db_session,
        user=user,
        episode=first_episode,
        is_watched=False,
    )

    repository = EpisodeProgressRepository(db_session)

    result = repository.get_next_unwatched_for_show(
        user_id=user.id,
        show_id=show.id,
        as_of=date(2026, 7, 1),
    )

    assert result is not None
    assert result.id == first_episode.id


def test_get_next_unwatched_for_show_orders_across_seasons(
    db_session: Session,
) -> None:
    """Move to the next season after the current season is watched."""

    user = create_user(db_session)

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    first_season = create_season(
        db_session,
        show=show,
        tmdb_id=134792,
        season_number=1,
        title="Season 1",
    )
    second_season = create_season(
        db_session,
        show=show,
        tmdb_id=234792,
        season_number=2,
        title="Season 2",
    )

    first_episode = create_episode(
        db_session,
        season=first_season,
        tmdb_id=2101,
        episode_number=1,
        title="S01E01",
        air_date=date(2026, 7, 1),
    )
    second_episode = create_episode(
        db_session,
        season=first_season,
        tmdb_id=2102,
        episode_number=2,
        title="S01E02",
        air_date=date(2026, 7, 2),
    )
    next_episode = create_episode(
        db_session,
        season=second_season,
        tmdb_id=2201,
        episode_number=1,
        title="S02E01",
        air_date=date(2026, 7, 3),
    )

    create_progress(
        db_session,
        user=user,
        episode=first_episode,
        is_watched=True,
    )
    create_progress(
        db_session,
        user=user,
        episode=second_episode,
        is_watched=True,
    )

    repository = EpisodeProgressRepository(db_session)

    result = repository.get_next_unwatched_for_show(
        user_id=user.id,
        show_id=show.id,
        as_of=date(2026, 7, 3),
    )

    assert result is not None
    assert result.id == next_episode.id


def test_get_next_unwatched_for_show_ignores_specials(
    db_session: Session,
) -> None:
    """Exclude season zero when determining the next regular episode."""

    user = create_user(db_session)

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    specials = create_season(
        db_session,
        show=show,
        tmdb_id=1000,
        season_number=0,
        title="Specials",
    )
    first_season = create_season(
        db_session,
        show=show,
        tmdb_id=134792,
        season_number=1,
        title="Season 1",
    )

    create_episode(
        db_session,
        season=specials,
        tmdb_id=2001,
        episode_number=1,
        title="Special 1",
        air_date=date(2026, 7, 1),
    )
    first_regular_episode = create_episode(
        db_session,
        season=first_season,
        tmdb_id=2101,
        episode_number=1,
        title="S01E01",
        air_date=date(2026, 7, 1),
    )

    repository = EpisodeProgressRepository(db_session)

    result = repository.get_next_unwatched_for_show(
        user_id=user.id,
        show_id=show.id,
        as_of=date(2026, 7, 1),
    )

    assert result is not None
    assert result.id == first_regular_episode.id


def test_get_next_unwatched_for_show_returns_none_when_all_are_watched(
    db_session: Session,
) -> None:
    """Return None when every regular episode has been watched."""

    user = create_user(db_session)

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    season = create_season(
        db_session,
        show=show,
        tmdb_id=134792,
        season_number=1,
        title="Season 1",
    )

    episode = create_episode(
        db_session,
        season=season,
        tmdb_id=2101,
        episode_number=1,
        title="Episode 1",
        air_date=date(2026, 7, 1),
    )

    create_progress(
        db_session,
        user=user,
        episode=episode,
        is_watched=True,
    )

    repository = EpisodeProgressRepository(db_session)

    result = repository.get_next_unwatched_for_show(
        user_id=user.id,
        show_id=show.id,
        as_of=date(2026, 7, 1),
    )

    assert result is None

def test_count_watched_for_show_ignores_specials(
    db_session: Session,
) -> None:
    """Exclude watched specials from show-level progress."""

    user = create_user(db_session)

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    specials = create_season(
        db_session,
        show=show,
        tmdb_id=1000,
        season_number=0,
        title="Specials",
    )

    regular = create_season(
        db_session,
        show=show,
        tmdb_id=1001,
        season_number=1,
        title="Season 1",
    )

    special_episode = create_episode(
        db_session,
        season=specials,
        tmdb_id=2001,
        episode_number=1,
        title="Special",
    )

    regular_episode = create_episode(
        db_session,
        season=regular,
        tmdb_id=2101,
        episode_number=1,
        title="Episode 1",
    )

    create_progress(
        db_session,
        user=user,
        episode=special_episode,
        is_watched=True,
    )

    create_progress(
        db_session,
        user=user,
        episode=regular_episode,
        is_watched=True,
    )

    repository = EpisodeProgressRepository(db_session)

    assert repository.count_watched_for_show(
        user_id=user.id,
        show_id=show.id,
    ) == 1


def test_count_watched_aired_for_season(
    db_session: Session,
) -> None:
    """Count only watched episodes already aired in a season."""

    user = create_user(db_session)

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    season = create_season(
        db_session,
        show=show,
        tmdb_id=134792,
        season_number=1,
        title="Season 1",
    )

    aired = create_episode(
        db_session,
        season=season,
        tmdb_id=2101,
        episode_number=1,
        title="Episode 1",
        air_date=date(2026, 7, 1),
    )

    future = create_episode(
        db_session,
        season=season,
        tmdb_id=2102,
        episode_number=2,
        title="Episode 2",
        air_date=date(2026, 8, 1),
    )

    create_progress(
        db_session,
        user=user,
        episode=aired,
        is_watched=True,
    )

    create_progress(
        db_session,
        user=user,
        episode=future,
        is_watched=True,
    )

    repository = EpisodeProgressRepository(db_session)

    assert repository.count_watched_aired_for_season(
        user_id=user.id,
        season_id=season.id,
        as_of=date(2026, 7, 29),
    ) == 1


def test_count_watched_aired_for_show_excludes_specials_and_future(
    db_session: Session,
) -> None:
    """Count only watched aired regular episodes for a show."""

    user = create_user(db_session)

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    specials = create_season(
        db_session,
        show=show,
        tmdb_id=1000,
        season_number=0,
        title="Specials",
    )

    regular = create_season(
        db_session,
        show=show,
        tmdb_id=1001,
        season_number=1,
        title="Season 1",
    )

    special = create_episode(
        db_session,
        season=specials,
        tmdb_id=2001,
        episode_number=1,
        title="Special",
        air_date=date(2026, 7, 1),
    )

    aired = create_episode(
        db_session,
        season=regular,
        tmdb_id=2101,
        episode_number=1,
        title="Episode 1",
        air_date=date(2026, 7, 1),
    )

    future = create_episode(
        db_session,
        season=regular,
        tmdb_id=2102,
        episode_number=2,
        title="Episode 2",
        air_date=date(2026, 8, 1),
    )

    for episode in (
        special,
        aired,
        future,
    ):
        create_progress(
            db_session,
            user=user,
            episode=episode,
            is_watched=True,
        )

    repository = EpisodeProgressRepository(db_session)

    assert repository.count_watched_aired_for_show(
        user_id=user.id,
        show_id=show.id,
        as_of=date(2026, 7, 29),
    ) == 1


def test_get_next_unwatched_for_show_ignores_future_episodes(
    db_session: Session,
) -> None:
    """Do not return an episode that has not aired yet."""

    user = create_user(db_session)

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    season = create_season(
        db_session,
        show=show,
        tmdb_id=134792,
        season_number=1,
        title="Season 1",
    )

    create_episode(
        db_session,
        season=season,
        tmdb_id=2101,
        episode_number=1,
        title="Future Episode",
        air_date=date(2026, 8, 1),
    )

    repository = EpisodeProgressRepository(db_session)

    result = repository.get_next_unwatched_for_show(
        user_id=user.id,
        show_id=show.id,
        as_of=date(2026, 7, 29),
    )

    assert result is None

def test_get_next_unwatched_for_show_ignores_unknown_air_date(
    db_session: Session,
) -> None:
    """Do not return an episode without a known air date."""

    user = create_user(db_session)

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    season = create_season(
        db_session,
        show=show,
        tmdb_id=134792,
        season_number=1,
        title="Season 1",
    )

    create_episode(
        db_session,
        season=season,
        tmdb_id=2101,
        episode_number=1,
        title="Unknown Air Date",
        air_date=None,
    )

    repository = EpisodeProgressRepository(db_session)

    result = repository.get_next_unwatched_for_show(
        user_id=user.id,
        show_id=show.id,
        as_of=date(2026, 7, 29),
    )

    assert result is None

def test_get_next_upcoming_for_show_returns_earliest_future_episode(
    db_session: Session,
) -> None:
    """Return the earliest known future regular episode."""

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    season = create_season(
        db_session,
        show=show,
        tmdb_id=134792,
        season_number=1,
        title="Season 1",
    )

    create_episode(
        db_session,
        season=season,
        tmdb_id=2102,
        episode_number=2,
        title="Later Episode",
        air_date=date(2026, 8, 9),
    )

    expected = create_episode(
        db_session,
        season=season,
        tmdb_id=2101,
        episode_number=1,
        title="Next Episode",
        air_date=date(2026, 8, 2),
    )

    repository = EpisodeProgressRepository(db_session)

    result = repository.get_next_upcoming_for_show(
        show_id=show.id,
        after=date(2026, 7, 29),
    )

    assert result is not None
    assert result.id == expected.id

def test_get_next_upcoming_for_show_ignores_specials_and_unknown_dates(
    db_session: Session,
) -> None:
    """Ignore specials and episodes without known dates."""

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    specials = create_season(
        db_session,
        show=show,
        tmdb_id=1000,
        season_number=0,
        title="Specials",
    )

    regular = create_season(
        db_session,
        show=show,
        tmdb_id=1001,
        season_number=1,
        title="Season 1",
    )

    create_episode(
        db_session,
        season=specials,
        tmdb_id=2001,
        episode_number=1,
        title="Future Special",
        air_date=date(2026, 7, 30),
    )

    create_episode(
        db_session,
        season=regular,
        tmdb_id=2101,
        episode_number=1,
        title="Unknown",
        air_date=None,
    )

    expected = create_episode(
        db_session,
        season=regular,
        tmdb_id=2102,
        episode_number=2,
        title="Regular Episode",
        air_date=date(2026, 8, 2),
    )

    repository = EpisodeProgressRepository(db_session)

    result = repository.get_next_upcoming_for_show(
        show_id=show.id,
        after=date(2026, 7, 29),
    )

    assert result is not None
    assert result.id == expected.id


def test_get_next_upcoming_for_show_returns_none_when_no_future_episode_exists(
    db_session: Session,
) -> None:
    """Return None when no future regular episode is known."""

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    season = create_season(
        db_session,
        show=show,
        tmdb_id=134792,
        season_number=1,
        title="Season 1",
    )

    create_episode(
        db_session,
        season=season,
        tmdb_id=2101,
        episode_number=1,
        title="Already Aired",
        air_date=date(2026, 7, 1),
    )

    repository = EpisodeProgressRepository(db_session)

    result = repository.get_next_upcoming_for_show(
        show_id=show.id,
        after=date(2026, 7, 29),
    )

    assert result is None


