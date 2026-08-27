from datetime import UTC, date, datetime, timedelta
from uuid import uuid4

import pytest
from sqlalchemy.orm import Session

from app.models.enums import LibraryStatus
from app.models.episode import Episode
from app.models.episode_progress import EpisodeProgress
from app.models.library import LibraryEntry
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


def create_library_entry(
    db_session: Session,
    *,
    user: User,
    show: Show,
    status: LibraryStatus = LibraryStatus.WATCHING,
) -> LibraryEntry:
    """Create and persist a Show library entry for progress repository tests."""

    entry = LibraryEntry(
        user_id=user.id,
        show_id=show.id,
        status=status,
    )

    db_session.add(entry)
    db_session.commit()
    db_session.refresh(entry)

    return entry


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

    assert (
        repository.count_watched_for_show(
            user_id=user.id,
            show_id=show.id,
        )
        == 1
    )


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

    assert (
        repository.count_watched_aired_for_season(
            user_id=user.id,
            season_id=season.id,
            as_of=date(2026, 7, 29),
        )
        == 1
    )


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

    assert (
        repository.count_watched_aired_for_show(
            user_id=user.id,
            show_id=show.id,
            as_of=date(2026, 7, 29),
        )
        == 1
    )


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


def test_get_watched_counts_by_show_id_groups_progress_by_season(
    db_session: Session,
) -> None:
    """Return watched and watched-aired counts grouped by Season."""

    user = create_user(
        db_session,
    )

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    first_season = Season(
        show_id=show.id,
        tmdb_id=1001,
        season_number=1,
        title="Season 1",
    )

    second_season = Season(
        show_id=show.id,
        tmdb_id=1002,
        season_number=2,
        title="Season 2",
    )

    db_session.add_all(
        [
            first_season,
            second_season,
        ]
    )
    db_session.flush()

    aired_watched = Episode(
        season_id=first_season.id,
        tmdb_id=2001,
        episode_number=1,
        title="Episode 1",
        air_date=date(2026, 7, 1),
    )

    future_watched = Episode(
        season_id=first_season.id,
        tmdb_id=2002,
        episode_number=2,
        title="Episode 2",
        air_date=date(2026, 8, 20),
    )

    aired_unwatched = Episode(
        season_id=first_season.id,
        tmdb_id=2003,
        episode_number=3,
        title="Episode 3",
        air_date=date(2026, 7, 15),
    )

    second_season_watched = Episode(
        season_id=second_season.id,
        tmdb_id=3001,
        episode_number=1,
        title="Episode 1",
        air_date=date(2026, 7, 10),
    )

    db_session.add_all(
        [
            aired_watched,
            future_watched,
            aired_unwatched,
            second_season_watched,
        ]
    )
    db_session.flush()

    db_session.add_all(
        [
            EpisodeProgress(
                user_id=user.id,
                episode_id=aired_watched.id,
                is_watched=True,
                watched_at=datetime.now(UTC),
            ),
            EpisodeProgress(
                user_id=user.id,
                episode_id=future_watched.id,
                is_watched=True,
                watched_at=datetime.now(UTC),
            ),
            EpisodeProgress(
                user_id=user.id,
                episode_id=aired_unwatched.id,
                is_watched=False,
                watched_at=None,
            ),
            EpisodeProgress(
                user_id=user.id,
                episode_id=second_season_watched.id,
                is_watched=True,
                watched_at=datetime.now(UTC),
            ),
        ]
    )

    db_session.commit()

    repository = EpisodeProgressRepository(
        db_session,
    )

    result = repository.get_watched_counts_by_show_id(
        user_id=user.id,
        show_id=show.id,
        as_of=date(2026, 8, 10),
    )

    assert result[first_season.id] == (2, 1)
    assert result[second_season.id] == (1, 1)


def test_get_watched_counts_by_show_id_isolated_by_user(
    db_session: Session,
) -> None:
    """Only count watched Episodes belonging to the requested user."""

    first_user = create_user(
        db_session,
    )

    second_user = User(
        display_name="Another User",
    )

    db_session.add(
        second_user,
    )

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    season = create_season(
        db_session,
        show=show,
        tmdb_id=1001,
        season_number=1,
        title="Season 1",
    )

    episode = create_episode(
        db_session,
        season=season,
        tmdb_id=2001,
        episode_number=1,
        title="Episode 1",
        air_date=date(2026, 7, 1),
    )

    episode.air_date = date(2026, 7, 1)

    db_session.add_all(
        [
            EpisodeProgress(
                user_id=first_user.id,
                episode_id=episode.id,
                is_watched=True,
                watched_at=datetime.now(UTC),
            ),
            EpisodeProgress(
                user_id=second_user.id,
                episode_id=episode.id,
                is_watched=True,
                watched_at=datetime.now(UTC),
            ),
        ]
    )

    db_session.commit()

    repository = EpisodeProgressRepository(
        db_session,
    )

    result = repository.get_watched_counts_by_show_id(
        user_id=first_user.id,
        show_id=show.id,
        as_of=date(2026, 8, 10),
    )

    assert result == {
        season.id: (1, 1),
    }


def test_list_by_user_and_season_returns_only_requested_season_progress(
    db_session: Session,
) -> None:
    """Return progress entries only for the requested user and season."""

    user = create_user(db_session)

    other_user = create_user(
        db_session,
        display_name="Other User",
    )

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    season_one = create_season(
        db_session,
        show=show,
        tmdb_id=134792,
        season_number=1,
        title="Season 1",
    )

    season_two = create_season(
        db_session,
        show=show,
        tmdb_id=200001,
        season_number=2,
        title="Season 2",
    )

    episode_one = create_episode(
        db_session,
        season=season_one,
        tmdb_id=2101,
        episode_number=1,
        title="Episode 1",
    )

    episode_two = create_episode(
        db_session,
        season=season_one,
        tmdb_id=2102,
        episode_number=2,
        title="Episode 2",
    )

    episode_other_season = create_episode(
        db_session,
        season=season_two,
        tmdb_id=2201,
        episode_number=1,
        title="Season 2 Episode 1",
    )

    first_progress = create_progress(
        db_session,
        user=user,
        episode=episode_one,
        is_watched=True,
    )

    second_progress = create_progress(
        db_session,
        user=user,
        episode=episode_two,
        is_watched=False,
    )

    create_progress(
        db_session,
        user=user,
        episode=episode_other_season,
        is_watched=True,
    )

    create_progress(
        db_session,
        user=other_user,
        episode=episode_one,
        is_watched=True,
    )

    repository = EpisodeProgressRepository(
        db_session,
    )

    result = repository.list_by_user_and_season(
        user_id=user.id,
        season_id=season_one.id,
    )

    assert result == [
        first_progress,
        second_progress,
    ]


def test_list_next_unwatched_for_shows_returns_next_episode_for_each_show(
    db_session: Session,
) -> None:
    """Return the first aired unwatched regular Episode for each requested Show."""

    user = create_user(db_session)

    first_show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    second_show = create_show(
        db_session,
        tmdb_id=100088,
        title="The Last of Us",
    )

    first_season = create_season(
        db_session,
        show=first_show,
        tmdb_id=134792,
        season_number=1,
        title="Season 1",
    )

    second_season = create_season(
        db_session,
        show=second_show,
        tmdb_id=200001,
        season_number=1,
        title="Season 1",
    )

    first_show_episode_one = create_episode(
        db_session,
        season=first_season,
        tmdb_id=1001,
        episode_number=1,
        title="Episode 1",
        air_date=date(2026, 8, 1),
    )

    first_show_episode_two = create_episode(
        db_session,
        season=first_season,
        tmdb_id=1002,
        episode_number=2,
        title="Episode 2",
        air_date=date(2026, 8, 8),
    )

    second_show_episode_one = create_episode(
        db_session,
        season=second_season,
        tmdb_id=2001,
        episode_number=1,
        title="Episode 1",
        air_date=date(2026, 8, 5),
    )

    create_progress(
        db_session,
        user=user,
        episode=first_show_episode_one,
        is_watched=True,
    )

    repository = EpisodeProgressRepository(
        db_session,
    )

    result = repository.list_next_unwatched_for_shows(
        user_id=user.id,
        show_ids=[
            first_show.id,
            second_show.id,
        ],
        as_of=date(2026, 8, 13),
    )

    assert set(result) == {
        first_show.id,
        second_show.id,
    }

    first_candidate = result[first_show.id]

    assert first_candidate.show_id == first_show.id
    assert first_candidate.episode.id == first_show_episode_two.id
    assert first_candidate.season_number == 1

    second_candidate = result[second_show.id]

    assert second_candidate.show_id == second_show.id
    assert second_candidate.episode.id == second_show_episode_one.id
    assert second_candidate.season_number == 1


def test_list_next_unwatched_for_shows_excludes_fully_watched_show(
    db_session: Session,
) -> None:
    """Do not return a Show when all of its aired Episodes are watched."""

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

    episode_one = create_episode(
        db_session,
        season=season,
        tmdb_id=1001,
        episode_number=1,
        title="Episode 1",
        air_date=date(2026, 8, 1),
    )

    episode_two = create_episode(
        db_session,
        season=season,
        tmdb_id=1002,
        episode_number=2,
        title="Episode 2",
        air_date=date(2026, 8, 8),
    )

    create_progress(
        db_session,
        user=user,
        episode=episode_one,
        is_watched=True,
    )

    create_progress(
        db_session,
        user=user,
        episode=episode_two,
        is_watched=True,
    )

    repository = EpisodeProgressRepository(
        db_session,
    )

    result = repository.list_next_unwatched_for_shows(
        user_id=user.id,
        show_ids=[show.id],
        as_of=date(2026, 8, 13),
    )

    assert result == {}


def test_list_next_unwatched_for_shows_excludes_future_episodes(
    db_session: Session,
) -> None:
    """Do not return Episodes that have not aired yet."""

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
        tmdb_id=1001,
        episode_number=1,
        title="Future Episode",
        air_date=date(2026, 8, 14),
    )

    repository = EpisodeProgressRepository(
        db_session,
    )

    result = repository.list_next_unwatched_for_shows(
        user_id=user.id,
        show_ids=[show.id],
        as_of=date(2026, 8, 13),
    )

    assert result == {}


def test_list_next_unwatched_for_shows_excludes_specials(
    db_session: Session,
) -> None:
    """Do not use Season 0 Episodes as Watch Next candidates."""

    user = create_user(db_session)

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    specials = create_season(
        db_session,
        show=show,
        tmdb_id=134791,
        season_number=0,
        title="Specials",
    )

    create_episode(
        db_session,
        season=specials,
        tmdb_id=999,
        episode_number=1,
        title="Behind the Scenes",
        air_date=date(2026, 8, 1),
    )

    repository = EpisodeProgressRepository(
        db_session,
    )

    result = repository.list_next_unwatched_for_shows(
        user_id=user.id,
        show_ids=[show.id],
        as_of=date(2026, 8, 13),
    )

    assert result == {}


def test_list_last_watched_for_shows_returns_latest_watched_episode(
    db_session: Session,
) -> None:
    """Return the most recently watched Episode for each requested Show."""

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
        tmdb_id=1001,
        episode_number=1,
        title="Episode 1",
        air_date=date(2026, 1, 1),
    )

    second_episode = create_episode(
        db_session,
        season=season,
        tmdb_id=1002,
        episode_number=2,
        title="Episode 2",
        air_date=date(2026, 1, 8),
    )

    first_progress = create_progress(
        db_session,
        user=user,
        episode=first_episode,
        is_watched=True,
    )

    second_progress = create_progress(
        db_session,
        user=user,
        episode=second_episode,
        is_watched=True,
    )

    first_progress.watched_at = datetime(
        2026,
        4,
        1,
        20,
        0,
        tzinfo=UTC,
    )

    second_progress.watched_at = datetime(
        2026,
        6,
        1,
        20,
        0,
        tzinfo=UTC,
    )

    db_session.commit()

    repository = EpisodeProgressRepository(db_session)

    result = repository.list_last_watched_for_shows(
        user_id=user.id,
        show_ids=[show.id],
    )

    assert set(result) == {show.id}

    candidate = result[show.id]

    assert candidate.show_id == show.id
    assert candidate.episode.id == second_episode.id
    assert candidate.season_number == 1
    assert candidate.watched_at.replace(tzinfo=UTC) == datetime(
        2026,
        6,
        1,
        20,
        0,
        tzinfo=UTC,
    )


def test_list_last_watched_for_shows_returns_each_show_independently(
    db_session: Session,
) -> None:
    """Resolve the latest watched Episode independently for each Show."""

    user = create_user(db_session)

    first_show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    second_show = create_show(
        db_session,
        tmdb_id=100088,
        title="The Last of Us",
    )

    first_season = create_season(
        db_session,
        show=first_show,
        tmdb_id=134792,
        season_number=1,
        title="Season 1",
    )

    second_season = create_season(
        db_session,
        show=second_show,
        tmdb_id=200001,
        season_number=1,
        title="Season 1",
    )

    first_episode = create_episode(
        db_session,
        season=first_season,
        tmdb_id=1001,
        episode_number=1,
        title="Episode 1",
    )

    second_episode = create_episode(
        db_session,
        season=second_season,
        tmdb_id=2001,
        episode_number=1,
        title="Episode 1",
    )

    first_progress = create_progress(
        db_session,
        user=user,
        episode=first_episode,
        is_watched=True,
    )

    second_progress = create_progress(
        db_session,
        user=user,
        episode=second_episode,
        is_watched=True,
    )

    first_progress.watched_at = datetime(
        2026,
        4,
        1,
        tzinfo=UTC,
    )

    second_progress.watched_at = datetime(
        2026,
        5,
        1,
        tzinfo=UTC,
    )

    db_session.commit()

    repository = EpisodeProgressRepository(db_session)

    result = repository.list_last_watched_for_shows(
        user_id=user.id,
        show_ids=[
            first_show.id,
            second_show.id,
        ],
    )

    assert set(result) == {
        first_show.id,
        second_show.id,
    }

    assert result[first_show.id].episode.id == first_episode.id
    assert result[second_show.id].episode.id == second_episode.id


def test_list_last_watched_for_shows_excludes_never_started_show(
    db_session: Session,
) -> None:
    """Do not return a Show when the user has never watched an Episode."""

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
        tmdb_id=1001,
        episode_number=1,
        title="Episode 1",
    )

    repository = EpisodeProgressRepository(db_session)

    result = repository.list_last_watched_for_shows(
        user_id=user.id,
        show_ids=[show.id],
    )

    assert result == {}


def test_list_watch_history_returns_watched_episodes_newest_first(
    db_session: Session,
) -> None:
    """Return watched regular Episodes ordered by most recent viewing."""

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
        title="Good News About Hell",
    )

    second_episode = create_episode(
        db_session,
        season=season,
        tmdb_id=2102,
        episode_number=2,
        title="Half Loop",
    )

    db_session.add_all(
        [
            EpisodeProgress(
                user_id=user.id,
                episode_id=first_episode.id,
                is_watched=True,
                watched_at=datetime(
                    2026,
                    7,
                    1,
                    20,
                    0,
                    tzinfo=UTC,
                ),
            ),
            EpisodeProgress(
                user_id=user.id,
                episode_id=second_episode.id,
                is_watched=True,
                watched_at=datetime(
                    2026,
                    8,
                    10,
                    21,
                    0,
                    tzinfo=UTC,
                ),
            ),
        ]
    )

    db_session.commit()

    repository = EpisodeProgressRepository(db_session)

    page = repository.list_watch_history(
        user_id=user.id,
    )

    assert len(page.items) == 2
    assert page.has_more is False

    assert page.items[0].episode.id == second_episode.id
    assert page.items[0].season_number == 1
    assert page.items[0].show.id == show.id
    assert page.items[0].show.tmdb_id == show.tmdb_id
    assert page.items[0].show.title == show.title

    assert page.items[1].episode.id == first_episode.id


def test_list_watch_history_excludes_unwatched_progress(
    db_session: Session,
) -> None:
    """Do not include Episodes currently marked as unwatched."""

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
        title="Good News About Hell",
    )

    db_session.add(
        EpisodeProgress(
            user_id=user.id,
            episode_id=episode.id,
            is_watched=False,
            watched_at=None,
        )
    )

    db_session.commit()

    repository = EpisodeProgressRepository(db_session)

    page = repository.list_watch_history(
        user_id=user.id,
    )

    assert page.items == []
    assert page.has_more is False


def test_list_watch_history_is_isolated_by_user(
    db_session: Session,
) -> None:
    """Return only Watch History belonging to the requested user."""

    user = create_user(
        db_session,
        display_name="First User",
    )

    other_user = create_user(
        db_session,
        display_name="Other User",
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
        title="Good News About Hell",
    )

    second_episode = create_episode(
        db_session,
        season=season,
        tmdb_id=2102,
        episode_number=2,
        title="Half Loop",
    )

    db_session.add_all(
        [
            EpisodeProgress(
                user_id=user.id,
                episode_id=first_episode.id,
                is_watched=True,
                watched_at=datetime.now(UTC),
            ),
            EpisodeProgress(
                user_id=other_user.id,
                episode_id=second_episode.id,
                is_watched=True,
                watched_at=datetime.now(UTC),
            ),
        ]
    )

    db_session.commit()

    repository = EpisodeProgressRepository(db_session)

    page = repository.list_watch_history(
        user_id=user.id,
    )

    assert len(page.items) == 1
    assert page.has_more is False

    assert page.items[0].episode.id == first_episode.id


def test_list_watch_history_excludes_special_seasons(
    db_session: Session,
) -> None:
    """Do not include Specials in the regular Shows Watch History."""

    user = create_user(db_session)

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    special_season = create_season(
        db_session,
        show=show,
        tmdb_id=134790,
        season_number=0,
        title="Specials",
    )

    special_episode = create_episode(
        db_session,
        season=special_season,
        tmdb_id=2101,
        episode_number=1,
        title="Special",
    )

    db_session.add(
        EpisodeProgress(
            user_id=user.id,
            episode_id=special_episode.id,
            is_watched=True,
            watched_at=datetime.now(UTC),
        )
    )

    db_session.commit()

    repository = EpisodeProgressRepository(db_session)

    page = repository.list_watch_history(
        user_id=user.id,
    )

    assert page.items == []
    assert page.has_more is False


def test_list_watch_history_respects_limit(
    db_session: Session,
) -> None:
    """Limit the number of recent Watch History entries returned."""

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

    episodes = [
        create_episode(
            db_session,
            season=season,
            tmdb_id=2200 + index,
            episode_number=index,
            title=f"Episode {index}",
        )
        for index in range(1, 4)
    ]

    for index, episode in enumerate(episodes, start=1):
        db_session.add(
            EpisodeProgress(
                user_id=user.id,
                episode_id=episode.id,
                is_watched=True,
                watched_at=datetime(
                    2026,
                    8,
                    index,
                    tzinfo=UTC,
                ),
            )
        )

    db_session.commit()

    repository = EpisodeProgressRepository(db_session)

    page = repository.list_watch_history(
        user_id=user.id,
        limit=2,
    )

    assert len(page.items) == 2
    assert page.has_more is True

    assert page.items[0].episode.id == episodes[2].id
    assert page.items[1].episode.id == episodes[1].id


def test_list_watch_history_loads_next_page_from_cursor(
    db_session: Session,
) -> None:
    """Continue Watch History from the last item of the previous page."""

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

    episodes = [
        create_episode(
            db_session,
            season=season,
            tmdb_id=2300 + index,
            episode_number=index,
            title=f"Episode {index}",
        )
        for index in range(1, 6)
    ]

    for index, episode in enumerate(
        episodes,
        start=1,
    ):
        db_session.add(
            EpisodeProgress(
                user_id=user.id,
                episode_id=episode.id,
                is_watched=True,
                watched_at=datetime(
                    2026,
                    8,
                    index,
                    20,
                    tzinfo=UTC,
                ),
            )
        )

    db_session.commit()

    repository = EpisodeProgressRepository(
        db_session,
    )

    first_page = repository.list_watch_history(
        user_id=user.id,
        limit=2,
    )

    assert len(first_page.items) == 2
    assert first_page.has_more is True

    assert first_page.items[0].episode.id == episodes[4].id

    assert first_page.items[1].episode.id == episodes[3].id

    cursor = first_page.items[-1]

    second_page = repository.list_watch_history(
        user_id=user.id,
        limit=2,
        before_watched_at=cursor.watched_at,
        before_progress_id=cursor.progress_id,
    )

    assert len(second_page.items) == 2
    assert second_page.has_more is True

    assert second_page.items[0].episode.id == episodes[2].id

    assert second_page.items[1].episode.id == episodes[1].id

    cursor = second_page.items[-1]

    third_page = repository.list_watch_history(
        user_id=user.id,
        limit=2,
        before_watched_at=cursor.watched_at,
        before_progress_id=cursor.progress_id,
    )

    assert len(third_page.items) == 1
    assert third_page.has_more is False

    assert third_page.items[0].episode.id == episodes[0].id


def test_list_watch_history_cursor_handles_equal_watched_timestamps(
    db_session: Session,
) -> None:
    """Do not skip items when watched_at values are equal."""

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

    episodes = [
        create_episode(
            db_session,
            season=season,
            tmdb_id=2400 + index,
            episode_number=index,
            title=f"Episode {index}",
        )
        for index in range(1, 4)
    ]

    watched_at = datetime(
        2026,
        8,
        10,
        20,
        tzinfo=UTC,
    )

    for episode in episodes:
        db_session.add(
            EpisodeProgress(
                user_id=user.id,
                episode_id=episode.id,
                is_watched=True,
                watched_at=watched_at,
            )
        )

    db_session.commit()

    repository = EpisodeProgressRepository(
        db_session,
    )

    first_page = repository.list_watch_history(
        user_id=user.id,
        limit=2,
    )

    assert len(first_page.items) == 2
    assert first_page.has_more is True

    first_page_ids = {item.progress_id for item in first_page.items}

    cursor = first_page.items[-1]

    second_page = repository.list_watch_history(
        user_id=user.id,
        limit=2,
        before_watched_at=cursor.watched_at,
        before_progress_id=cursor.progress_id,
    )

    assert len(second_page.items) == 1
    assert second_page.has_more is False

    assert second_page.items[0].progress_id not in first_page_ids


def test_list_watch_history_rejects_partial_cursor(
    db_session: Session,
) -> None:
    """Require both cursor components together."""

    user = create_user(db_session)

    repository = EpisodeProgressRepository(
        db_session,
    )

    with pytest.raises(
        ValueError,
        match="cursor requires both",
    ):
        repository.list_watch_history(
            user_id=user.id,
            before_watched_at=datetime.now(UTC),
        )


def test_get_watched_aired_counts_by_show_ids_groups_counts_by_show(
    db_session: Session,
) -> None:
    """Return watched aired regular Episode counts for multiple Shows."""

    user = create_user(db_session)

    first_show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    second_show = create_show(
        db_session,
        tmdb_id=100088,
        title="The Last of Us",
    )

    first_season = create_season(
        db_session,
        show=first_show,
        tmdb_id=1001,
        season_number=1,
        title="Season 1",
    )

    second_season = create_season(
        db_session,
        show=second_show,
        tmdb_id=2001,
        season_number=1,
        title="Season 1",
    )

    first_episode = create_episode(
        db_session,
        season=first_season,
        tmdb_id=3001,
        episode_number=1,
        title="Episode 1",
        air_date=date(2026, 7, 1),
    )

    second_episode = create_episode(
        db_session,
        season=first_season,
        tmdb_id=3002,
        episode_number=2,
        title="Episode 2",
        air_date=date(2026, 7, 8),
    )

    third_episode = create_episode(
        db_session,
        season=second_season,
        tmdb_id=4001,
        episode_number=1,
        title="Episode 1",
        air_date=date(2026, 7, 5),
    )

    for episode in (
        first_episode,
        second_episode,
        third_episode,
    ):
        create_progress(
            db_session,
            user=user,
            episode=episode,
            is_watched=True,
        )

    repository = EpisodeProgressRepository(db_session)

    result = repository.get_watched_aired_counts_by_show_ids(
        user_id=user.id,
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


def test_get_watched_aired_counts_by_show_ids_excludes_invalid_candidates(
    db_session: Session,
) -> None:
    """Exclude unwatched, future, unknown-date, and Special Episodes."""

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

    aired_watched = create_episode(
        db_session,
        season=regular,
        tmdb_id=2101,
        episode_number=1,
        title="Aired Watched",
        air_date=date(2026, 7, 1),
    )

    aired_unwatched = create_episode(
        db_session,
        season=regular,
        tmdb_id=2102,
        episode_number=2,
        title="Aired Unwatched",
        air_date=date(2026, 7, 8),
    )

    future = create_episode(
        db_session,
        season=regular,
        tmdb_id=2103,
        episode_number=3,
        title="Future",
        air_date=date(2026, 8, 20),
    )

    unknown = create_episode(
        db_session,
        season=regular,
        tmdb_id=2104,
        episode_number=4,
        title="Unknown",
        air_date=None,
    )

    create_progress(
        db_session,
        user=user,
        episode=special,
        is_watched=True,
    )

    create_progress(
        db_session,
        user=user,
        episode=aired_watched,
        is_watched=True,
    )

    create_progress(
        db_session,
        user=user,
        episode=aired_unwatched,
        is_watched=False,
    )

    create_progress(
        db_session,
        user=user,
        episode=future,
        is_watched=True,
    )

    create_progress(
        db_session,
        user=user,
        episode=unknown,
        is_watched=True,
    )

    repository = EpisodeProgressRepository(db_session)

    result = repository.get_watched_aired_counts_by_show_ids(
        user_id=user.id,
        show_ids=[show.id],
        as_of=date(2026, 8, 13),
    )

    assert result == {
        show.id: 1,
    }


def test_get_watched_aired_counts_by_show_ids_isolated_by_user(
    db_session: Session,
) -> None:
    """Count watched Episodes only for the requested user."""

    user = create_user(
        db_session,
        display_name="First User",
    )

    other_user = create_user(
        db_session,
        display_name="Other User",
    )

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    season = create_season(
        db_session,
        show=show,
        tmdb_id=1001,
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
        air_date=date(2026, 7, 8),
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

    result = repository.get_watched_aired_counts_by_show_ids(
        user_id=user.id,
        show_ids=[show.id],
        as_of=date(2026, 8, 13),
    )

    assert result == {
        show.id: 1,
    }


def test_get_watched_aired_counts_by_show_ids_returns_empty_for_empty_input(
    db_session: Session,
) -> None:
    """Return no progress counts when no Shows are requested."""

    user = create_user(db_session)

    repository = EpisodeProgressRepository(db_session)

    result = repository.get_watched_aired_counts_by_show_ids(
        user_id=user.id,
        show_ids=[],
        as_of=date(2026, 8, 13),
    )

    assert result == {}


def test_get_watched_episode_ids_returns_only_watched_requested_episodes(
    db_session: Session,
) -> None:
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

    watched_episode = create_episode(
        db_session,
        season=season,
        tmdb_id=1947647,
        episode_number=1,
        title="Good News About Hell",
    )

    unwatched_episode = create_episode(
        db_session,
        season=season,
        tmdb_id=1947648,
        episode_number=2,
        title="Half Loop",
    )

    progress = EpisodeProgress(
        user_id=user.id,
        episode_id=watched_episode.id,
        is_watched=True,
        watched_at=datetime.now(UTC),
    )

    db_session.add(progress)
    db_session.commit()

    repository = EpisodeProgressRepository(db_session)

    result = repository.get_watched_episode_ids(
        user_id=user.id,
        episode_ids=[
            watched_episode.id,
            unwatched_episode.id,
        ],
    )

    assert result == {
        watched_episode.id,
    }


def test_get_watched_episode_ids_returns_empty_for_empty_input(
    db_session: Session,
) -> None:
    repository = EpisodeProgressRepository(db_session)

    result = repository.get_watched_episode_ids(
        user_id=uuid4(),
        episode_ids=[],
    )

    assert result == set()


def test_list_missed_recently_returns_unwatched_regular_episodes_for_watching_shows(
    db_session: Session,
) -> None:
    user = create_user(db_session)

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    create_library_entry(
        db_session,
        user=user,
        show=show,
        status=LibraryStatus.WATCHING,
    )

    season = create_season(
        db_session,
        show=show,
        tmdb_id=134792,
        season_number=2,
        title="Season 2",
    )

    episode = create_episode(
        db_session,
        season=season,
        tmdb_id=300001,
        episode_number=3,
        title="Who Is Alive?",
        air_date=date(2026, 8, 16),
    )

    repository = EpisodeProgressRepository(db_session)

    result = repository.list_missed_recently(
        user_id=user.id,
        from_date=date(2026, 8, 3),
        to_date=date(2026, 8, 16),
        limit=10,
    )

    assert len(result) == 1

    item = result[0]

    assert item.show_id == show.id
    assert item.episode.id == episode.id
    assert item.season_number == 2


def test_list_missed_recently_excludes_watched_episodes(
    db_session: Session,
) -> None:
    user = create_user(db_session)

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    create_library_entry(
        db_session,
        user=user,
        show=show,
        status=LibraryStatus.WATCHING,
    )

    season = create_season(
        db_session,
        show=show,
        tmdb_id=134792,
        season_number=2,
        title="Season 2",
    )

    watched_episode = create_episode(
        db_session,
        season=season,
        tmdb_id=300001,
        episode_number=1,
        title="Watched",
        air_date=date(2026, 8, 15),
    )

    unwatched_episode = create_episode(
        db_session,
        season=season,
        tmdb_id=300002,
        episode_number=2,
        title="Unwatched",
        air_date=date(2026, 8, 16),
    )

    progress = EpisodeProgress(
        user_id=user.id,
        episode_id=watched_episode.id,
        is_watched=True,
        watched_at=datetime(
            2026,
            8,
            15,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    db_session.add(progress)
    db_session.commit()

    repository = EpisodeProgressRepository(db_session)

    result = repository.list_missed_recently(
        user_id=user.id,
        from_date=date(2026, 8, 3),
        to_date=date(2026, 8, 16),
        limit=10,
    )

    assert [item.episode.id for item in result] == [
        unwatched_episode.id,
    ]


def test_list_missed_recently_keeps_explicitly_unwatched_progress(
    db_session: Session,
) -> None:
    user = create_user(db_session)

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    create_library_entry(
        db_session,
        user=user,
        show=show,
        status=LibraryStatus.WATCHING,
    )

    season = create_season(
        db_session,
        show=show,
        tmdb_id=134792,
        season_number=2,
        title="Season 2",
    )

    episode = create_episode(
        db_session,
        season=season,
        tmdb_id=300001,
        episode_number=1,
        title="Unwatched",
        air_date=date(2026, 8, 16),
    )

    progress = EpisodeProgress(
        user_id=user.id,
        episode_id=episode.id,
        is_watched=False,
        watched_at=None,
    )

    db_session.add(progress)
    db_session.commit()

    repository = EpisodeProgressRepository(db_session)

    result = repository.list_missed_recently(
        user_id=user.id,
        from_date=date(2026, 8, 3),
        to_date=date(2026, 8, 16),
        limit=10,
    )

    assert [item.episode.id for item in result] == [
        episode.id,
    ]


def test_list_missed_recently_only_returns_watching_shows(
    db_session: Session,
) -> None:
    user = create_user(db_session)

    statuses = (
        LibraryStatus.WATCHING,
        LibraryStatus.PLANNING,
        LibraryStatus.PAUSED,
        LibraryStatus.COMPLETED,
        LibraryStatus.DROPPED,
    )

    expected_episode_id = None

    for index, status in enumerate(statuses):
        show = create_show(
            db_session,
            tmdb_id=110000 + index,
            title=f"Show {status.value}",
        )

        create_library_entry(
            db_session,
            user=user,
            show=show,
            status=status,
        )

        season = create_season(
            db_session,
            show=show,
            tmdb_id=120000 + index,
            season_number=1,
            title="Season 1",
        )

        episode = create_episode(
            db_session,
            season=season,
            tmdb_id=130000 + index,
            episode_number=1,
            title="Episode",
            air_date=date(2026, 8, 16),
        )

        if status == LibraryStatus.WATCHING:
            expected_episode_id = episode.id

    repository = EpisodeProgressRepository(db_session)

    result = repository.list_missed_recently(
        user_id=user.id,
        from_date=date(2026, 8, 3),
        to_date=date(2026, 8, 16),
        limit=10,
    )

    assert [item.episode.id for item in result] == [
        expected_episode_id,
    ]


def test_list_missed_recently_excludes_special_episodes(
    db_session: Session,
) -> None:
    user = create_user(db_session)

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    create_library_entry(
        db_session,
        user=user,
        show=show,
        status=LibraryStatus.WATCHING,
    )

    specials = create_season(
        db_session,
        show=show,
        tmdb_id=134790,
        season_number=0,
        title="Specials",
    )

    regular_season = create_season(
        db_session,
        show=show,
        tmdb_id=134792,
        season_number=2,
        title="Season 2",
    )

    create_episode(
        db_session,
        season=specials,
        tmdb_id=300001,
        episode_number=1,
        title="Special",
        air_date=date(2026, 8, 16),
    )

    regular_episode = create_episode(
        db_session,
        season=regular_season,
        tmdb_id=300002,
        episode_number=1,
        title="Regular Episode",
        air_date=date(2026, 8, 16),
    )

    repository = EpisodeProgressRepository(db_session)

    result = repository.list_missed_recently(
        user_id=user.id,
        from_date=date(2026, 8, 3),
        to_date=date(2026, 8, 16),
        limit=10,
    )

    assert [item.episode.id for item in result] == [
        regular_episode.id,
    ]


def test_list_missed_recently_uses_inclusive_date_range(
    db_session: Session,
) -> None:
    user = create_user(db_session)

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    create_library_entry(
        db_session,
        user=user,
        show=show,
        status=LibraryStatus.WATCHING,
    )

    season = create_season(
        db_session,
        show=show,
        tmdb_id=134792,
        season_number=2,
        title="Season 2",
    )

    before = create_episode(
        db_session,
        season=season,
        tmdb_id=300001,
        episode_number=1,
        title="Before",
        air_date=date(2026, 8, 2),
    )

    first = create_episode(
        db_session,
        season=season,
        tmdb_id=300002,
        episode_number=2,
        title="First Boundary",
        air_date=date(2026, 8, 3),
    )

    last = create_episode(
        db_session,
        season=season,
        tmdb_id=300003,
        episode_number=3,
        title="Last Boundary",
        air_date=date(2026, 8, 16),
    )

    after = create_episode(
        db_session,
        season=season,
        tmdb_id=300004,
        episode_number=4,
        title="After",
        air_date=date(2026, 8, 17),
    )

    repository = EpisodeProgressRepository(db_session)

    result = repository.list_missed_recently(
        user_id=user.id,
        from_date=date(2026, 8, 3),
        to_date=date(2026, 8, 16),
        limit=10,
    )

    ids = [item.episode.id for item in result]

    assert first.id in ids
    assert last.id in ids

    assert before.id not in ids
    assert after.id not in ids


def test_list_missed_recently_orders_newest_first(
    db_session: Session,
) -> None:
    user = create_user(db_session)

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    create_library_entry(
        db_session,
        user=user,
        show=show,
        status=LibraryStatus.WATCHING,
    )

    season = create_season(
        db_session,
        show=show,
        tmdb_id=134792,
        season_number=2,
        title="Season 2",
    )

    oldest = create_episode(
        db_session,
        season=season,
        tmdb_id=300001,
        episode_number=1,
        title="Oldest",
        air_date=date(2026, 8, 5),
    )

    middle = create_episode(
        db_session,
        season=season,
        tmdb_id=300002,
        episode_number=2,
        title="Middle",
        air_date=date(2026, 8, 10),
    )

    newest = create_episode(
        db_session,
        season=season,
        tmdb_id=300003,
        episode_number=3,
        title="Newest",
        air_date=date(2026, 8, 16),
    )

    repository = EpisodeProgressRepository(db_session)

    result = repository.list_missed_recently(
        user_id=user.id,
        from_date=date(2026, 8, 3),
        to_date=date(2026, 8, 16),
        limit=10,
    )

    assert [item.episode.id for item in result] == [
        newest.id,
        middle.id,
        oldest.id,
    ]


def test_list_missed_recently_respects_limit(
    db_session: Session,
) -> None:
    user = create_user(db_session)

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    create_library_entry(
        db_session,
        user=user,
        show=show,
        status=LibraryStatus.WATCHING,
    )

    season = create_season(
        db_session,
        show=show,
        tmdb_id=134792,
        season_number=2,
        title="Season 2",
    )

    for index in range(12):
        create_episode(
            db_session,
            season=season,
            tmdb_id=300000 + index,
            episode_number=index + 1,
            title=f"Episode {index + 1}",
            air_date=date(2026, 8, 16) - timedelta(days=index),
        )

    repository = EpisodeProgressRepository(db_session)

    result = repository.list_missed_recently(
        user_id=user.id,
        from_date=date(2026, 8, 3),
        to_date=date(2026, 8, 16),
        limit=10,
    )

    assert len(result) == 10
