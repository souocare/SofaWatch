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