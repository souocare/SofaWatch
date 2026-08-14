from datetime import UTC, date, datetime
from types import SimpleNamespace
from unittest.mock import Mock
from uuid import UUID, uuid4

import pytest

from app.repositories.episode_watch_event import (
    EpisodeWatchEventRepository,
    WatchHistoryEvent,
    WatchHistoryEventPage,
)
from app.services.watch_history import WatchHistoryService
from app.services.watch_history_cursor import (
    WatchHistoryCursor,
    WatchHistoryCursorCodec,
)


def create_show(
    *,
    show_id: UUID | None = None,
    tmdb_id: int = 95396,
    title: str = "Severance",
) -> SimpleNamespace:
    return SimpleNamespace(
        id=show_id or uuid4(),
        tmdb_id=tmdb_id,
        title=title,
        original_title=title,
        first_air_date=date(2022, 2, 18),
        tmdb_poster_path=None,
        local_poster_path=None,
        poster_url="https://example.com/poster.jpg",
        backdrop_url="https://example.com/backdrop.jpg",
        status="Returning Series",
        vote_average=8.4,
    )


def create_episode(
    *,
    tmdb_id: int = 1947648,
    episode_number: int = 4,
    title: str = "Woe's Hollow",
) -> SimpleNamespace:
    return SimpleNamespace(
        id=uuid4(),
        tmdb_id=tmdb_id,
        episode_number=episode_number,
        title=title,
        air_date=date(2026, 8, 10),
        runtime=52,
        still_url="https://example.com/still.jpg",
    )


def create_history_item(
    *,
    show: SimpleNamespace | None = None,
    episode: SimpleNamespace | None = None,
    season_number: int = 2,
    watched_at: datetime | None = None,
) -> WatchHistoryEvent:
    return WatchHistoryEvent(
        event_id=uuid4(),
        show=show or create_show(),
        episode=episode or create_episode(),
        season_number=season_number,
        watched_at=watched_at
        or datetime(
            2026,
            8,
            13,
            20,
            0,
            tzinfo=UTC,
        ),
    )


def create_service(
    *,
    watch_event_repository: Mock,
) -> WatchHistoryService:
    watch_event_repository.get_counts_by_user_and_episode_ids.side_effect = (
        lambda *, user_id, episode_ids: {
            episode_id: 1
            for episode_id in episode_ids
        }
    )

    return WatchHistoryService(
        watch_event_repository=watch_event_repository,
    )


def test_lists_first_watch_history_page() -> None:
    watch_event_repository = Mock(
        spec=EpisodeWatchEventRepository,
    )

    history_item = create_history_item()

    watch_event_repository.list_watch_history.return_value = (
        WatchHistoryEventPage(
            items=[history_item],
            has_more=False,
        )
    )

    service = create_service(
        watch_event_repository=watch_event_repository,
    )

    user_id = uuid4()

    result = service.list_for_user(
        user_id=user_id,
        limit=30,
    )

    assert len(result.items) == 1
    assert result.has_more is False
    assert result.next_cursor is None

    item = result.items[0]

    assert item.show.id == history_item.show.id
    assert item.show.tmdb_id == 95396
    assert item.show.title == "Severance"

    assert item.episode.id == history_item.episode.id
    assert item.episode.tmdb_id == 1947648
    assert item.episode.season_number == 2
    assert item.episode.episode_number == 4
    assert item.episode.title == "Woe's Hollow"
    assert item.episode.runtime == 52
    assert item.episode.watched_at == history_item.watched_at

    watch_event_repository.list_watch_history.assert_called_once_with(
        user_id=user_id,
        limit=30,
        before_watched_at=None,
        before_event_id=None,
    )


def test_returns_next_cursor_when_more_history_exists() -> None:
    watch_event_repository = Mock(
        spec=EpisodeWatchEventRepository,
    )

    first_item = create_history_item(
        watched_at=datetime(
            2026,
            8,
            13,
            20,
            tzinfo=UTC,
        ),
    )

    second_item = create_history_item(
        watched_at=datetime(
            2026,
            8,
            12,
            20,
            tzinfo=UTC,
        ),
    )

    watch_event_repository.list_watch_history.return_value = (
        WatchHistoryEventPage(
            items=[
                first_item,
                second_item,
            ],
            has_more=True,
        )
    )

    service = create_service(
        watch_event_repository=watch_event_repository,
    )

    result = service.list_for_user(
        user_id=uuid4(),
        limit=2,
    )

    assert result.has_more is True
    assert result.next_cursor is not None

    decoded = WatchHistoryCursorCodec.decode(
        result.next_cursor,
    )

    assert decoded.watched_at == second_item.watched_at
    assert decoded.event_id == second_item.event_id


def test_decodes_cursor_and_forwards_it_to_repository() -> None:
    watch_event_repository = Mock(
        spec=EpisodeWatchEventRepository,
    )

    watch_event_repository.list_watch_history.return_value = (
        WatchHistoryEventPage(
            items=[],
            has_more=False,
        )
    )

    service = create_service(
        watch_event_repository=watch_event_repository,
    )

    user_id = uuid4()

    cursor = WatchHistoryCursor(
        watched_at=datetime(
            2026,
            8,
            10,
            18,
            tzinfo=UTC,
        ),
        event_id=uuid4(),
    )

    encoded_cursor = WatchHistoryCursorCodec.encode(
        cursor,
    )

    result = service.list_for_user(
        user_id=user_id,
        limit=20,
        cursor=encoded_cursor,
    )

    assert result.items == []
    assert result.has_more is False
    assert result.next_cursor is None

    watch_event_repository.list_watch_history.assert_called_once_with(
        user_id=user_id,
        limit=20,
        before_watched_at=cursor.watched_at,
        before_event_id=cursor.event_id,
    )


def test_supports_empty_watch_history() -> None:
    watch_event_repository = Mock(
        spec=EpisodeWatchEventRepository,
    )

    watch_event_repository.list_watch_history.return_value = (
        WatchHistoryEventPage(
            items=[],
            has_more=False,
        )
    )

    service = create_service(
        watch_event_repository=watch_event_repository,
    )

    result = service.list_for_user(
        user_id=uuid4(),
    )

    assert result.items == []
    assert result.has_more is False
    assert result.next_cursor is None


def test_invalid_cursor_is_rejected_before_repository_call() -> None:
    watch_event_repository = Mock(
        spec=EpisodeWatchEventRepository,
    )

    service = create_service(
        watch_event_repository=watch_event_repository,
    )

    with pytest.raises(
        ValueError,
        match="Invalid Watch History cursor",
    ):
        service.list_for_user(
            user_id=uuid4(),
            cursor="not-a-valid-cursor",
        )

    watch_event_repository.list_watch_history.assert_not_called()


def test_maps_multiple_history_items() -> None:
    watch_event_repository = Mock(
        spec=EpisodeWatchEventRepository,
    )

    first_show = create_show(
        tmdb_id=95396,
        title="Severance",
    )

    second_show = create_show(
        tmdb_id=100088,
        title="The Last of Us",
    )

    first_episode = create_episode(
        tmdb_id=1947648,
        episode_number=4,
        title="Woe's Hollow",
    )

    second_episode = create_episode(
        tmdb_id=3000001,
        episode_number=3,
        title="Long, Long Time",
    )

    watch_event_repository.list_watch_history.return_value = (
        WatchHistoryEventPage(
            items=[
                create_history_item(
                    show=first_show,
                    episode=first_episode,
                    season_number=2,
                ),
                create_history_item(
                    show=second_show,
                    episode=second_episode,
                    season_number=1,
                ),
            ],
            has_more=False,
        )
    )

    service = create_service(
        watch_event_repository=watch_event_repository,
    )

    result = service.list_for_user(
        user_id=uuid4(),
    )

    assert len(result.items) == 2

    assert result.items[0].show.title == "Severance"
    assert result.items[0].episode.season_number == 2
    assert result.items[0].episode.episode_number == 4

    assert result.items[1].show.title == "The Last of Us"
    assert result.items[1].episode.season_number == 1
    assert result.items[1].episode.episode_number == 3


def test_preserves_multiple_watches_of_same_episode() -> None:
    """Every viewing of the same Episode remains a separate History item."""

    watch_event_repository = Mock(
        spec=EpisodeWatchEventRepository,
    )

    show = create_show()
    episode = create_episode()

    first_watch = create_history_item(
        show=show,
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

    previous_watch = create_history_item(
        show=show,
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

    watch_event_repository.list_watch_history.return_value = (
        WatchHistoryEventPage(
            items=[
                first_watch,
                previous_watch,
            ],
            has_more=False,
        )
    )

    service = create_service(
        watch_event_repository=watch_event_repository,
    )
    watch_event_repository.get_counts_by_user_and_episode_ids.side_effect = None
    watch_event_repository.get_counts_by_user_and_episode_ids.return_value = {
        episode.id: 2,
    }

    result = service.list_for_user(
        user_id=uuid4(),
    )

    assert len(result.items) == 2

    assert result.items[0].episode.id == episode.id
    assert result.items[1].episode.id == episode.id

    assert (
        result.items[0].episode.watched_at
        == first_watch.watched_at
    )

    assert (
        result.items[1].episode.watched_at
        == previous_watch.watched_at
    )

    assert result.items[0].event_id == first_watch.event_id
    assert result.items[1].event_id == previous_watch.event_id

    assert result.items[0].episode.watch_count == 2
    assert result.items[1].episode.watch_count == 2