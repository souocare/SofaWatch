from datetime import UTC, datetime
from uuid import UUID, uuid4

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.episode import Episode
from app.models.episode_watch_event import EpisodeWatchEvent
from app.models.season import Season
from app.models.show import Show
from app.models.user import User
from app.repositories.episode_watch_event import EpisodeWatchEventRepository
from app.models.genre import Genre


def as_utc(value: datetime) -> datetime:
    """Normalize a database datetime to UTC."""

    if value.tzinfo is None:
        return value.replace(tzinfo=UTC)

    return value.astimezone(UTC)


def create_user(
    db_session: Session,
    *,
    display_name: str = "Test User",
) -> User:
    """Create and persist a user for watch event repository tests."""

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
) -> Episode:
    """Create and persist a TV episode."""

    episode = Episode(
        season_id=season.id,
        tmdb_id=tmdb_id,
        episode_number=episode_number,
        title=title,
        overview=None,
        air_date=None,
        runtime=None,
        vote_average=0.0,
        vote_count=0,
        tmdb_still_path=None,
        local_still_path=None,
    )

    db_session.add(episode)
    db_session.commit()
    db_session.refresh(episode)

    return episode


def create_watch_event(
    db_session: Session,
    *,
    user: User,
    episode: Episode,
    watched_at: datetime,
    event_id: UUID | None = None,
) -> EpisodeWatchEvent:
    """Create and persist a historical Episode viewing event."""

    event = EpisodeWatchEvent(
        id=event_id if event_id is not None else None,
        user_id=user.id,
        episode_id=episode.id,
        watched_at=watched_at,
    )

    if event_id is None:
        # Let the model's UUID default run normally.
        event = EpisodeWatchEvent(
            user_id=user.id,
            episode_id=episode.id,
            watched_at=watched_at,
        )

    db_session.add(event)
    db_session.commit()
    db_session.refresh(event)

    return event

def create_genre(
    db_session: Session,
    *,
    name: str,
    slug: str,
) -> Genre:
    """Create and persist a Genre."""

    genre = Genre(
        name=name,
        slug=slug,
    )

    db_session.add(genre)
    db_session.commit()
    db_session.refresh(genre)

    return genre


def test_add_episode_watch_event(
    db_session: Session,
) -> None:
    """Add an Episode watch event to the current unit of work."""

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

    watched_at = datetime(
        2026,
        8,
        14,
        10,
        30,
        tzinfo=UTC,
    )

    repository = EpisodeWatchEventRepository(
        db_session,
    )

    event = EpisodeWatchEvent(
        user_id=user.id,
        episode_id=episode.id,
        watched_at=watched_at,
    )

    result = repository.add(
        event,
    )

    assert result is event

    db_session.commit()
    db_session.refresh(event)

    persisted_event = db_session.scalar(
        select(EpisodeWatchEvent).where(
            EpisodeWatchEvent.id == event.id,
        )
    )

    assert persisted_event is not None

    assert persisted_event.id == event.id
    assert persisted_event.user_id == user.id
    assert persisted_event.episode_id == episode.id

    assert as_utc(
        persisted_event.watched_at,
    ) == watched_at


def test_allows_multiple_watch_events_for_same_episode(
    db_session: Session,
) -> None:
    """Store multiple watch events for the same user and Episode."""

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

    repository = EpisodeWatchEventRepository(
        db_session,
    )

    first_event = EpisodeWatchEvent(
        user_id=user.id,
        episode_id=episode.id,
        watched_at=datetime(
            2026,
            8,
            1,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    second_event = EpisodeWatchEvent(
        user_id=user.id,
        episode_id=episode.id,
        watched_at=datetime(
            2026,
            8,
            14,
            21,
            30,
            tzinfo=UTC,
        ),
    )

    repository.add(
        first_event,
    )
    repository.add(
        second_event,
    )

    db_session.commit()

    events = list(
        db_session.scalars(
            select(EpisodeWatchEvent)
            .where(
                EpisodeWatchEvent.user_id == user.id,
                EpisodeWatchEvent.episode_id == episode.id,
            )
            .order_by(
                EpisodeWatchEvent.watched_at.asc(),
            )
        ).all()
    )

    assert len(events) == 2

    assert events[0].id == first_event.id

    assert as_utc(
        events[0].watched_at,
    ) == datetime(
        2026,
        8,
        1,
        20,
        0,
        tzinfo=UTC,
    )

    assert events[1].id == second_event.id

    assert as_utc(
        events[1].watched_at,
    ) == datetime(
        2026,
        8,
        14,
        21,
        30,
        tzinfo=UTC,
    )


def test_list_watch_history_returns_newest_events_first(
    db_session: Session,
) -> None:
    """Return Watch History ordered from newest viewing to oldest."""

    user = create_user(
        db_session,
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

    older_event = create_watch_event(
        db_session,
        user=user,
        episode=first_episode,
        watched_at=datetime(
            2026,
            8,
            10,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    newer_event = create_watch_event(
        db_session,
        user=user,
        episode=second_episode,
        watched_at=datetime(
            2026,
            8,
            14,
            21,
            30,
            tzinfo=UTC,
        ),
    )

    repository = EpisodeWatchEventRepository(
        db_session,
    )

    page = repository.list_watch_history(
        user_id=user.id,
        limit=30,
    )

    assert page.has_more is False
    assert len(page.items) == 2

    assert page.items[0].event_id == newer_event.id
    assert page.items[0].episode.id == second_episode.id
    assert page.items[0].season_number == 1
    assert page.items[0].show.id == show.id
    assert page.items[0].show.title == "Severance"

    assert as_utc(
        page.items[0].watched_at,
    ) == datetime(
        2026,
        8,
        14,
        21,
        30,
        tzinfo=UTC,
    )

    assert page.items[1].event_id == older_event.id
    assert page.items[1].episode.id == first_episode.id


def test_list_watch_history_keeps_rewatches_as_independent_items(
    db_session: Session,
) -> None:
    """Return every rewatch as an independent Watch History entry."""

    user = create_user(
        db_session,
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
        title="Good News About Hell",
    )

    first_event = create_watch_event(
        db_session,
        user=user,
        episode=episode,
        watched_at=datetime(
            2026,
            7,
            20,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    second_event = create_watch_event(
        db_session,
        user=user,
        episode=episode,
        watched_at=datetime(
            2026,
            8,
            14,
            21,
            30,
            tzinfo=UTC,
        ),
    )

    repository = EpisodeWatchEventRepository(
        db_session,
    )

    page = repository.list_watch_history(
        user_id=user.id,
        limit=30,
    )

    assert page.has_more is False
    assert len(page.items) == 2

    assert page.items[0].event_id == second_event.id
    assert page.items[1].event_id == first_event.id

    assert page.items[0].episode.id == episode.id
    assert page.items[1].episode.id == episode.id

    assert as_utc(
        page.items[0].watched_at,
    ) == datetime(
        2026,
        8,
        14,
        21,
        30,
        tzinfo=UTC,
    )

    assert as_utc(
        page.items[1].watched_at,
    ) == datetime(
        2026,
        7,
        20,
        20,
        0,
        tzinfo=UTC,
    )


def test_list_watch_history_is_isolated_by_user(
    db_session: Session,
) -> None:
    """Return only historical viewing events belonging to the user."""

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

    episode = create_episode(
        db_session,
        season=season,
        tmdb_id=2101,
        episode_number=1,
        title="Good News About Hell",
    )

    user_event = create_watch_event(
        db_session,
        user=user,
        episode=episode,
        watched_at=datetime(
            2026,
            8,
            14,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    create_watch_event(
        db_session,
        user=other_user,
        episode=episode,
        watched_at=datetime(
            2026,
            8,
            14,
            21,
            0,
            tzinfo=UTC,
        ),
    )

    repository = EpisodeWatchEventRepository(
        db_session,
    )

    page = repository.list_watch_history(
        user_id=user.id,
        limit=30,
    )

    assert page.has_more is False
    assert len(page.items) == 1

    assert page.items[0].event_id == user_event.id
    assert page.items[0].episode.id == episode.id


def test_list_watch_history_reports_when_more_items_exist(
    db_session: Session,
) -> None:
    """Request one extra row internally to determine whether more history exists."""

    user = create_user(
        db_session,
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
        title="Good News About Hell",
    )

    for day in (
        10,
        11,
        12,
    ):
        create_watch_event(
            db_session,
            user=user,
            episode=episode,
            watched_at=datetime(
                2026,
                8,
                day,
                20,
                0,
                tzinfo=UTC,
            ),
        )

    repository = EpisodeWatchEventRepository(
        db_session,
    )

    page = repository.list_watch_history(
        user_id=user.id,
        limit=2,
    )

    assert len(page.items) == 2
    assert page.has_more is True

    assert as_utc(
        page.items[0].watched_at,
    ) == datetime(
        2026,
        8,
        12,
        20,
        0,
        tzinfo=UTC,
    )

    assert as_utc(
        page.items[1].watched_at,
    ) == datetime(
        2026,
        8,
        11,
        20,
        0,
        tzinfo=UTC,
    )


def test_list_watch_history_supports_cursor_pagination(
    db_session: Session,
) -> None:
    """Load older Watch History using the last event from the previous page."""

    user = create_user(
        db_session,
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
        title="Good News About Hell",
    )

    oldest_event = create_watch_event(
        db_session,
        user=user,
        episode=episode,
        watched_at=datetime(
            2026,
            8,
            10,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    middle_event = create_watch_event(
        db_session,
        user=user,
        episode=episode,
        watched_at=datetime(
            2026,
            8,
            11,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    newest_event = create_watch_event(
        db_session,
        user=user,
        episode=episode,
        watched_at=datetime(
            2026,
            8,
            12,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    repository = EpisodeWatchEventRepository(
        db_session,
    )

    first_page = repository.list_watch_history(
        user_id=user.id,
        limit=2,
    )

    assert len(first_page.items) == 2
    assert first_page.has_more is True

    assert first_page.items[0].event_id == newest_event.id
    assert first_page.items[1].event_id == middle_event.id

    cursor_item = first_page.items[-1]

    second_page = repository.list_watch_history(
        user_id=user.id,
        limit=2,
        before_watched_at=cursor_item.watched_at,
        before_event_id=cursor_item.event_id,
    )

    assert len(second_page.items) == 1
    assert second_page.has_more is False

    assert second_page.items[0].event_id == oldest_event.id


def test_list_watch_history_uses_event_id_to_break_timestamp_ties(
    db_session: Session,
) -> None:
    """Use event ID as a stable secondary cursor when timestamps match."""

    user = create_user(
        db_session,
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
        title="Good News About Hell",
    )

    watched_at = datetime(
        2026,
        8,
        14,
        21,
        30,
        tzinfo=UTC,
    )

    lower_id = UUID(
        "00000000-0000-0000-0000-000000000001",
    )

    middle_id = UUID(
        "00000000-0000-0000-0000-000000000002",
    )

    higher_id = UUID(
        "00000000-0000-0000-0000-000000000003",
    )

    lower_event = create_watch_event(
        db_session,
        user=user,
        episode=episode,
        watched_at=watched_at,
        event_id=lower_id,
    )

    middle_event = create_watch_event(
        db_session,
        user=user,
        episode=episode,
        watched_at=watched_at,
        event_id=middle_id,
    )

    higher_event = create_watch_event(
        db_session,
        user=user,
        episode=episode,
        watched_at=watched_at,
        event_id=higher_id,
    )

    repository = EpisodeWatchEventRepository(
        db_session,
    )

    first_page = repository.list_watch_history(
        user_id=user.id,
        limit=2,
    )

    assert len(first_page.items) == 2
    assert first_page.has_more is True

    assert first_page.items[0].event_id == higher_event.id
    assert first_page.items[1].event_id == middle_event.id

    second_page = repository.list_watch_history(
        user_id=user.id,
        limit=2,
        before_watched_at=first_page.items[-1].watched_at,
        before_event_id=first_page.items[-1].event_id,
    )

    assert len(second_page.items) == 1
    assert second_page.has_more is False

    assert second_page.items[0].event_id == lower_event.id


def test_list_watch_history_rejects_incomplete_cursor(
    db_session: Session,
) -> None:
    """Require both timestamp and event ID when using a history cursor."""

    repository = EpisodeWatchEventRepository(
        db_session,
    )

    user = create_user(
        db_session,
    )

    try:
        repository.list_watch_history(
            user_id=user.id,
            before_watched_at=datetime(
                2026,
                8,
                14,
                20,
                0,
                tzinfo=UTC,
            ),
            before_event_id=None,
        )
    except ValueError as error:
        assert "cursor" in str(error).lower()
    else:
        raise AssertionError(
            "Expected list_watch_history() to reject an incomplete cursor."
        )


def test_list_watch_history_returns_empty_page_for_non_positive_limit(
    db_session: Session,
) -> None:
    """Return an empty page when the requested page size is not positive."""

    user = create_user(
        db_session,
    )

    repository = EpisodeWatchEventRepository(
        db_session,
    )

    page = repository.list_watch_history(
        user_id=user.id,
        limit=0,
    )

    assert page.items == []
    assert page.has_more is False

def test_get_counts_by_user_and_episode_ids(
    db_session: Session,
) -> None:
    """Return historical watch counts grouped by Episode."""

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

    repository = EpisodeWatchEventRepository(
        db_session,
    )

    repository.add(
        EpisodeWatchEvent(
            user_id=user.id,
            episode_id=first_episode.id,
            watched_at=datetime(
                2026,
                8,
                1,
                20,
                0,
                tzinfo=UTC,
            ),
        )
    )

    repository.add(
        EpisodeWatchEvent(
            user_id=user.id,
            episode_id=first_episode.id,
            watched_at=datetime(
                2026,
                8,
                14,
                20,
                0,
                tzinfo=UTC,
            ),
        )
    )

    repository.add(
        EpisodeWatchEvent(
            user_id=user.id,
            episode_id=second_episode.id,
            watched_at=datetime(
                2026,
                8,
                10,
                20,
                0,
                tzinfo=UTC,
            ),
        )
    )

    db_session.commit()

    result = repository.get_counts_by_user_and_episode_ids(
        user_id=user.id,
        episode_ids=[
            first_episode.id,
            second_episode.id,
        ],
    )

    assert result == {
        first_episode.id: 2,
        second_episode.id: 1,
    }

def test_get_counts_by_user_and_episode_ids_returns_empty_for_empty_input(
    db_session: Session,
) -> None:
    """Avoid querying watch counts when no Episodes are requested."""

    repository = EpisodeWatchEventRepository(
        db_session,
    )

    result = repository.get_counts_by_user_and_episode_ids(
        user_id=uuid4(),
        episode_ids=[],
    )

    assert result == {}

def test_get_statistics_for_period_counts_viewings_and_runtime(
    db_session: Session,
) -> None:
    """Aggregate Episode viewing count and runtime within a period."""

    user = create_user(
        db_session,
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
        title="Good News About Hell",
    )

    episode.runtime = 50

    db_session.commit()

    create_watch_event(
        db_session,
        user=user,
        episode=episode,
        watched_at=datetime(
            2026,
            8,
            17,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    create_watch_event(
        db_session,
        user=user,
        episode=episode,
        watched_at=datetime(
            2026,
            8,
            19,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    # Previous week: must not be included.
    create_watch_event(
        db_session,
        user=user,
        episode=episode,
        watched_at=datetime(
            2026,
            8,
            16,
            23,
            59,
            tzinfo=UTC,
        ),
    )

    repository = EpisodeWatchEventRepository(
        db_session,
    )

    count, watch_time = repository.get_statistics_for_period(
        user_id=user.id,
        start_at=datetime(
            2026,
            8,
            17,
            tzinfo=UTC,
        ),
        end_at=datetime(
            2026,
            8,
            24,
            tzinfo=UTC,
        ),
    )

    assert count == 2

    assert watch_time == 100


def test_get_statistics_for_period_counts_episode_without_runtime(
    db_session: Session,
) -> None:
    """Count a viewing even when the Episode runtime is unknown."""

    user = create_user(
        db_session,
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
        title="Good News About Hell",
    )

    assert episode.runtime is None

    create_watch_event(
        db_session,
        user=user,
        episode=episode,
        watched_at=datetime(
            2026,
            8,
            19,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    repository = EpisodeWatchEventRepository(
        db_session,
    )

    count, watch_time = repository.get_statistics_for_period(
        user_id=user.id,
        start_at=datetime(
            2026,
            8,
            17,
            tzinfo=UTC,
        ),
        end_at=datetime(
            2026,
            8,
            24,
            tzinfo=UTC,
        ),
    )

    assert count == 1
    assert watch_time == 0

def test_get_all_time_statistics_counts_unique_episodes_and_rewatches(
    db_session: Session,
) -> None:
    """Aggregate all-time Episode watches, unique Episodes and rewatches."""

    user = create_user(
        db_session,
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

    first_episode.runtime = 50
    second_episode.runtime = 40

    db_session.commit()

    # First Episode: one original watch + two rewatches.
    create_watch_event(
        db_session,
        user=user,
        episode=first_episode,
        watched_at=datetime(
            2026,
            8,
            1,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    create_watch_event(
        db_session,
        user=user,
        episode=first_episode,
        watched_at=datetime(
            2026,
            8,
            2,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    create_watch_event(
        db_session,
        user=user,
        episode=first_episode,
        watched_at=datetime(
            2026,
            8,
            3,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    # Second Episode: one original watch.
    create_watch_event(
        db_session,
        user=user,
        episode=second_episode,
        watched_at=datetime(
            2026,
            8,
            4,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    repository = EpisodeWatchEventRepository(
        db_session,
    )

    (
        watch_count,
        unique_count,
        rewatch_count,
        watch_time_minutes,
        rewatch_time_minutes,
    ) = repository.get_all_time_statistics(
        user_id=user.id,
    )

    assert watch_count == 4
    assert unique_count == 2
    assert rewatch_count == 2

    # 50 + 50 + 50 + 40
    assert watch_time_minutes == 190

    # The second and third views of Episode 1 are rewatches.
    assert rewatch_time_minutes == 100

    assert watch_count == unique_count + rewatch_count


def test_get_all_time_statistics_counts_episode_without_runtime(
    db_session: Session,
) -> None:
    """Count Episode watches even when runtime is unknown."""

    user = create_user(
        db_session,
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
        title="Good News About Hell",
    )

    assert episode.runtime is None

    create_watch_event(
        db_session,
        user=user,
        episode=episode,
        watched_at=datetime(
            2026,
            8,
            1,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    create_watch_event(
        db_session,
        user=user,
        episode=episode,
        watched_at=datetime(
            2026,
            8,
            2,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    repository = EpisodeWatchEventRepository(
        db_session,
    )

    (
        watch_count,
        unique_count,
        rewatch_count,
        watch_time_minutes,
        rewatch_time_minutes,
    ) = repository.get_all_time_statistics(
        user_id=user.id,
    )

    assert watch_count == 2
    assert unique_count == 1
    assert rewatch_count == 1
    assert watch_time_minutes == 0
    assert rewatch_time_minutes == 0


def test_get_all_time_statistics_is_isolated_by_user(
    db_session: Session,
) -> None:
    """Only include Episode watches belonging to the requested user."""

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
        title="Good News About Hell",
    )

    episode.runtime = 50

    db_session.commit()

    create_watch_event(
        db_session,
        user=first_user,
        episode=episode,
        watched_at=datetime(
            2026,
            8,
            1,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    create_watch_event(
        db_session,
        user=second_user,
        episode=episode,
        watched_at=datetime(
            2026,
            8,
            2,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    create_watch_event(
        db_session,
        user=second_user,
        episode=episode,
        watched_at=datetime(
            2026,
            8,
            3,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    repository = EpisodeWatchEventRepository(
        db_session,
    )

    result = repository.get_all_time_statistics(
        user_id=first_user.id,
    )

    assert result == (
        1,
        1,
        0,
        50,
        0,
    )


def test_count_watched_shows_counts_each_show_once(
    db_session: Session,
) -> None:
    """Count each watched Show once regardless of Episodes or rewatches."""

    user = create_user(
        db_session,
    )

    first_show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    first_season = create_season(
        db_session,
        show=first_show,
        tmdb_id=134792,
        season_number=1,
        title="Season 1",
    )

    first_episode = create_episode(
        db_session,
        season=first_season,
        tmdb_id=2101,
        episode_number=1,
        title="Good News About Hell",
    )

    second_episode = create_episode(
        db_session,
        season=first_season,
        tmdb_id=2102,
        episode_number=2,
        title="Half Loop",
    )

    second_show = create_show(
        db_session,
        tmdb_id=1396,
        title="Breaking Bad",
    )

    second_season = create_season(
        db_session,
        show=second_show,
        tmdb_id=3624,
        season_number=1,
        title="Season 1",
    )

    third_episode = create_episode(
        db_session,
        season=second_season,
        tmdb_id=62085,
        episode_number=1,
        title="Pilot",
    )

    # Multiple watches from Show 1 must still represent one watched Show.
    create_watch_event(
        db_session,
        user=user,
        episode=first_episode,
        watched_at=datetime(
            2026,
            8,
            1,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    create_watch_event(
        db_session,
        user=user,
        episode=first_episode,
        watched_at=datetime(
            2026,
            8,
            2,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    create_watch_event(
        db_session,
        user=user,
        episode=second_episode,
        watched_at=datetime(
            2026,
            8,
            3,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    create_watch_event(
        db_session,
        user=user,
        episode=third_episode,
        watched_at=datetime(
            2026,
            8,
            4,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    repository = EpisodeWatchEventRepository(
        db_session,
    )

    result = repository.count_watched_shows(
        user_id=user.id,
    )

    assert result == 2


def test_get_daily_statistics_for_period_groups_episode_activity_by_day(
    db_session: Session,
) -> None:
    """Group Episode viewing counts and runtime by calendar day."""

    user = create_user(
        db_session,
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
        title="Good News About Hell",
    )

    episode.runtime = 50

    db_session.commit()

    create_watch_event(
        db_session,
        user=user,
        episode=episode,
        watched_at=datetime(
            2026,
            8,
            17,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    create_watch_event(
        db_session,
        user=user,
        episode=episode,
        watched_at=datetime(
            2026,
            8,
            17,
            22,
            0,
            tzinfo=UTC,
        ),
    )

    create_watch_event(
        db_session,
        user=user,
        episode=episode,
        watched_at=datetime(
            2026,
            8,
            19,
            21,
            0,
            tzinfo=UTC,
        ),
    )

    # Outside requested range.
    create_watch_event(
        db_session,
        user=user,
        episode=episode,
        watched_at=datetime(
            2026,
            8,
            16,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    repository = EpisodeWatchEventRepository(
        db_session,
    )

    result = repository.get_daily_statistics_for_period(
        user_id=user.id,
        start_at=datetime(
            2026,
            8,
            17,
            tzinfo=UTC,
        ),
        end_at=datetime(
            2026,
            8,
            20,
            tzinfo=UTC,
        ),
    )

    assert [
        (
            item.day,
            item.watch_count,
            item.watch_time_minutes,
        )
        for item in result
    ] == [
        (
            "2026-08-17",
            2,
            100,
        ),
        (
            "2026-08-19",
            1,
            50,
        ),
    ]


def test_get_daily_statistics_for_period_is_isolated_by_user(
    db_session: Session,
) -> None:
    """Exclude Episode activity belonging to other users."""

    user = create_user(
        db_session,
        display_name="Requested User",
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

    episode = create_episode(
        db_session,
        season=season,
        tmdb_id=2101,
        episode_number=1,
        title="Good News About Hell",
    )

    episode.runtime = 50

    db_session.commit()

    create_watch_event(
        db_session,
        user=user,
        episode=episode,
        watched_at=datetime(
            2026,
            8,
            17,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    create_watch_event(
        db_session,
        user=other_user,
        episode=episode,
        watched_at=datetime(
            2026,
            8,
            17,
            21,
            0,
            tzinfo=UTC,
        ),
    )

    repository = EpisodeWatchEventRepository(
        db_session,
    )

    result = repository.get_daily_statistics_for_period(
        user_id=user.id,
        start_at=datetime(
            2026,
            8,
            17,
            tzinfo=UTC,
        ),
        end_at=datetime(
            2026,
            8,
            18,
            tzinfo=UTC,
        ),
    )

    assert len(result) == 1
    assert result[0].watch_count == 1
    assert result[0].watch_time_minutes == 50

def test_get_earliest_watched_at_for_user(
    db_session: Session,
) -> None:
    user = create_user(
        db_session,
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
        title="Good News About Hell",
    )

    create_watch_event(
        db_session,
        user=user,
        episode=episode,
        watched_at=datetime(
            2026,
            8,
            18,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    create_watch_event(
        db_session,
        user=user,
        episode=episode,
        watched_at=datetime(
            2025,
            3,
            4,
            21,
            0,
            tzinfo=UTC,
        ),
    )

    repository = EpisodeWatchEventRepository(
        db_session,
    )

    result = repository.get_earliest_watched_at_for_user(
        user_id=user.id,
    )

    assert result is not None
    assert as_utc(result) == datetime(
        2025,
        3,
        4,
        21,
        0,
        tzinfo=UTC,
    )


def test_get_earliest_watched_at_for_user_returns_none_without_history(
    db_session: Session,
) -> None:
    user = create_user(
        db_session,
    )

    repository = EpisodeWatchEventRepository(
        db_session,
    )

    assert (
        repository.get_earliest_watched_at_for_user(
            user_id=user.id,
        )
        is None
    )


def test_get_most_watched_shows_ranks_by_episode_watch_events(
    db_session: Session,
) -> None:
    """Rank Shows by total Episode watch events for the requested user."""

    user = create_user(
        db_session,
    )

    other_user = create_user(
        db_session,
        display_name="Other User",
    )

    severance = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    silo = create_show(
        db_session,
        tmdb_id=125988,
        title="Silo",
    )

    severance_season = create_season(
        db_session,
        show=severance,
        tmdb_id=134792,
        season_number=1,
        title="Season 1",
    )

    silo_season = create_season(
        db_session,
        show=silo,
        tmdb_id=200001,
        season_number=1,
        title="Season 1",
    )

    severance_episode = create_episode(
        db_session,
        season=severance_season,
        tmdb_id=2101,
        episode_number=1,
        title="Good News About Hell",
    )

    silo_episode = create_episode(
        db_session,
        season=silo_season,
        tmdb_id=300001,
        episode_number=1,
        title="Freedom Day",
    )

    for hour in (
        18,
        19,
        20,
        21,
    ):
        create_watch_event(
            db_session,
            user=user,
            episode=severance_episode,
            watched_at=datetime(
                2026,
                8,
                18,
                hour,
                0,
                tzinfo=UTC,
            ),
        )

    for hour in (
        18,
        19,
    ):
        create_watch_event(
            db_session,
            user=user,
            episode=silo_episode,
            watched_at=datetime(
                2026,
                8,
                17,
                hour,
                0,
                tzinfo=UTC,
            ),
        )

    # Other-user activity must not affect the requested user's ranking.
    for hour in (
        10,
        11,
        12,
        13,
        14,
    ):
        create_watch_event(
            db_session,
            user=other_user,
            episode=silo_episode,
            watched_at=datetime(
                2026,
                8,
                16,
                hour,
                0,
                tzinfo=UTC,
            ),
        )

    repository = EpisodeWatchEventRepository(
        db_session,
    )

    result = repository.get_most_watched_shows(
        user_id=user.id,
        limit=5,
    )

    assert [
        (
            item.title,
            item.watch_count,
        )
        for item in result
    ] == [
        (
            "Severance",
            4,
        ),
        (
            "Silo",
            2,
        ),
    ]

def test_get_most_rewatched_shows_sums_episode_rewatches(
    db_session: Session,
) -> None:
    """Rank Shows by rewatches calculated independently per Episode."""

    user = create_user(
        db_session,
    )

    severance = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    silo = create_show(
        db_session,
        tmdb_id=125988,
        title="Silo",
    )

    severance_season = create_season(
        db_session,
        show=severance,
        tmdb_id=134792,
        season_number=1,
        title="Season 1",
    )

    silo_season = create_season(
        db_session,
        show=silo,
        tmdb_id=200001,
        season_number=1,
        title="Season 1",
    )

    severance_episode_1 = create_episode(
        db_session,
        season=severance_season,
        tmdb_id=2101,
        episode_number=1,
        title="Good News About Hell",
    )

    severance_episode_2 = create_episode(
        db_session,
        season=severance_season,
        tmdb_id=2102,
        episode_number=2,
        title="Half Loop",
    )

    silo_episode = create_episode(
        db_session,
        season=silo_season,
        tmdb_id=300001,
        episode_number=1,
        title="Freedom Day",
    )

    # Episode 1 -> 3 watches -> 2 rewatches.
    for hour in (
        10,
        11,
        12,
    ):
        create_watch_event(
            db_session,
            user=user,
            episode=severance_episode_1,
            watched_at=datetime(
                2026,
                8,
                16,
                hour,
                0,
                tzinfo=UTC,
            ),
        )

    # Episode 2 -> 2 watches -> 1 rewatch.
    for hour in (
        13,
        14,
    ):
        create_watch_event(
            db_session,
            user=user,
            episode=severance_episode_2,
            watched_at=datetime(
                2026,
                8,
                16,
                hour,
                0,
                tzinfo=UTC,
            ),
        )

    # Silo -> 2 watches -> 1 rewatch.
    for hour in (
        15,
        16,
    ):
        create_watch_event(
            db_session,
            user=user,
            episode=silo_episode,
            watched_at=datetime(
                2026,
                8,
                16,
                hour,
                0,
                tzinfo=UTC,
            ),
        )

    repository = EpisodeWatchEventRepository(
        db_session,
    )

    result = repository.get_most_rewatched_shows(
        user_id=user.id,
        limit=5,
    )

    assert [
        (
            item.title,
            item.watch_count,
            item.rewatch_count,
        )
        for item in result
    ] == [
        (
            "Severance",
            5,
            3,
        ),
        (
            "Silo",
            2,
            1,
        ),
    ]

def test_get_most_rewatched_episodes_excludes_single_viewings(
    db_session: Session,
) -> None:
    """Rank only Episodes that have at least one Rewatch."""

    user = create_user(
        db_session,
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

    third_episode = create_episode(
        db_session,
        season=season,
        tmdb_id=2103,
        episode_number=3,
        title="In Perpetuity",
    )

    for hour in (
        10,
        11,
        12,
    ):
        create_watch_event(
            db_session,
            user=user,
            episode=first_episode,
            watched_at=datetime(
                2026,
                8,
                18,
                hour,
                0,
                tzinfo=UTC,
            ),
        )

    for hour in (
        13,
        14,
    ):
        create_watch_event(
            db_session,
            user=user,
            episode=second_episode,
            watched_at=datetime(
                2026,
                8,
                18,
                hour,
                0,
                tzinfo=UTC,
            ),
        )

    # One viewing only: must not appear.
    create_watch_event(
        db_session,
        user=user,
        episode=third_episode,
        watched_at=datetime(
            2026,
            8,
            18,
            15,
            0,
            tzinfo=UTC,
        ),
    )

    repository = EpisodeWatchEventRepository(
        db_session,
    )

    result = repository.get_most_rewatched_episodes(
        user_id=user.id,
        limit=5,
    )

    assert [
        (
            item.episode_title,
            item.watch_count,
            item.rewatch_count,
        )
        for item in result
    ] == [
        (
            "Good News About Hell",
            3,
            2,
        ),
        (
            "Half Loop",
            2,
            1,
        ),
    ]

def test_get_top_show_genres_counts_episode_watch_events_for_each_genre(
    db_session: Session,
) -> None:
    """Rank Show Genres by Episode watch events."""

    user = create_user(
        db_session,
    )

    drama = create_genre(
        db_session,
        name="Drama",
        slug="drama",
    )

    science_fiction = create_genre(
        db_session,
        name="Science Fiction",
        slug="science-fiction",
    )

    comedy = create_genre(
        db_session,
        name="Comedy",
        slug="comedy",
    )

    severance = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    comedy_show = create_show(
        db_session,
        tmdb_id=999001,
        title="Comedy Show",
    )

    severance.genres.extend(
        [
            drama,
            science_fiction,
        ]
    )

    comedy_show.genres.append(
        comedy,
    )

    db_session.commit()

    severance_season = create_season(
        db_session,
        show=severance,
        tmdb_id=134792,
        season_number=1,
        title="Season 1",
    )

    comedy_season = create_season(
        db_session,
        show=comedy_show,
        tmdb_id=999002,
        season_number=1,
        title="Season 1",
    )

    severance_episode = create_episode(
        db_session,
        season=severance_season,
        tmdb_id=2101,
        episode_number=1,
        title="Good News About Hell",
    )

    comedy_episode = create_episode(
        db_session,
        season=comedy_season,
        tmdb_id=999003,
        episode_number=1,
        title="Pilot",
    )

    for hour in (
        10,
        11,
        12,
    ):
        create_watch_event(
            db_session,
            user=user,
            episode=severance_episode,
            watched_at=datetime(
                2026,
                8,
                18,
                hour,
                0,
                tzinfo=UTC,
            ),
        )

    create_watch_event(
        db_session,
        user=user,
        episode=comedy_episode,
        watched_at=datetime(
            2026,
            8,
            18,
            13,
            0,
            tzinfo=UTC,
        ),
    )

    repository = EpisodeWatchEventRepository(
        db_session,
    )

    result = repository.get_top_show_genres(
        user_id=user.id,
        limit=5,
    )

    assert [
        (
            item.name,
            item.watch_count,
        )
        for item in result
    ] == [
        (
            "Drama",
            3,
        ),
        (
            "Science Fiction",
            3,
        ),
        (
            "Comedy",
            1,
        ),
    ]

def test_list_all_for_user_returns_complete_episode_history_in_chronological_order(
    db_session: Session,
) -> None:
    """Return every Episode viewing from oldest to newest."""

    user = create_user(
        db_session,
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
        title="Good News About Hell",
    )

    older_event = create_watch_event(
        db_session,
        user=user,
        episode=episode,
        watched_at=datetime(
            2026,
            8,
            10,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    newer_event = create_watch_event(
        db_session,
        user=user,
        episode=episode,
        watched_at=datetime(
            2026,
            8,
            14,
            21,
            30,
            tzinfo=UTC,
        ),
    )

    repository = EpisodeWatchEventRepository(
        db_session,
    )

    result = repository.list_all_for_user(
        user_id=user.id,
    )

    assert [
        item.event_id
        for item in result
    ] == [
        older_event.id,
        newer_event.id,
    ]

    assert result[0].show.id == show.id
    assert result[0].show.tmdb_id == 95396

    assert result[0].season_number == 1

    assert result[0].episode.id == episode.id
    assert result[0].episode.tmdb_id == 2101
    assert result[0].episode.episode_number == 1


def test_list_all_for_user_preserves_specials_and_is_isolated_by_user(
    db_session: Session,
) -> None:
    """Export only the user's Episode History, including Specials."""

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

    specials = create_season(
        db_session,
        show=show,
        tmdb_id=134791,
        season_number=0,
        title="Specials",
    )

    episode = create_episode(
        db_session,
        season=specials,
        tmdb_id=2100,
        episode_number=1,
        title="Special",
    )

    expected_event = create_watch_event(
        db_session,
        user=user,
        episode=episode,
        watched_at=datetime(
            2026,
            8,
            10,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    create_watch_event(
        db_session,
        user=other_user,
        episode=episode,
        watched_at=datetime(
            2026,
            8,
            11,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    repository = EpisodeWatchEventRepository(
        db_session,
    )

    result = repository.list_all_for_user(
        user_id=user.id,
    )

    assert len(result) == 1

    assert result[0].event_id == expected_event.id
    assert result[0].season_number == 0

def test_list_all_for_user_returns_complete_episode_history(
    db_session: Session,
) -> None:
    """Return every regular Episode watch event for a user."""

    user = create_user(
        db_session,
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

    episode = create_episode(
        db_session,
        season=season,
        tmdb_id=2101,
        episode_number=1,
        title="Good News About Hell",
    )

    older_event = create_watch_event(
        db_session,
        user=user,
        episode=episode,
        watched_at=datetime(
            2026,
            8,
            1,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    newer_event = create_watch_event(
        db_session,
        user=user,
        episode=episode,
        watched_at=datetime(
            2026,
            8,
            14,
            21,
            30,
            tzinfo=UTC,
        ),
    )

    create_watch_event(
        db_session,
        user=other_user,
        episode=episode,
        watched_at=datetime(
            2026,
            8,
            15,
            21,
            30,
            tzinfo=UTC,
        ),
    )

    repository = EpisodeWatchEventRepository(
        db_session,
    )

    result = repository.list_all_for_user(
        user_id=user.id,
    )

    assert [
        item.event_id
        for item in result
    ] == [
        older_event.id,
        newer_event.id,
    ]

    assert all(
        item.show.id == show.id
        for item in result
    )

    assert all(
        item.episode.id == episode.id
        for item in result
    )

    assert all(
        item.season_number == 1
        for item in result
    )


def test_exists_at_finds_exact_episode_watch_event(
    db_session: Session,
) -> None:
    """Detect an existing Episode viewing using media and timestamp."""

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

    watched_at = datetime(
        2026,
        8,
        14,
        21,
        30,
        tzinfo=UTC,
    )

    create_watch_event(
        db_session,
        user=user,
        episode=episode,
        watched_at=watched_at,
    )

    repository = EpisodeWatchEventRepository(
        db_session,
    )

    assert repository.exists_at(
        user_id=user.id,
        episode_id=episode.id,
        watched_at=watched_at,
    )

    assert not repository.exists_at(
        user_id=user.id,
        episode_id=episode.id,
        watched_at=datetime(
            2026,
            8,
            14,
            22,
            0,
            tzinfo=UTC,
        ),
    )