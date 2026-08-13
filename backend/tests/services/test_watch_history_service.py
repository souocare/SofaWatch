from datetime import UTC, date, datetime
from types import SimpleNamespace
from unittest.mock import Mock
from uuid import UUID, uuid4

import pytest

from app.repositories.episode_progress import (
    EpisodeProgressRepository,
    WatchHistoryEpisode,
    WatchHistoryPage,
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
) -> WatchHistoryEpisode:
    return WatchHistoryEpisode(
        progress_id=uuid4(),
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
    progress_repository: Mock,
) -> WatchHistoryService:
    return WatchHistoryService(
        progress_repository=progress_repository,
    )


def test_lists_first_watch_history_page() -> None:
    progress_repository = Mock(
        spec=EpisodeProgressRepository,
    )

    history_item = create_history_item()

    progress_repository.list_watch_history.return_value = WatchHistoryPage(
        items=[history_item],
        has_more=False,
    )

    service = create_service(
        progress_repository=progress_repository,
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

    progress_repository.list_watch_history.assert_called_once_with(
        user_id=user_id,
        limit=30,
        before_watched_at=None,
        before_progress_id=None,
    )


def test_returns_next_cursor_when_more_history_exists() -> None:
    progress_repository = Mock(
        spec=EpisodeProgressRepository,
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

    progress_repository.list_watch_history.return_value = WatchHistoryPage(
        items=[
            first_item,
            second_item,
        ],
        has_more=True,
    )

    service = create_service(
        progress_repository=progress_repository,
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
    assert decoded.progress_id == second_item.progress_id


def test_decodes_cursor_and_forwards_it_to_repository() -> None:
    progress_repository = Mock(
        spec=EpisodeProgressRepository,
    )

    progress_repository.list_watch_history.return_value = WatchHistoryPage(
        items=[],
        has_more=False,
    )

    service = create_service(
        progress_repository=progress_repository,
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
        progress_id=uuid4(),
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

    progress_repository.list_watch_history.assert_called_once_with(
        user_id=user_id,
        limit=20,
        before_watched_at=cursor.watched_at,
        before_progress_id=cursor.progress_id,
    )


def test_supports_empty_watch_history() -> None:
    progress_repository = Mock(
        spec=EpisodeProgressRepository,
    )

    progress_repository.list_watch_history.return_value = WatchHistoryPage(
        items=[],
        has_more=False,
    )

    service = create_service(
        progress_repository=progress_repository,
    )

    result = service.list_for_user(
        user_id=uuid4(),
    )

    assert result.items == []
    assert result.has_more is False
    assert result.next_cursor is None


def test_invalid_cursor_is_rejected_before_repository_call() -> None:
    progress_repository = Mock(
        spec=EpisodeProgressRepository,
    )

    service = create_service(
        progress_repository=progress_repository,
    )

    with pytest.raises(
        ValueError,
        match="Invalid Watch History cursor",
    ):
        service.list_for_user(
            user_id=uuid4(),
            cursor="not-a-valid-cursor",
        )

    progress_repository.list_watch_history.assert_not_called()


def test_maps_multiple_history_items() -> None:
    progress_repository = Mock(
        spec=EpisodeProgressRepository,
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

    progress_repository.list_watch_history.return_value = WatchHistoryPage(
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

    service = create_service(
        progress_repository=progress_repository,
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