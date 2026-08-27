from datetime import UTC, date, datetime
from typing import cast
from uuid import UUID, uuid4

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.api.dependencies import get_season_episode_sync_service
from app.models.episode import Episode
from app.models.episode_progress import EpisodeProgress
from app.models.episode_watch_event import EpisodeWatchEvent
from app.models.season import Season
from app.models.show import Show
from app.models.user import User


def create_local_show(
    db_session: Session,
    *,
    tmdb_id: int,
    title: str,
) -> Show:
    """Create and persist a locally stored TV series for route tests."""

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


def create_local_season(
    db_session: Session,
    *,
    show: Show,
    tmdb_id: int,
    season_number: int,
    title: str,
) -> Season:
    """Create and persist a locally stored TV season for route tests."""

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


def create_local_user(
    db_session: Session,
) -> User:
    """Create and persist a user for Season route tests."""

    user = User(
        display_name="Local User",
    )

    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)

    return user


def create_episode_progress(
    db_session: Session,
    *,
    user: User,
    episode: Episode,
    is_watched: bool,
    watched_at: datetime | None = None,
) -> EpisodeProgress:
    """Create and persist episode viewing progress."""

    progress = EpisodeProgress(
        user_id=user.id,
        episode_id=episode.id,
        is_watched=is_watched,
        watched_at=watched_at,
    )

    db_session.add(progress)
    db_session.commit()
    db_session.refresh(progress)

    return progress


class FakeSeasonEpisodeSyncService:
    """Controllable Season Episode sync service for route tests."""

    def __init__(
        self,
        *,
        episodes: list[Episode] | None = None,
        season_exists: bool = True,
    ) -> None:
        self.episodes = episodes or []
        self.season_exists = season_exists

        self.requested_season_ids: list[UUID] = []

    def sync(
        self,
        *,
        season_id: UUID,
        language: str | None = None,
    ) -> list[Episode] | None:
        self.requested_season_ids.append(
            season_id,
        )

        if not self.season_exists:
            return None

        return self.episodes


def override_season_episode_sync_service(
    client: TestClient,
    service: FakeSeasonEpisodeSyncService,
) -> FastAPI:
    """Override the Season Episode sync dependency for one route test."""

    app = cast(
        FastAPI,
        client.app,
    )

    app.dependency_overrides[get_season_episode_sync_service] = lambda: service

    return app


def create_local_episode(
    db_session: Session,
    *,
    season: Season,
    tmdb_id: int,
    episode_number: int,
    title: str,
    overview: str | None = None,
    air_date: date | None = None,
    runtime: int | None = None,
    vote_average: float = 0.0,
    vote_count: int = 0,
    tmdb_still_path: str | None = None,
    local_still_path: str | None = None,
) -> Episode:
    """Create and persist a locally stored TV episode for route tests."""

    episode = Episode(
        season_id=season.id,
        tmdb_id=tmdb_id,
        episode_number=episode_number,
        title=title,
        overview=overview,
        air_date=air_date,
        runtime=runtime,
        vote_average=vote_average,
        vote_count=vote_count,
        tmdb_still_path=tmdb_still_path,
        local_still_path=local_still_path,
    )

    db_session.add(episode)
    db_session.commit()
    db_session.refresh(episode)

    return episode


def test_list_season_episodes_returns_empty_list(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return an empty list when the season has no episodes."""

    show = create_local_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    season = create_local_season(
        db_session,
        show=show,
        tmdb_id=134792,
        season_number=1,
        title="Season 1",
    )

    response = client.get(
        f"/api/v1/seasons/{season.id}/episodes",
    )

    assert response.status_code == 200
    assert response.json() == []


def test_list_season_episodes_returns_stored_episodes(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return the locally stored episodes belonging to a season."""

    show = create_local_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    season = create_local_season(
        db_session,
        show=show,
        tmdb_id=134792,
        season_number=1,
        title="Season 1",
    )

    episode = create_local_episode(
        db_session,
        season=season,
        tmdb_id=2101,
        episode_number=1,
        title="Good News About Hell",
        overview="Mark starts a new day at Lumon.",
        air_date=date(2022, 2, 18),
        runtime=57,
        vote_average=8.1,
        vote_count=42,
        tmdb_still_path="/episode-1.jpg",
    )

    response = client.get(
        f"/api/v1/seasons/{season.id}/episodes",
    )

    assert response.status_code == 200

    body = response.json()

    assert len(body) == 1

    assert body[0] == {
        "id": str(episode.id),
        "tmdb_id": 2101,
        "episode_number": 1,
        "title": "Good News About Hell",
        "overview": "Mark starts a new day at Lumon.",
        "air_date": "2022-02-18",
        "runtime": 57,
        "vote_average": 8.1,
        "vote_count": 42,
        "tmdb_still_path": "/episode-1.jpg",
        "local_still_path": None,
        "still_url": (f"/api/v1/images/episodes/{episode.id}/still"),
    }


def test_list_season_episodes_orders_by_episode_number(
    client: TestClient,
    db_session: Session,
) -> None:
    """Order episodes by episode number in ascending order."""

    show = create_local_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    season = create_local_season(
        db_session,
        show=show,
        tmdb_id=134792,
        season_number=1,
        title="Season 1",
    )

    create_local_episode(
        db_session,
        season=season,
        tmdb_id=2103,
        episode_number=3,
        title="Episode 3",
    )
    create_local_episode(
        db_session,
        season=season,
        tmdb_id=2101,
        episode_number=1,
        title="Episode 1",
    )
    create_local_episode(
        db_session,
        season=season,
        tmdb_id=2102,
        episode_number=2,
        title="Episode 2",
    )

    response = client.get(
        f"/api/v1/seasons/{season.id}/episodes",
    )

    assert response.status_code == 200

    body = response.json()

    assert [episode["episode_number"] for episode in body] == [
        1,
        2,
        3,
    ]


def test_list_season_episodes_only_returns_requested_season(
    client: TestClient,
    db_session: Session,
) -> None:
    """Do not return episodes belonging to another season."""

    show = create_local_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    first_season = create_local_season(
        db_session,
        show=show,
        tmdb_id=1001,
        season_number=1,
        title="Season 1",
    )

    second_season = create_local_season(
        db_session,
        show=show,
        tmdb_id=1002,
        season_number=2,
        title="Season 2",
    )

    create_local_episode(
        db_session,
        season=first_season,
        tmdb_id=2001,
        episode_number=1,
        title="First Season Episode",
    )

    create_local_episode(
        db_session,
        season=second_season,
        tmdb_id=3001,
        episode_number=1,
        title="Second Season Episode",
    )

    response = client.get(
        f"/api/v1/seasons/{first_season.id}/episodes",
    )

    assert response.status_code == 200

    body = response.json()

    assert len(body) == 1
    assert body[0]["title"] == "First Season Episode"
    assert body[0]["tmdb_id"] == 2001


def test_list_season_episodes_serializes_optional_fields_as_null(
    client: TestClient,
    db_session: Session,
) -> None:
    """Serialize missing optional episode metadata as null."""

    show = create_local_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    season = create_local_season(
        db_session,
        show=show,
        tmdb_id=134792,
        season_number=1,
        title="Season 1",
    )

    episode = create_local_episode(
        db_session,
        season=season,
        tmdb_id=2101,
        episode_number=1,
        title="Future Episode",
        overview=None,
        air_date=None,
        runtime=None,
        vote_average=0.0,
        vote_count=0,
        tmdb_still_path=None,
        local_still_path=None,
    )

    response = client.get(
        f"/api/v1/seasons/{season.id}/episodes",
    )

    assert response.status_code == 200

    body = response.json()

    assert body[0] == {
        "id": str(episode.id),
        "tmdb_id": 2101,
        "episode_number": 1,
        "title": "Future Episode",
        "overview": None,
        "air_date": None,
        "runtime": None,
        "vote_average": 0.0,
        "vote_count": 0,
        "tmdb_still_path": None,
        "local_still_path": None,
        "still_url": None,
    }


def test_list_season_episodes_returns_404_when_season_does_not_exist(
    client: TestClient,
) -> None:
    """Return HTTP 404 when the local TV season does not exist."""

    response = client.get(
        f"/api/v1/seasons/{uuid4()}/episodes",
    )

    assert response.status_code == 404
    assert response.json() == {
        "error": {
            "code": "season_not_found",
            "message": "TV season not found.",
        }
    }


@pytest.mark.parametrize(
    "season_id",
    [
        "not-a-valid-uuid",
        "123",
        "invalid",
    ],
)
def test_list_season_episodes_rejects_invalid_season_id(
    client: TestClient,
    season_id: str,
) -> None:
    """Reject an invalid local TV season identifier."""

    response = client.get(
        f"/api/v1/seasons/{season_id}/episodes",
    )

    assert response.status_code == 422


def test_sync_season_episodes_returns_synced_episodes(
    client: TestClient,
    db_session: Session,
) -> None:
    """Synchronize one Season and return its locally stored Episodes."""

    show = create_local_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    season = create_local_season(
        db_session,
        show=show,
        tmdb_id=134792,
        season_number=1,
        title="Season 1",
    )

    episode = create_local_episode(
        db_session,
        season=season,
        tmdb_id=2101,
        episode_number=1,
        title="Good News About Hell",
        overview="Mark starts a new day at Lumon.",
        air_date=date(2022, 2, 18),
        runtime=57,
        vote_average=8.1,
        vote_count=42,
        tmdb_still_path="/episode-1.jpg",
    )

    sync_service = FakeSeasonEpisodeSyncService(
        episodes=[episode],
    )

    app = override_season_episode_sync_service(
        client,
        sync_service,
    )

    try:
        response = client.post(
            f"/api/v1/seasons/{season.id}/sync",
        )
    finally:
        app.dependency_overrides.pop(
            get_season_episode_sync_service,
            None,
        )

    assert response.status_code == 200

    body = response.json()

    assert len(body) == 1

    assert body[0] == {
        "id": str(episode.id),
        "tmdb_id": 2101,
        "episode_number": 1,
        "title": "Good News About Hell",
        "overview": "Mark starts a new day at Lumon.",
        "air_date": "2022-02-18",
        "runtime": 57,
        "vote_average": 8.1,
        "vote_count": 42,
        "tmdb_still_path": "/episode-1.jpg",
        "local_still_path": None,
        "still_url": (f"/api/v1/images/episodes/{episode.id}/still"),
    }


def test_sync_season_episodes_syncs_only_requested_season(
    client: TestClient,
    db_session: Session,
) -> None:
    """Forward only the requested local Season identifier to the sync service."""

    show = create_local_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    first_season = create_local_season(
        db_session,
        show=show,
        tmdb_id=1001,
        season_number=1,
        title="Season 1",
    )

    create_local_season(
        db_session,
        show=show,
        tmdb_id=1002,
        season_number=2,
        title="Season 2",
    )

    sync_service = FakeSeasonEpisodeSyncService()

    app = override_season_episode_sync_service(
        client,
        sync_service,
    )

    try:
        response = client.post(
            f"/api/v1/seasons/{first_season.id}/sync",
        )
    finally:
        app.dependency_overrides.pop(
            get_season_episode_sync_service,
            None,
        )

    assert response.status_code == 200
    assert response.json() == []

    assert sync_service.requested_season_ids == [
        first_season.id,
    ]


def test_sync_season_episodes_returns_404_when_season_does_not_exist(
    client: TestClient,
) -> None:
    """Return HTTP 404 when the Season cannot be resolved by the sync service."""

    season_id = uuid4()

    sync_service = FakeSeasonEpisodeSyncService(
        season_exists=False,
    )

    app = override_season_episode_sync_service(
        client,
        sync_service,
    )

    try:
        response = client.post(
            f"/api/v1/seasons/{season_id}/sync",
        )
    finally:
        app.dependency_overrides.pop(
            get_season_episode_sync_service,
            None,
        )

    assert response.status_code == 404

    assert response.json() == {
        "error": {
            "code": "season_not_found",
            "message": "TV season not found.",
        }
    }

    assert sync_service.requested_season_ids == [
        season_id,
    ]


@pytest.mark.parametrize(
    "season_id",
    [
        "not-a-valid-uuid",
        "123",
        "invalid",
    ],
)
def test_sync_season_episodes_rejects_invalid_season_id(
    client: TestClient,
    season_id: str,
) -> None:
    """Reject an invalid local Season identifier."""

    response = client.post(
        f"/api/v1/seasons/{season_id}/sync",
    )

    assert response.status_code == 422


def test_list_season_episode_progress_returns_user_progress(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return current progress and historical watch count for the user."""

    user = create_local_user(db_session)

    show = create_local_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    season = create_local_season(
        db_session,
        show=show,
        tmdb_id=134792,
        season_number=1,
        title="Season 1",
    )

    watched_episode = create_local_episode(
        db_session,
        season=season,
        tmdb_id=2101,
        episode_number=1,
        title="Good News About Hell",
    )

    create_local_episode(
        db_session,
        season=season,
        tmdb_id=2102,
        episode_number=2,
        title="Half Loop",
    )

    first_watched_at = datetime(
        2026,
        7,
        10,
        21,
        30,
        tzinfo=UTC,
    )

    latest_watched_at = datetime(
        2026,
        8,
        10,
        21,
        30,
        tzinfo=UTC,
    )

    progress = create_episode_progress(
        db_session,
        user=user,
        episode=watched_episode,
        is_watched=True,
        watched_at=latest_watched_at,
    )

    db_session.add_all(
        [
            EpisodeWatchEvent(
                user_id=user.id,
                episode_id=watched_episode.id,
                watched_at=first_watched_at,
            ),
            EpisodeWatchEvent(
                user_id=user.id,
                episode_id=watched_episode.id,
                watched_at=latest_watched_at,
            ),
        ]
    )

    db_session.commit()

    response = client.get(
        f"/api/v1/seasons/{season.id}/episodes/progress",
    )

    assert response.status_code == 200

    body = response.json()

    assert len(body) == 1

    assert body[0]["id"] == str(progress.id)
    assert body[0]["episode_id"] == str(watched_episode.id)

    assert body[0]["is_watched"] is True
    assert body[0]["watched_at"] is not None

    assert body[0]["watch_count"] == 2


def test_list_season_episode_progress_returns_404_when_season_missing(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return HTTP 404 when the requested season does not exist."""

    create_local_user(db_session)

    response = client.get(
        f"/api/v1/seasons/{uuid4()}/episodes/progress",
    )

    assert response.status_code == 404

    assert response.json() == {
        "error": {
            "code": "season_not_found",
            "message": "TV season not found.",
        }
    }


def test_mark_season_watched_marks_aired_episodes(
    client: TestClient,
    db_session: Session,
) -> None:
    """Mark all eligible Episodes in a Season as watched."""

    local_user = create_local_user(
        db_session,
    )

    show = create_local_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    season = create_local_season(
        db_session,
        show=show,
        tmdb_id=134792,
        season_number=1,
        title="Season 1",
    )

    aired_episode_1 = create_local_episode(
        db_session,
        season=season,
        tmdb_id=2001,
        episode_number=1,
        title="Episode 1",
        air_date=date(2025, 1, 1),
    )

    aired_episode_2 = create_local_episode(
        db_session,
        season=season,
        tmdb_id=2002,
        episode_number=2,
        title="Episode 2",
        air_date=date(2025, 1, 8),
    )

    future_episode = create_local_episode(
        db_session,
        season=season,
        tmdb_id=2003,
        episode_number=3,
        title="Episode 3",
        air_date=date(2099, 1, 1),
    )

    response = client.post(
        f"/api/v1/seasons/{season.id}/watched",
    )

    assert response.status_code == 200

    payload = response.json()

    assert payload["season_id"] == str(season.id)
    assert payload["watched_episodes"] == 2
    assert payload["aired_episodes"] == 2
    assert payload["watched_aired_episodes"] == 2
    assert payload["aired_progress_percentage"] == 100.0
    assert payload["caught_up"] is True

    progress_entries = db_session.scalars(
        select(EpisodeProgress).where(
            EpisodeProgress.user_id == local_user.id,
        )
    ).all()

    progress_by_episode_id = {progress.episode_id: progress for progress in progress_entries}

    assert progress_by_episode_id[aired_episode_1.id].is_watched is True
    assert progress_by_episode_id[aired_episode_2.id].is_watched is True

    assert future_episode.id not in progress_by_episode_id

    watch_events = db_session.scalars(
        select(EpisodeWatchEvent).where(
            EpisodeWatchEvent.user_id == local_user.id,
        )
    ).all()

    assert {event.episode_id for event in watch_events} == {
        aired_episode_1.id,
        aired_episode_2.id,
    }


def test_mark_season_watched_does_not_rewatch_already_watched_episode(
    client: TestClient,
    db_session: Session,
) -> None:
    """Bulk Season completion must not create Rewatch events."""

    local_user = create_local_user(
        db_session,
    )

    show = create_local_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    season = create_local_season(
        db_session,
        show=show,
        tmdb_id=134792,
        season_number=1,
        title="Season 1",
    )

    episode = create_local_episode(
        db_session,
        season=season,
        tmdb_id=2001,
        episode_number=1,
        title="Episode 1",
        air_date=date(2025, 1, 1),
    )

    watched_at = datetime(
        2026,
        8,
        10,
        20,
        tzinfo=UTC,
    )

    progress = EpisodeProgress(
        user_id=local_user.id,
        episode_id=episode.id,
        is_watched=True,
        watched_at=watched_at,
    )

    event = EpisodeWatchEvent(
        user_id=local_user.id,
        episode_id=episode.id,
        watched_at=watched_at,
    )

    db_session.add_all(
        [
            progress,
            event,
        ]
    )

    db_session.commit()

    response = client.post(
        f"/api/v1/seasons/{season.id}/watched",
    )

    assert response.status_code == 200

    events = db_session.scalars(
        select(EpisodeWatchEvent).where(
            EpisodeWatchEvent.user_id == local_user.id,
            EpisodeWatchEvent.episode_id == episode.id,
        )
    ).all()

    assert len(events) == 1

    db_session.refresh(progress)

    assert progress.is_watched is True


def test_mark_season_watched_marks_all_aired_unwatched_episodes(
    client: TestClient,
    db_session: Session,
) -> None:
    """Mark every aired unwatched Episode in the Season as watched."""

    user = create_local_user(
        db_session,
    )

    show = create_local_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    season = create_local_season(
        db_session,
        show=show,
        tmdb_id=134792,
        season_number=1,
        title="Season 1",
    )

    already_watched_episode = create_local_episode(
        db_session,
        season=season,
        tmdb_id=2101,
        episode_number=1,
        title="Episode 1",
        air_date=date(2026, 8, 10),
    )

    unwatched_episode = create_local_episode(
        db_session,
        season=season,
        tmdb_id=2102,
        episode_number=2,
        title="Episode 2",
        air_date=date(2026, 8, 11),
    )

    future_episode = create_local_episode(
        db_session,
        season=season,
        tmdb_id=2103,
        episode_number=3,
        title="Episode 3",
        air_date=date(2099, 8, 20),
    )

    unknown_air_date_episode = create_local_episode(
        db_session,
        season=season,
        tmdb_id=2104,
        episode_number=4,
        title="Episode 4",
        air_date=None,
    )

    original_watched_at = datetime(
        2026,
        8,
        10,
        20,
        tzinfo=UTC,
    )

    create_episode_progress(
        db_session,
        user=user,
        episode=already_watched_episode,
        is_watched=True,
        watched_at=original_watched_at,
    )

    response = client.post(
        f"/api/v1/seasons/{season.id}/watched",
    )

    assert response.status_code == 200

    payload = response.json()

    assert payload["season_id"] == str(season.id)

    assert payload["watched_episodes"] == 2
    assert payload["total_episodes"] == 4

    assert payload["aired_episodes"] == 2
    assert payload["watched_aired_episodes"] == 2
    assert payload["caught_up"] is True

    progress_entries = {
        progress.episode_id: progress
        for progress in db_session.query(EpisodeProgress)
        .filter(
            EpisodeProgress.user_id == user.id,
        )
        .all()
    }

    assert progress_entries[already_watched_episode.id].is_watched is True

    assert progress_entries[already_watched_episode.id].watched_at is not None

    assert progress_entries[unwatched_episode.id].is_watched is True

    assert progress_entries[unwatched_episode.id].watched_at is not None

    assert future_episode.id not in progress_entries

    assert unknown_air_date_episode.id not in progress_entries


def test_mark_season_watched_preserves_existing_watched_episode_history(
    client: TestClient,
    db_session: Session,
) -> None:
    """Do not create another watch event for an already watched Episode."""

    user = create_local_user(
        db_session,
    )

    show = create_local_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    season = create_local_season(
        db_session,
        show=show,
        tmdb_id=134792,
        season_number=1,
        title="Season 1",
    )

    episode = create_local_episode(
        db_session,
        season=season,
        tmdb_id=2101,
        episode_number=1,
        title="Episode 1",
        air_date=date(2026, 8, 10),
    )

    watched_at = datetime(
        2026,
        8,
        10,
        20,
        tzinfo=UTC,
    )

    create_episode_progress(
        db_session,
        user=user,
        episode=episode,
        is_watched=True,
        watched_at=watched_at,
    )

    existing_event = EpisodeWatchEvent(
        user_id=user.id,
        episode_id=episode.id,
        watched_at=watched_at,
    )

    db_session.add(existing_event)
    db_session.commit()

    response = client.post(
        f"/api/v1/seasons/{season.id}/watched",
    )

    assert response.status_code == 200

    events = (
        db_session.query(EpisodeWatchEvent)
        .filter(
            EpisodeWatchEvent.user_id == user.id,
            EpisodeWatchEvent.episode_id == episode.id,
        )
        .all()
    )

    assert len(events) == 1

    progress = (
        db_session.query(EpisodeProgress)
        .filter(
            EpisodeProgress.user_id == user.id,
            EpisodeProgress.episode_id == episode.id,
        )
        .one()
    )

    assert progress.is_watched is True

    assert progress.watched_at is not None


def test_mark_season_watched_reuses_existing_unwatched_progress(
    client: TestClient,
    db_session: Session,
) -> None:
    """Reuse the existing progress row when the Episode was unwatched."""

    user = create_local_user(
        db_session,
    )

    show = create_local_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    season = create_local_season(
        db_session,
        show=show,
        tmdb_id=134792,
        season_number=1,
        title="Season 1",
    )

    episode = create_local_episode(
        db_session,
        season=season,
        tmdb_id=2101,
        episode_number=1,
        title="Episode 1",
        air_date=date(2026, 8, 10),
    )

    existing_progress = create_episode_progress(
        db_session,
        user=user,
        episode=episode,
        is_watched=False,
    )

    original_progress_id = existing_progress.id

    response = client.post(
        f"/api/v1/seasons/{season.id}/watched",
    )

    assert response.status_code == 200

    progress_entries = (
        db_session.query(EpisodeProgress)
        .filter(
            EpisodeProgress.user_id == user.id,
            EpisodeProgress.episode_id == episode.id,
        )
        .all()
    )

    assert len(progress_entries) == 1

    progress = progress_entries[0]

    assert progress.id == original_progress_id
    assert progress.is_watched is True
    assert progress.watched_at is not None

    events = (
        db_session.query(EpisodeWatchEvent)
        .filter(
            EpisodeWatchEvent.user_id == user.id,
            EpisodeWatchEvent.episode_id == episode.id,
        )
        .all()
    )

    assert len(events) == 1


def test_mark_season_watched_returns_404_when_season_does_not_exist(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return HTTP 404 when the requested Season does not exist."""

    create_local_user(
        db_session,
    )

    season_id = uuid4()

    response = client.post(
        f"/api/v1/seasons/{season_id}/watched",
    )

    assert response.status_code == 404

    assert response.json() == {
        "error": {
            "code": "season_not_found",
            "message": "TV season not found.",
        }
    }
