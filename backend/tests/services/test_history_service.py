from datetime import UTC, date, datetime
from types import SimpleNamespace
from unittest.mock import Mock
from uuid import UUID

import pytest

from app.repositories.episode_watch_event import (
    EpisodeWatchEventRepository,
    WatchHistoryEvent,
    WatchHistoryEventPage,
)
from app.repositories.movie_watch_event import (
    MovieWatchEventRepository,
    MovieWatchHistoryEvent,
    MovieWatchHistoryEventPage,
)
from app.services.history import HistoryService
from app.services.history_cursor import (
    HistoryCursor,
    HistoryCursorCodec,
)

USER_ID = UUID(
    "00000000-0000-0000-0000-000000000001",
)


def make_show(
    *,
    show_id: str,
    tmdb_id: int,
    title: str,
) -> SimpleNamespace:
    """Create Show-like data required by History response schemas."""

    return SimpleNamespace(
        id=UUID(show_id),
        tmdb_id=tmdb_id,
        title=title,
        original_title=title,
        first_air_date=date(2022, 2, 18),
        tmdb_poster_path=None,
        local_poster_path=None,
        poster_url=None,
        backdrop_url=None,
        status="Returning Series",
        vote_average=8.5,
    )


def make_episode(
    *,
    episode_id: str,
    tmdb_id: int,
    episode_number: int,
    title: str,
) -> SimpleNamespace:
    """Create Episode-like data required by History response schemas."""

    return SimpleNamespace(
        id=UUID(episode_id),
        tmdb_id=tmdb_id,
        episode_number=episode_number,
        title=title,
        air_date=date(2022, 2, 18),
        runtime=52,
        still_url=None,
    )


def make_movie(
    *,
    movie_id: str,
    tmdb_id: int,
    title: str,
) -> SimpleNamespace:
    """Create Movie-like data required by History response schemas."""

    return SimpleNamespace(
        id=UUID(movie_id),
        tmdb_id=tmdb_id,
        title=title,
        original_title=title,
        release_date=date(2021, 10, 22),
        tmdb_poster_path=None,
        local_poster_path=None,
        poster_url=None,
        backdrop_url=None,
        status="Released",
        vote_average=8.0,
    )


def make_episode_history_event(
    *,
    event_id: str,
    watched_at: datetime,
    show_id: str = "10000000-0000-0000-0000-000000000001",
    show_tmdb_id: int = 95396,
    show_title: str = "Severance",
    episode_id: str = "20000000-0000-0000-0000-000000000001",
    episode_tmdb_id: int = 2101,
    season_number: int = 1,
    episode_number: int = 1,
    episode_title: str = "Good News About Hell",
) -> WatchHistoryEvent:
    """Create one historical Episode viewing."""

    return WatchHistoryEvent(
        event_id=UUID(event_id),
        show=make_show(
            show_id=show_id,
            tmdb_id=show_tmdb_id,
            title=show_title,
        ),
        episode=make_episode(
            episode_id=episode_id,
            tmdb_id=episode_tmdb_id,
            episode_number=episode_number,
            title=episode_title,
        ),
        season_number=season_number,
        watched_at=watched_at,
    )


def make_movie_history_event(
    *,
    event_id: str,
    watched_at: datetime,
    movie_id: str = "30000000-0000-0000-0000-000000000001",
    movie_tmdb_id: int = 438631,
    movie_title: str = "Dune",
) -> MovieWatchHistoryEvent:
    """Create one historical Movie viewing."""

    return MovieWatchHistoryEvent(
        event_id=UUID(event_id),
        movie=make_movie(
            movie_id=movie_id,
            tmdb_id=movie_tmdb_id,
            title=movie_title,
        ),
        watched_at=watched_at,
    )


@pytest.fixture
def episode_repository() -> Mock:
    """Provide a mocked Episode watch-event repository."""

    return Mock(
        spec=EpisodeWatchEventRepository,
    )


@pytest.fixture
def movie_repository() -> Mock:
    """Provide a mocked Movie watch-event repository."""

    return Mock(
        spec=MovieWatchEventRepository,
    )


@pytest.fixture
def service(
    episode_repository: Mock,
    movie_repository: Mock,
) -> HistoryService:
    """Provide HistoryService with mocked persistence dependencies."""

    return HistoryService(
        episode_watch_event_repository=episode_repository,
        movie_watch_event_repository=movie_repository,
    )


def test_get_preview_returns_recent_episode_and_movie_history(
    service: HistoryService,
    episode_repository: Mock,
    movie_repository: Mock,
) -> None:
    """Return independent compact Episode and Movie preview collections."""

    episode_event = make_episode_history_event(
        event_id="40000000-0000-0000-0000-000000000001",
        watched_at=datetime(
            2026,
            8,
            19,
            18,
            0,
            tzinfo=UTC,
        ),
    )

    movie_event = make_movie_history_event(
        event_id="50000000-0000-0000-0000-000000000001",
        watched_at=datetime(
            2026,
            8,
            19,
            17,
            0,
            tzinfo=UTC,
        ),
    )

    episode_repository.list_watch_history.return_value = WatchHistoryEventPage(
        items=[
            episode_event,
        ],
        has_more=False,
    )

    movie_repository.list_watch_history.return_value = MovieWatchHistoryEventPage(
        items=[
            movie_event,
        ],
        has_more=False,
    )

    result = service.get_preview(
        user_id=USER_ID,
    )

    assert len(result.episodes) == 1
    assert len(result.movies) == 1

    episode_item = result.episodes[0]

    assert episode_item.media_type == "episode"
    assert episode_item.event_id == episode_event.event_id
    assert episode_item.watched_at == episode_event.watched_at

    assert episode_item.show.tmdb_id == 95396
    assert episode_item.show.title == "Severance"

    assert episode_item.episode.tmdb_id == 2101
    assert episode_item.episode.season_number == 1
    assert episode_item.episode.episode_number == 1
    assert episode_item.episode.title == "Good News About Hell"

    movie_item = result.movies[0]

    assert movie_item.media_type == "movie"
    assert movie_item.event_id == movie_event.event_id
    assert movie_item.watched_at == movie_event.watched_at

    assert movie_item.movie.tmdb_id == 438631
    assert movie_item.movie.title == "Dune"

    episode_repository.list_watch_history.assert_called_once_with(
        user_id=USER_ID,
        limit=5,
    )

    movie_repository.list_watch_history.assert_called_once_with(
        user_id=USER_ID,
        limit=5,
    )


def test_get_preview_forwards_custom_limit(
    service: HistoryService,
    episode_repository: Mock,
    movie_repository: Mock,
) -> None:
    """Forward the requested preview limit independently to both sources."""

    episode_repository.list_watch_history.return_value = WatchHistoryEventPage(
        items=[],
        has_more=False,
    )

    movie_repository.list_watch_history.return_value = MovieWatchHistoryEventPage(
        items=[],
        has_more=False,
    )

    result = service.get_preview(
        user_id=USER_ID,
        limit=3,
    )

    assert result.episodes == []
    assert result.movies == []

    episode_repository.list_watch_history.assert_called_once_with(
        user_id=USER_ID,
        limit=3,
    )

    movie_repository.list_watch_history.assert_called_once_with(
        user_id=USER_ID,
        limit=3,
    )


def test_get_preview_supports_empty_history(
    service: HistoryService,
    episode_repository: Mock,
    movie_repository: Mock,
) -> None:
    """Return usable empty preview collections."""

    episode_repository.list_watch_history.return_value = WatchHistoryEventPage(
        items=[],
        has_more=False,
    )

    movie_repository.list_watch_history.return_value = MovieWatchHistoryEventPage(
        items=[],
        has_more=False,
    )

    result = service.get_preview(
        user_id=USER_ID,
    )

    assert result.episodes == []
    assert result.movies == []


def test_list_for_user_merges_episode_and_movie_history_newest_first(
    service: HistoryService,
    episode_repository: Mock,
    movie_repository: Mock,
) -> None:
    """Merge both History sources into one globally ordered timeline."""

    newest_movie = make_movie_history_event(
        event_id="50000000-0000-0000-0000-000000000003",
        watched_at=datetime(
            2026,
            8,
            19,
            22,
            0,
            tzinfo=UTC,
        ),
        movie_id="30000000-0000-0000-0000-000000000003",
        movie_tmdb_id=329865,
        movie_title="Arrival",
    )

    middle_episode = make_episode_history_event(
        event_id="40000000-0000-0000-0000-000000000002",
        watched_at=datetime(
            2026,
            8,
            19,
            21,
            0,
            tzinfo=UTC,
        ),
    )

    oldest_movie = make_movie_history_event(
        event_id="50000000-0000-0000-0000-000000000001",
        watched_at=datetime(
            2026,
            8,
            19,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    episode_repository.list_watch_history.return_value = WatchHistoryEventPage(
        items=[
            middle_episode,
        ],
        has_more=False,
    )

    movie_repository.list_watch_history.return_value = MovieWatchHistoryEventPage(
        items=[
            newest_movie,
            oldest_movie,
        ],
        has_more=False,
    )

    result = service.list_for_user(
        user_id=USER_ID,
        limit=10,
    )

    assert len(result.items) == 3

    assert [item.media_type for item in result.items] == [
        "movie",
        "episode",
        "movie",
    ]

    assert [item.event_id for item in result.items] == [
        newest_movie.event_id,
        middle_episode.event_id,
        oldest_movie.event_id,
    ]

    assert result.has_more is False
    assert result.next_cursor is None


def test_list_for_user_preserves_rewatches_as_independent_items(
    service: HistoryService,
    episode_repository: Mock,
    movie_repository: Mock,
) -> None:
    """Keep every real viewing event, including Rewatches."""

    newer_episode_watch = make_episode_history_event(
        event_id="40000000-0000-0000-0000-000000000002",
        watched_at=datetime(
            2026,
            8,
            19,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    older_episode_watch = make_episode_history_event(
        event_id="40000000-0000-0000-0000-000000000001",
        watched_at=datetime(
            2026,
            8,
            10,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    newer_movie_watch = make_movie_history_event(
        event_id="50000000-0000-0000-0000-000000000002",
        watched_at=datetime(
            2026,
            8,
            18,
            21,
            0,
            tzinfo=UTC,
        ),
    )

    older_movie_watch = make_movie_history_event(
        event_id="50000000-0000-0000-0000-000000000001",
        watched_at=datetime(
            2026,
            8,
            5,
            21,
            0,
            tzinfo=UTC,
        ),
    )

    episode_repository.list_watch_history.return_value = WatchHistoryEventPage(
        items=[
            newer_episode_watch,
            older_episode_watch,
        ],
        has_more=False,
    )

    movie_repository.list_watch_history.return_value = MovieWatchHistoryEventPage(
        items=[
            newer_movie_watch,
            older_movie_watch,
        ],
        has_more=False,
    )

    result = service.list_for_user(
        user_id=USER_ID,
        limit=10,
    )

    assert len(result.items) == 4

    assert {item.event_id for item in result.items} == {
        newer_episode_watch.event_id,
        older_episode_watch.event_id,
        newer_movie_watch.event_id,
        older_movie_watch.event_id,
    }


def test_list_for_user_returns_empty_history(
    service: HistoryService,
    episode_repository: Mock,
    movie_repository: Mock,
) -> None:
    """Return a usable empty combined History."""

    episode_repository.list_watch_history.return_value = WatchHistoryEventPage(
        items=[],
        has_more=False,
    )

    movie_repository.list_watch_history.return_value = MovieWatchHistoryEventPage(
        items=[],
        has_more=False,
    )

    result = service.list_for_user(
        user_id=USER_ID,
    )

    assert result.items == []
    assert result.next_cursor is None
    assert result.has_more is False


def test_list_for_user_returns_empty_page_for_non_positive_limit(
    service: HistoryService,
    episode_repository: Mock,
    movie_repository: Mock,
) -> None:
    """Do not query persistence for an unusable page size."""

    result = service.list_for_user(
        user_id=USER_ID,
        limit=0,
    )

    assert result.items == []
    assert result.next_cursor is None
    assert result.has_more is False

    episode_repository.list_watch_history.assert_not_called()
    movie_repository.list_watch_history.assert_not_called()


def test_list_for_user_limits_combined_page_and_returns_cursor(
    service: HistoryService,
    episode_repository: Mock,
    movie_repository: Mock,
) -> None:
    """Apply the limit after globally merging both History sources."""

    episode_event = make_episode_history_event(
        event_id="40000000-0000-0000-0000-000000000001",
        watched_at=datetime(
            2026,
            8,
            19,
            21,
            0,
            tzinfo=UTC,
        ),
    )

    newest_movie = make_movie_history_event(
        event_id="50000000-0000-0000-0000-000000000002",
        watched_at=datetime(
            2026,
            8,
            19,
            22,
            0,
            tzinfo=UTC,
        ),
    )

    oldest_movie = make_movie_history_event(
        event_id="50000000-0000-0000-0000-000000000001",
        watched_at=datetime(
            2026,
            8,
            19,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    episode_repository.list_watch_history.return_value = WatchHistoryEventPage(
        items=[
            episode_event,
        ],
        has_more=False,
    )

    movie_repository.list_watch_history.return_value = MovieWatchHistoryEventPage(
        items=[
            newest_movie,
            oldest_movie,
        ],
        has_more=False,
    )

    result = service.list_for_user(
        user_id=USER_ID,
        limit=2,
    )

    assert [item.event_id for item in result.items] == [
        newest_movie.event_id,
        episode_event.event_id,
    ]

    assert result.has_more is True
    assert result.next_cursor is not None

    decoded = HistoryCursorCodec.decode(
        result.next_cursor,
    )

    assert decoded == HistoryCursor(
        watched_at=episode_event.watched_at,
        media_type="episode",
        event_id=episode_event.event_id,
    )

    episode_repository.list_watch_history.assert_called_once_with(
        user_id=USER_ID,
        limit=3,
    )

    movie_repository.list_watch_history.assert_called_once_with(
        user_id=USER_ID,
        limit=3,
    )


def test_list_for_user_applies_combined_cursor_without_duplicates(
    service: HistoryService,
    episode_repository: Mock,
    movie_repository: Mock,
) -> None:
    """Exclude events at or newer than the combined cursor."""

    cursor_episode = make_episode_history_event(
        event_id="40000000-0000-0000-0000-000000000002",
        watched_at=datetime(
            2026,
            8,
            19,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    older_episode = make_episode_history_event(
        event_id="40000000-0000-0000-0000-000000000001",
        watched_at=datetime(
            2026,
            8,
            19,
            18,
            0,
            tzinfo=UTC,
        ),
    )

    older_movie = make_movie_history_event(
        event_id="50000000-0000-0000-0000-000000000001",
        watched_at=datetime(
            2026,
            8,
            19,
            19,
            0,
            tzinfo=UTC,
        ),
    )

    episode_repository.list_watch_history.return_value = WatchHistoryEventPage(
        items=[
            older_episode,
        ],
        has_more=False,
    )

    movie_repository.list_watch_history_before_timestamp.return_value = MovieWatchHistoryEventPage(
        items=[
            older_movie,
        ],
        has_more=False,
    )

    cursor = HistoryCursorCodec.encode(
        HistoryCursor(
            watched_at=cursor_episode.watched_at,
            media_type="episode",
            event_id=cursor_episode.event_id,
        )
    )

    result = service.list_for_user(
        user_id=USER_ID,
        limit=10,
        cursor=cursor,
    )

    assert [item.event_id for item in result.items] == [
        older_movie.event_id,
        older_episode.event_id,
    ]

    assert cursor_episode.event_id not in {item.event_id for item in result.items}

    assert result.has_more is False
    assert result.next_cursor is None

    episode_repository.list_watch_history.assert_called_once_with(
        user_id=USER_ID,
        limit=11,
        before_watched_at=cursor_episode.watched_at,
        before_event_id=cursor_episode.event_id,
    )

    movie_repository.list_watch_history_before_timestamp.assert_called_once_with(
        user_id=USER_ID,
        limit=11,
        watched_at=cursor_episode.watched_at,
        inclusive=False,
    )


def test_list_for_user_uses_media_type_and_event_id_to_break_timestamp_ties(
    service: HistoryService,
    episode_repository: Mock,
    movie_repository: Mock,
) -> None:
    """Keep pagination deterministic when several events share watched_at."""

    watched_at = datetime(
        2026,
        8,
        19,
        20,
        0,
        tzinfo=UTC,
    )

    episode_event = make_episode_history_event(
        event_id="40000000-0000-0000-0000-000000000001",
        watched_at=watched_at,
    )

    movie_event = make_movie_history_event(
        event_id="50000000-0000-0000-0000-000000000001",
        watched_at=watched_at,
    )

    # First page has no cursor, so both repositories use their normal
    # newest-first History query.
    episode_repository.list_watch_history.return_value = WatchHistoryEventPage(
        items=[
            episode_event,
        ],
        has_more=False,
    )

    movie_repository.list_watch_history.return_value = MovieWatchHistoryEventPage(
        items=[
            movie_event,
        ],
        has_more=False,
    )

    first_page = service.list_for_user(
        user_id=USER_ID,
        limit=1,
    )

    assert len(first_page.items) == 1
    assert first_page.items[0].media_type == "movie"
    assert first_page.items[0].event_id == movie_event.event_id

    assert first_page.has_more is True
    assert first_page.next_cursor is not None

    # The cursor belongs to a Movie at this timestamp.
    #
    # Episodes at the exact same watched_at must remain eligible because
    # "movie" sorts after "episode" in the combined deterministic key.
    episode_repository.list_watch_history_before_timestamp.return_value = WatchHistoryEventPage(
        items=[
            episode_event,
        ],
        has_more=False,
    )

    # Movies use their own event-id cursor and therefore must exclude the
    # Movie that produced the previous page cursor.
    movie_repository.list_watch_history.return_value = MovieWatchHistoryEventPage(
        items=[],
        has_more=False,
    )

    second_page = service.list_for_user(
        user_id=USER_ID,
        limit=1,
        cursor=first_page.next_cursor,
    )

    assert len(second_page.items) == 1
    assert second_page.items[0].media_type == "episode"
    assert second_page.items[0].event_id == episode_event.event_id

    assert second_page.has_more is False
    assert second_page.next_cursor is None

    episode_repository.list_watch_history_before_timestamp.assert_called_once_with(
        user_id=USER_ID,
        limit=2,
        watched_at=watched_at,
        inclusive=True,
    )

    assert movie_repository.list_watch_history.call_count == 2

    assert movie_repository.list_watch_history.call_args_list[1].kwargs == {
        "user_id": USER_ID,
        "limit": 2,
        "before_watched_at": watched_at,
        "before_event_id": movie_event.event_id,
    }


def test_list_for_user_orders_same_media_type_timestamp_by_event_id(
    service: HistoryService,
    episode_repository: Mock,
    movie_repository: Mock,
) -> None:
    """Use event ID as the final deterministic ordering component."""

    watched_at = datetime(
        2026,
        8,
        19,
        20,
        0,
        tzinfo=UTC,
    )

    lower_id_event = make_episode_history_event(
        event_id="40000000-0000-0000-0000-000000000001",
        watched_at=watched_at,
    )

    higher_id_event = make_episode_history_event(
        event_id="40000000-0000-0000-0000-000000000002",
        watched_at=watched_at,
    )

    episode_repository.list_watch_history.return_value = WatchHistoryEventPage(
        items=[
            lower_id_event,
            higher_id_event,
        ],
        has_more=False,
    )

    movie_repository.list_watch_history.return_value = MovieWatchHistoryEventPage(
        items=[],
        has_more=False,
    )

    result = service.list_for_user(
        user_id=USER_ID,
        limit=10,
    )

    assert [item.event_id for item in result.items] == [
        higher_id_event.event_id,
        lower_id_event.event_id,
    ]


def test_list_for_user_forwards_current_user_to_both_repositories(
    service: HistoryService,
    episode_repository: Mock,
    movie_repository: Mock,
) -> None:
    """Scope every History source to the requested user."""

    episode_repository.list_watch_history.return_value = WatchHistoryEventPage(
        items=[],
        has_more=False,
    )

    movie_repository.list_watch_history.return_value = MovieWatchHistoryEventPage(
        items=[],
        has_more=False,
    )

    service.list_for_user(
        user_id=USER_ID,
        limit=20,
    )

    episode_repository.list_watch_history.assert_called_once_with(
        user_id=USER_ID,
        limit=21,
    )

    movie_repository.list_watch_history.assert_called_once_with(
        user_id=USER_ID,
        limit=21,
    )


def test_invalid_cursor_is_rejected_before_repository_calls(
    service: HistoryService,
    episode_repository: Mock,
    movie_repository: Mock,
) -> None:
    """Reject malformed combined History cursors before querying persistence."""

    with pytest.raises(ValueError):
        service.list_for_user(
            user_id=USER_ID,
            cursor="not-a-valid-history-cursor",
        )

    episode_repository.list_watch_history.assert_not_called()
    movie_repository.list_watch_history.assert_not_called()


def test_list_for_user_can_return_only_episode_history(
    service: HistoryService,
    episode_repository: Mock,
    movie_repository: Mock,
) -> None:
    """Return only Episode events when Episode History is requested."""

    newer_event = make_episode_history_event(
        event_id="40000000-0000-0000-0000-000000000002",
        watched_at=datetime(
            2026,
            8,
            19,
            21,
            0,
            tzinfo=UTC,
        ),
    )

    older_event = make_episode_history_event(
        event_id="40000000-0000-0000-0000-000000000001",
        watched_at=datetime(
            2026,
            8,
            19,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    episode_repository.list_watch_history.return_value = WatchHistoryEventPage(
        items=[
            newer_event,
            older_event,
        ],
        has_more=False,
    )

    result = service.list_for_user(
        user_id=USER_ID,
        limit=10,
        media_type="episode",
    )

    assert [item.event_id for item in result.items] == [
        newer_event.event_id,
        older_event.event_id,
    ]

    assert all(item.media_type == "episode" for item in result.items)
    assert result.has_more is False
    assert result.next_cursor is None

    episode_repository.list_watch_history.assert_called_once_with(
        user_id=USER_ID,
        limit=11,
        before_watched_at=None,
        before_event_id=None,
    )

    movie_repository.list_watch_history.assert_not_called()

def test_list_for_user_can_return_only_movie_history(
    service: HistoryService,
    episode_repository: Mock,
    movie_repository: Mock,
) -> None:
    """Return only Movie events when Movie History is requested."""

    newer_event = make_movie_history_event(
        event_id="50000000-0000-0000-0000-000000000002",
        watched_at=datetime(
            2026,
            8,
            19,
            21,
            0,
            tzinfo=UTC,
        ),
    )

    older_event = make_movie_history_event(
        event_id="50000000-0000-0000-0000-000000000001",
        watched_at=datetime(
            2026,
            8,
            19,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    movie_repository.list_watch_history.return_value = (
        MovieWatchHistoryEventPage(
            items=[
                newer_event,
                older_event,
            ],
            has_more=False,
        )
    )

    result = service.list_for_user(
        user_id=USER_ID,
        limit=10,
        media_type="movie",
    )

    assert [item.event_id for item in result.items] == [
        newer_event.event_id,
        older_event.event_id,
    ]

    assert all(item.media_type == "movie" for item in result.items)
    assert result.has_more is False
    assert result.next_cursor is None

    movie_repository.list_watch_history.assert_called_once_with(
        user_id=USER_ID,
        limit=11,
        before_watched_at=None,
        before_event_id=None,
    )

    episode_repository.list_watch_history.assert_not_called()


def test_list_for_user_paginates_episode_history(
    service: HistoryService,
    episode_repository: Mock,
    movie_repository: Mock,
) -> None:
    """Continue Episode-only History with an Episode cursor."""

    cursor_event = make_episode_history_event(
        event_id="40000000-0000-0000-0000-000000000002",
        watched_at=datetime(
            2026,
            8,
            19,
            21,
            0,
            tzinfo=UTC,
        ),
    )

    older_event = make_episode_history_event(
        event_id="40000000-0000-0000-0000-000000000001",
        watched_at=datetime(
            2026,
            8,
            19,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    cursor = HistoryCursorCodec.encode(
        HistoryCursor(
            watched_at=cursor_event.watched_at,
            media_type="episode",
            event_id=cursor_event.event_id,
        )
    )

    episode_repository.list_watch_history.return_value = WatchHistoryEventPage(
        items=[older_event],
        has_more=False,
    )

    result = service.list_for_user(
        user_id=USER_ID,
        limit=10,
        cursor=cursor,
        media_type="episode",
    )

    assert [item.event_id for item in result.items] == [
        older_event.event_id,
    ]

    assert result.has_more is False
    assert result.next_cursor is None

    episode_repository.list_watch_history.assert_called_once_with(
        user_id=USER_ID,
        limit=11,
        before_watched_at=cursor_event.watched_at,
        before_event_id=cursor_event.event_id,
    )

    movie_repository.list_watch_history.assert_not_called()

def test_list_for_user_rejects_movie_cursor_for_episode_history(
    service: HistoryService,
    episode_repository: Mock,
    movie_repository: Mock,
) -> None:
    """Reject a cursor belonging to another History media type."""

    cursor = HistoryCursorCodec.encode(
        HistoryCursor(
            watched_at=datetime(
                2026,
                8,
                19,
                21,
                0,
                tzinfo=UTC,
            ),
            media_type="movie",
            event_id=UUID(
                "50000000-0000-0000-0000-000000000001"
            ),
        )
    )

    with pytest.raises(ValueError):
        service.list_for_user(
            user_id=USER_ID,
            cursor=cursor,
            media_type="episode",
        )

    episode_repository.list_watch_history.assert_not_called()
    movie_repository.list_watch_history.assert_not_called()


