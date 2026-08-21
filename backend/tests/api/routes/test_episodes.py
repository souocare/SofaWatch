from datetime import UTC, date, datetime, timedelta
from uuid import uuid4

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import select
from sqlalchemy.orm import Session

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


@pytest.fixture
def local_user(
    db_session: Session,
) -> User:
    """Create the local SofaWatch user required by authenticated routes."""

    user = User(
        display_name="Local User",
        is_local=True,
    )

    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)

    return user


def create_watch_event(
    db_session: Session,
    *,
    user: User,
    episode: Episode,
    watched_at: datetime,
) -> EpisodeWatchEvent:
    """Create and persist one Episode viewing event."""

    event = EpisodeWatchEvent(
        user_id=user.id,
        episode_id=episode.id,
        watched_at=watched_at,
    )

    db_session.add(event)
    db_session.commit()
    db_session.refresh(event)

    return event


def create_watched_progress(
    db_session: Session,
    *,
    user: User,
    episode: Episode,
    watched_at: datetime,
) -> EpisodeProgress:
    """Create and persist the Episode's current watched state."""

    progress = EpisodeProgress(
        user_id=user.id,
        episode_id=episode.id,
        is_watched=True,
        watched_at=watched_at,
    )

    db_session.add(progress)
    db_session.commit()
    db_session.refresh(progress)

    return progress


def as_utc(
    value: datetime,
) -> datetime:
    """Interpret timezone-naive SQLite datetimes as UTC."""

    if value.tzinfo is None:
        return value.replace(
            tzinfo=UTC,
        )

    return value.astimezone(
        UTC,
    )


def test_get_episode_returns_detailed_response(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return detailed information about a locally stored TV episode."""

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
        local_still_path="/media/severance/s01e01.jpg",
    )

    response = client.get(
        f"/api/v1/episodes/{episode.id}",
    )

    assert response.status_code == 200

    assert response.json() == {
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
        "local_still_path": "/media/severance/s01e01.jpg",
        "still_url": f"/api/v1/images/episodes/{episode.id}/still",
    }


def test_get_episode_serializes_optional_fields_as_null(
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
        f"/api/v1/episodes/{episode.id}",
    )

    assert response.status_code == 200

    assert response.json() == {
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


def test_get_episode_returns_404_when_episode_does_not_exist(
    client: TestClient,
) -> None:
    """Return HTTP 404 when the local TV episode does not exist."""

    response = client.get(
        f"/api/v1/episodes/{uuid4()}",
    )

    assert response.status_code == 404

    assert response.json() == {
        "error": {
            "code": "episode_not_found",
            "message": "TV episode not found.",
        }
    }


@pytest.mark.parametrize(
    "episode_id",
    [
        "not-a-valid-uuid",
        "123",
        "invalid",
    ],
)
def test_get_episode_rejects_invalid_episode_id(
    client: TestClient,
    episode_id: str,
) -> None:
    """Reject an invalid local TV episode identifier."""

    response = client.get(
        f"/api/v1/episodes/{episode_id}",
    )

    assert response.status_code == 422


def test_mark_episode_watched_creates_watch_event(
    client: TestClient,
    db_session: Session,
    local_user: User,
) -> None:
    """Marking an Episode watched must record a historical viewing event."""

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
        air_date=date(2026, 8, 1),
    )

    watched_at = datetime(
        2026,
        8,
        14,
        20,
        30,
        tzinfo=UTC,
    )

    response = client.post(
        f"/api/v1/episodes/{episode.id}/watched",
        json={
            "watched_at": watched_at.isoformat(),
        },
    )

    assert response.status_code == 200

    payload = response.json()

    assert payload["episode_id"] == str(episode.id)
    assert payload["is_watched"] is True
    assert payload["watched_at"] is not None

    events = list(
        db_session.scalars(
            select(EpisodeWatchEvent).where(
                EpisodeWatchEvent.user_id == local_user.id,
                EpisodeWatchEvent.episode_id == episode.id,
            )
        ).all()
    )

    assert len(events) == 1

    assert as_utc(events[0].watched_at) == watched_at


def test_mark_episode_watched_again_creates_second_watch_event(
    client: TestClient,
    db_session: Session,
    local_user: User,
) -> None:
    """A rewatch must create another historical viewing event."""

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
        air_date=date(2026, 8, 1),
    )

    first_watched_at = datetime(
        2026,
        7,
        20,
        20,
        30,
        tzinfo=UTC,
    )

    second_watched_at = datetime(
        2026,
        8,
        14,
        21,
        15,
        tzinfo=UTC,
    )

    first_response = client.post(
        f"/api/v1/episodes/{episode.id}/watched",
        json={
            "watched_at": first_watched_at.isoformat(),
        },
    )

    assert first_response.status_code == 200

    second_response = client.post(
        f"/api/v1/episodes/{episode.id}/watched",
        json={
            "watched_at": second_watched_at.isoformat(),
        },
    )

    assert second_response.status_code == 200

    events = list(
        db_session.scalars(
            select(EpisodeWatchEvent)
            .where(
                EpisodeWatchEvent.user_id == local_user.id,
                EpisodeWatchEvent.episode_id == episode.id,
            )
            .order_by(
                EpisodeWatchEvent.watched_at.desc(),
            )
        ).all()
    )

    assert len(events) == 2

    assert as_utc(events[0].watched_at) == second_watched_at
    assert as_utc(events[1].watched_at) == first_watched_at


def test_list_episode_watch_events_returns_newest_first(
    client: TestClient,
    db_session: Session,
    local_user: User,
) -> None:
    """Return all Episode viewing events ordered newest first."""

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
    )

    older_event = create_watch_event(
        db_session,
        user=local_user,
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

    newer_event = create_watch_event(
        db_session,
        user=local_user,
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

    response = client.get(
        f"/api/v1/episodes/{episode.id}/watch-events",
    )

    assert response.status_code == 200

    payload = response.json()

    assert len(payload) == 2

    assert payload[0]["id"] == str(newer_event.id)
    assert payload[0]["episode_id"] == str(episode.id)

    assert payload[1]["id"] == str(older_event.id)
    assert payload[1]["episode_id"] == str(episode.id)


def test_list_episode_watch_events_returns_empty_list_when_never_watched(
    client: TestClient,
    db_session: Session,
    local_user: User,
) -> None:
    """Return an empty list when the Episode has no recorded viewings."""

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
    )

    response = client.get(
        f"/api/v1/episodes/{episode.id}/watch-events",
    )

    assert response.status_code == 200
    assert response.json() == []


def test_delete_intermediate_watch_event_preserves_latest_progress(
    client: TestClient,
    db_session: Session,
    local_user: User,
) -> None:
    """Deleting an older watch event must preserve the newest viewing."""

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
    )

    older_watched_at = datetime(
        2026,
        7,
        20,
        20,
        0,
        tzinfo=UTC,
    )

    latest_watched_at = datetime(
        2026,
        8,
        14,
        21,
        30,
        tzinfo=UTC,
    )

    older_event = create_watch_event(
        db_session,
        user=local_user,
        episode=episode,
        watched_at=older_watched_at,
    )

    create_watch_event(
        db_session,
        user=local_user,
        episode=episode,
        watched_at=latest_watched_at,
    )

    progress = create_watched_progress(
        db_session,
        user=local_user,
        episode=episode,
        watched_at=latest_watched_at,
    )

    response = client.delete(
        (
            f"/api/v1/episodes/{episode.id}/watch-events/"
            f"{older_event.id}"
        ),
    )

    assert response.status_code == 204
    assert response.content == b""

    db_session.refresh(progress)

    assert progress.is_watched is True
    assert progress.watched_at is not None
    assert as_utc(progress.watched_at) == latest_watched_at

    deleted_event = db_session.get(
        EpisodeWatchEvent,
        older_event.id,
    )

    assert deleted_event is None


def test_delete_latest_watch_event_moves_progress_to_previous_event(
    client: TestClient,
    db_session: Session,
    local_user: User,
) -> None:
    """Deleting the latest event must restore the previous viewing date."""

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
    )

    previous_watched_at = datetime(
        2026,
        7,
        20,
        20,
        0,
        tzinfo=UTC,
    )

    latest_watched_at = datetime(
        2026,
        8,
        14,
        21,
        30,
        tzinfo=UTC,
    )

    create_watch_event(
        db_session,
        user=local_user,
        episode=episode,
        watched_at=previous_watched_at,
    )

    latest_event = create_watch_event(
        db_session,
        user=local_user,
        episode=episode,
        watched_at=latest_watched_at,
    )

    progress = create_watched_progress(
        db_session,
        user=local_user,
        episode=episode,
        watched_at=latest_watched_at,
    )

    response = client.delete(
        (
            f"/api/v1/episodes/{episode.id}/watch-events/"
            f"{latest_event.id}"
        ),
    )

    assert response.status_code == 204

    db_session.refresh(progress)

    assert progress.is_watched is True
    assert progress.watched_at is not None
    assert as_utc(progress.watched_at) == previous_watched_at


def test_delete_only_watch_event_marks_episode_unwatched(
    client: TestClient,
    db_session: Session,
    local_user: User,
) -> None:
    """Deleting the final historical viewing must clear watched progress."""

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
    )

    watched_at = datetime(
        2026,
        8,
        14,
        21,
        30,
        tzinfo=UTC,
    )

    event = create_watch_event(
        db_session,
        user=local_user,
        episode=episode,
        watched_at=watched_at,
    )

    progress = create_watched_progress(
        db_session,
        user=local_user,
        episode=episode,
        watched_at=watched_at,
    )

    response = client.delete(
        (
            f"/api/v1/episodes/{episode.id}/watch-events/"
            f"{event.id}"
        ),
    )

    assert response.status_code == 204

    db_session.refresh(progress)

    assert progress.is_watched is False
    assert progress.watched_at is None


def test_delete_watch_event_returns_404_when_event_does_not_exist(
    client: TestClient,
    db_session: Session,
    local_user: User,
) -> None:
    """Return HTTP 404 when deleting a missing historical viewing."""

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
    )

    response = client.delete(
        (
            f"/api/v1/episodes/{episode.id}/watch-events/"
            f"{uuid4()}"
        ),
    )

    assert response.status_code == 404

    assert response.json() == {
        "error": {
            "code": "episode_watch_event_not_found",
            "message": "Episode watch event not found.",
        }
    }


def test_delete_watch_event_returns_404_for_event_from_another_episode(
    client: TestClient,
    db_session: Session,
    local_user: User,
) -> None:
    """Do not allow an event from another Episode to be deleted."""

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

    first_episode = create_local_episode(
        db_session,
        season=season,
        tmdb_id=2101,
        episode_number=1,
        title="Good News About Hell",
    )

    second_episode = create_local_episode(
        db_session,
        season=season,
        tmdb_id=2102,
        episode_number=2,
        title="Half Loop",
    )

    event = create_watch_event(
        db_session,
        user=local_user,
        episode=first_episode,
        watched_at=datetime(
            2026,
            8,
            14,
            21,
            30,
            tzinfo=UTC,
        ),
    )

    response = client.delete(
        (
            f"/api/v1/episodes/{second_episode.id}/watch-events/"
            f"{event.id}"
        ),
    )

    assert response.status_code == 404

    assert response.json() == {
        "error": {
            "code": "episode_watch_event_not_found",
            "message": "Episode watch event not found.",
        }
    }

    persisted_event = db_session.get(
        EpisodeWatchEvent,
        event.id,
    )

    assert persisted_event is not None


def test_delete_watch_event_cannot_delete_another_users_event(
    client: TestClient,
    db_session: Session,
    local_user: User,
) -> None:
    """Do not allow a user to delete another user's Episode watch event."""

    other_user = User(
        username="other-user",
        display_name="Other User",
        is_local=False,
        is_active=True,
    )

    db_session.add(other_user)
    db_session.commit()
    db_session.refresh(other_user)

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
    )

    event = create_watch_event(
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

    response = client.delete(
        f"/api/v1/episodes/{episode.id}/watch-events/{event.id}",
    )

    assert response.status_code == 404

    assert response.json() == {
        "error": {
            "code": "episode_watch_event_not_found",
            "message": "Episode watch event not found.",
        }
    }

    stored_event = db_session.get(
        EpisodeWatchEvent,
        event.id,
    )

    assert stored_event is not None
    assert stored_event.user_id == other_user.id


def test_delete_all_watch_events_clears_history_and_progress(
    client: TestClient,
    db_session: Session,
    local_user: User,
) -> None:
    """Delete every viewing event and clear the Episode watched state."""

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
    )

    watched_at_values = [
        datetime(2026, 6, 1, 20, 0, tzinfo=UTC),
        datetime(2026, 7, 1, 20, 0, tzinfo=UTC),
        datetime(2026, 8, 14, 21, 30, tzinfo=UTC),
    ]

    for watched_at in watched_at_values:
        create_watch_event(
            db_session,
            user=local_user,
            episode=episode,
            watched_at=watched_at,
        )

    progress = create_watched_progress(
        db_session,
        user=local_user,
        episode=episode,
        watched_at=watched_at_values[-1],
    )

    response = client.delete(
        f"/api/v1/episodes/{episode.id}/watch-events",
    )

    assert response.status_code == 204
    assert response.content == b""

    remaining_events = list(
        db_session.scalars(
            select(EpisodeWatchEvent).where(
                EpisodeWatchEvent.user_id == local_user.id,
                EpisodeWatchEvent.episode_id == episode.id,
            )
        ).all()
    )

    assert remaining_events == []

    db_session.refresh(progress)

    assert progress.is_watched is False
    assert progress.watched_at is None

def test_delete_all_watch_events_is_idempotent(
    client: TestClient,
    db_session: Session,
    local_user: User,
) -> None:
    """Deleting all viewings repeatedly must continue to succeed."""

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
    )

    response = client.delete(
        f"/api/v1/episodes/{episode.id}/watch-events",
    )

    assert response.status_code == 204

    second_response = client.delete(
        f"/api/v1/episodes/{episode.id}/watch-events",
    )

    assert second_response.status_code == 204


def test_delete_all_watch_events_preserves_other_episode_history(
    client: TestClient,
    db_session: Session,
    local_user: User,
) -> None:
    """Deleting all viewings for one Episode must not affect another Episode."""

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

    first_episode = create_local_episode(
        db_session,
        season=season,
        tmdb_id=2101,
        episode_number=1,
        title="Good News About Hell",
    )

    second_episode = create_local_episode(
        db_session,
        season=season,
        tmdb_id=2102,
        episode_number=2,
        title="Half Loop",
    )

    first_event = create_watch_event(
        db_session,
        user=local_user,
        episode=first_episode,
        watched_at=datetime(
            2026,
            8,
            14,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    second_event = create_watch_event(
        db_session,
        user=local_user,
        episode=second_episode,
        watched_at=datetime(
            2026,
            8,
            14,
            21,
            0,
            tzinfo=UTC,
        ),
    )

    create_watched_progress(
        db_session,
        user=local_user,
        episode=first_episode,
        watched_at=first_event.watched_at,
    )

    response = client.delete(
        f"/api/v1/episodes/{first_episode.id}/watch-events",
    )

    assert response.status_code == 204

    assert db_session.get(EpisodeWatchEvent, first_event.id) is None
    assert db_session.get(EpisodeWatchEvent, second_event.id) is not None

def test_mark_future_episode_watched_returns_conflict(
    client: TestClient,
    db_session: Session,
    local_user: User,
) -> None:
    """Reject watching an Episode whose air date is still in the future."""

    show = create_local_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    season = create_local_season(
        db_session,
        show=show,
        tmdb_id=134792,
        season_number=2,
        title="Season 2",
    )

    episode = create_local_episode(
        db_session,
        season=season,
        tmdb_id=300001,
        episode_number=10,
        title="Future Episode",
        air_date=date.today() + timedelta(days=1),
    )

    response = client.post(
        f"/api/v1/episodes/{episode.id}/watched",
        json={
            "watched_at": None,
        },
    )

    assert response.status_code == 409

    assert response.json() == {
        "error": {
            "code": "episode_cannot_be_watched",
            "message": "TV episode cannot be marked as watched yet.",
        }
    }
def test_mark_episode_airing_today_watched_returns_success(
    client: TestClient,
    db_session: Session,
    local_user: User,
) -> None:
    """Allow marking an Episode watched when it airs Today."""

    show = create_local_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    season = create_local_season(
        db_session,
        show=show,
        tmdb_id=134792,
        season_number=2,
        title="Season 2",
    )

    episode = create_local_episode(
        db_session,
        season=season,
        tmdb_id=300002,
        episode_number=2,
        title="Today Episode",
        air_date=date.today(),
    )

    response = client.post(
        f"/api/v1/episodes/{episode.id}/watched",
        json={
            "watched_at": None,
        },
    )

    assert response.status_code == 200

    body = response.json()

    assert body["episode_id"] == str(episode.id)
    assert body["is_watched"] is True


def test_get_episode_details_returns_episode_context_and_progress(
    client: TestClient,
    db_session: Session,
    local_user: User,
) -> None:
    """Return the complete Episode Details aggregate."""

    show = create_local_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    season = create_local_season(
        db_session,
        show=show,
        tmdb_id=134792,
        season_number=2,
        title="Season 2",
    )

    episode = create_local_episode(
        db_session,
        season=season,
        tmdb_id=1947648,
        episode_number=4,
        title="Woe's Hollow",
        overview="Mark and the team discover something unexpected.",
        air_date=date(2025, 2, 7),
        runtime=52,
        vote_average=8.5,
        vote_count=100,
        tmdb_still_path="/woes-hollow.jpg",
    )

    first_watch = datetime(
        2026,
        8,
        10,
        20,
        tzinfo=UTC,
    )

    latest_watch = datetime(
        2026,
        8,
        14,
        21,
        30,
        tzinfo=UTC,
    )

    create_watched_progress(
        db_session,
        user=local_user,
        episode=episode,
        watched_at=latest_watch,
    )

    create_watch_event(
        db_session,
        user=local_user,
        episode=episode,
        watched_at=first_watch,
    )

    create_watch_event(
        db_session,
        user=local_user,
        episode=episode,
        watched_at=latest_watch,
    )

    response = client.get(
        f"/api/v1/episodes/{episode.id}/details",
    )

    assert response.status_code == 200

    payload = response.json()

    assert payload["episode"]["id"] == str(episode.id)
    assert payload["episode"]["tmdb_id"] == 1947648
    assert payload["episode"]["episode_number"] == 4
    assert payload["episode"]["title"] == "Woe's Hollow"

    assert payload["season"]["id"] == str(season.id)
    assert payload["season"]["season_number"] == 2

    assert payload["show"]["id"] == str(show.id)
    assert payload["show"]["tmdb_id"] == 95396
    assert payload["show"]["title"] == "Severance"

    assert payload["progress"]["is_watched"] is True
    assert payload["progress"]["watch_count"] == 2

    assert as_utc(
        datetime.fromisoformat(
            payload["progress"]["watched_at"],
        )
    ) == latest_watch

    assert as_utc(
        datetime.fromisoformat(
            payload["progress"]["last_watched_at"],
        )
    ) == latest_watch

def test_get_episode_details_returns_unwatched_state_without_history(
    client: TestClient,
    db_session: Session,
    local_user: User,
) -> None:
    """Return an unwatched Episode when no viewing history exists."""

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
        air_date=date(2022, 2, 18),
    )

    response = client.get(
        f"/api/v1/episodes/{episode.id}/details",
    )

    assert response.status_code == 200

    payload = response.json()

    assert payload["episode"]["id"] == str(episode.id)

    assert payload["progress"] == {
        "is_watched": False,
        "watched_at": None,
        "watch_count": 0,
        "last_watched_at": None,
    }


def test_get_episode_details_preserves_history_when_currently_unwatched(
    client: TestClient,
    db_session: Session,
    local_user: User,
) -> None:
    """Keep historical watches separate from the current watched state."""

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
        air_date=date(2022, 2, 18),
    )

    previous_watch = datetime(
        2026,
        8,
        10,
        20,
        tzinfo=UTC,
    )

    create_watch_event(
        db_session,
        user=local_user,
        episode=episode,
        watched_at=previous_watch,
    )

    progress = EpisodeProgress(
        user_id=local_user.id,
        episode_id=episode.id,
        is_watched=False,
        watched_at=None,
    )

    db_session.add(progress)
    db_session.commit()

    response = client.get(
        f"/api/v1/episodes/{episode.id}/details",
    )

    assert response.status_code == 200

    payload = response.json()

    assert payload["progress"]["is_watched"] is False
    assert payload["progress"]["watched_at"] is None

    assert payload["progress"]["watch_count"] == 1

    assert as_utc(
        datetime.fromisoformat(
            payload["progress"]["last_watched_at"],
        )
    ) == previous_watch


def test_get_episode_details_returns_404_when_episode_does_not_exist(
    client: TestClient,
    local_user: User,
) -> None:
    """Return HTTP 404 when Episode Details cannot find the Episode."""

    response = client.get(
        f"/api/v1/episodes/{uuid4()}/details",
    )

    assert response.status_code == 404

    assert response.json() == {
        "error": {
            "code": "episode_not_found",
            "message": "TV episode not found.",
        }
    }