from datetime import UTC, date, datetime, timedelta
from uuid import uuid4

import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.models.episode import Episode
from app.models.episode_progress import EpisodeProgress
from app.models.episode_watch_event import EpisodeWatchEvent
from app.models.season import Season
from app.models.show import Show
from app.models.user import User


def as_utc(
    value: datetime,
) -> datetime:
    """Normalize SQLite datetime values to UTC for assertions."""

    if value.tzinfo is None:
        return value.replace(
            tzinfo=UTC,
        )

    return value.astimezone(
        UTC,
    )


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
        overview=f"Overview for {title}.",
        tagline=f"Tagline for {title}.",
        first_air_date=None,
        last_air_date=None,
        tmdb_poster_path=f"/posters/{tmdb_id}.jpg",
        tmdb_backdrop_path=f"/backdrops/{tmdb_id}.jpg",
        local_poster_path=None,
        local_backdrop_path=None,
        homepage_url=None,
        original_language="en",
        status="Returning Series",
        show_type="Scripted",
        in_production=True,
        number_of_seasons=1,
        number_of_episodes=10,
        episode_run_time=50,
        popularity=100.0,
        vote_average=8.0,
        vote_count=100,
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
    overview: str | None = None,
    air_date: date | None = None,
    episode_count: int = 0,
    vote_average: float = 0.0,
    tmdb_poster_path: str | None = None,
    local_poster_path: str | None = None,
) -> Season:
    """Create and persist a locally stored TV season for route tests."""

    season = Season(
        show_id=show.id,
        tmdb_id=tmdb_id,
        season_number=season_number,
        title=title,
        overview=overview,
        air_date=air_date,
        episode_count=episode_count,
        vote_average=vote_average,
        tmdb_poster_path=tmdb_poster_path,
        local_poster_path=local_poster_path,
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
    air_date: date | None = None,
) -> Episode:
    """Create and persist a locally stored TV episode for route tests."""

    episode = Episode(
        season_id=season.id,
        tmdb_id=tmdb_id,
        episode_number=episode_number,
        title=title,
        overview=None,
        air_date=air_date,
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


def create_local_user(
    db_session: Session,
    *,
    display_name: str = "Local User",
) -> User:
    """Create and persist the local SofaWatch user for route tests."""

    user = User(
        display_name=display_name,
    )

    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)

    return user


@pytest.fixture
def local_user(
    db_session: Session,
) -> User:
    """Provide the local SofaWatch user required by progress routes."""

    return create_local_user(
        db_session,
    )


def test_list_show_seasons_returns_empty_list(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return an empty list when the local TV series has no seasons."""

    show = create_local_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    response = client.get(
        f"/api/v1/shows/{show.id}/seasons",
    )

    assert response.status_code == 200
    assert response.json() == []


def test_list_show_seasons_returns_stored_seasons(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return the locally stored seasons belonging to a TV series."""

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
        overview="The first season.",
        air_date=date(2022, 2, 18),
        episode_count=9,
        vote_average=8.4,
        tmdb_poster_path="/season-one.jpg",
    )

    response = client.get(
        f"/api/v1/shows/{show.id}/seasons",
    )

    assert response.status_code == 200

    body = response.json()

    assert len(body) == 1

    assert body[0] == {
        "id": str(season.id),
        "tmdb_id": 134792,
        "season_number": 1,
        "title": "Season 1",
        "overview": "The first season.",
        "air_date": "2022-02-18",
        "episode_count": 9,
        "vote_average": 8.4,
        "tmdb_poster_path": "/season-one.jpg",
        "local_poster_path": None,
        "poster_url": (f"/api/v1/images/seasons/{season.id}/poster"),
    }


def test_list_show_seasons_orders_by_season_number(
    client: TestClient,
    db_session: Session,
) -> None:
    """Order seasons by their season number in ascending order."""

    show = create_local_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    create_local_season(
        db_session,
        show=show,
        tmdb_id=3002,
        season_number=2,
        title="Season 2",
    )

    create_local_season(
        db_session,
        show=show,
        tmdb_id=3000,
        season_number=0,
        title="Specials",
    )

    create_local_season(
        db_session,
        show=show,
        tmdb_id=3001,
        season_number=1,
        title="Season 1",
    )

    response = client.get(
        f"/api/v1/shows/{show.id}/seasons",
    )

    assert response.status_code == 200

    body = response.json()

    assert [season["season_number"] for season in body] == [
        0,
        1,
        2,
    ]


def test_list_show_seasons_includes_specials(
    client: TestClient,
    db_session: Session,
) -> None:
    """Include season number zero representing special episodes."""

    show = create_local_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    specials = create_local_season(
        db_session,
        show=show,
        tmdb_id=199716,
        season_number=0,
        title="Specials",
        overview="Special episodes.",
        episode_count=2,
        vote_average=7.5,
        tmdb_poster_path="/specials.jpg",
    )

    response = client.get(
        f"/api/v1/shows/{show.id}/seasons",
    )

    assert response.status_code == 200

    body = response.json()

    assert len(body) == 1
    assert body[0]["id"] == str(specials.id)
    assert body[0]["season_number"] == 0
    assert body[0]["title"] == "Specials"


def test_list_show_seasons_only_returns_requested_show_seasons(
    client: TestClient,
    db_session: Session,
) -> None:
    """Do not return seasons belonging to another TV series."""

    first_show = create_local_show(
        db_session,
        tmdb_id=1001,
        title="First Show",
    )

    second_show = create_local_show(
        db_session,
        tmdb_id=1002,
        title="Second Show",
    )

    create_local_season(
        db_session,
        show=first_show,
        tmdb_id=2001,
        season_number=1,
        title="First Show Season",
    )

    create_local_season(
        db_session,
        show=second_show,
        tmdb_id=3001,
        season_number=1,
        title="Second Show Season",
    )

    response = client.get(
        f"/api/v1/shows/{first_show.id}/seasons",
    )

    assert response.status_code == 200

    body = response.json()

    assert len(body) == 1
    assert body[0]["title"] == "First Show Season"
    assert body[0]["tmdb_id"] == 2001


def test_list_show_seasons_serializes_optional_fields_as_null(
    client: TestClient,
    db_session: Session,
) -> None:
    """Serialize missing optional season metadata as null."""

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
        overview=None,
        air_date=None,
        episode_count=0,
        vote_average=0.0,
        tmdb_poster_path=None,
        local_poster_path=None,
    )

    response = client.get(
        f"/api/v1/shows/{show.id}/seasons",
    )

    assert response.status_code == 200

    body = response.json()

    assert len(body) == 1

    assert body[0] == {
        "id": str(season.id),
        "tmdb_id": 134792,
        "season_number": 1,
        "title": "Season 1",
        "overview": None,
        "air_date": None,
        "episode_count": 0,
        "vote_average": 0.0,
        "tmdb_poster_path": None,
        "local_poster_path": None,
        "poster_url": None,
    }


def test_list_show_seasons_returns_local_poster_path(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return locally stored season artwork when available."""

    show = create_local_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    create_local_season(
        db_session,
        show=show,
        tmdb_id=134792,
        season_number=1,
        title="Season 1",
        tmdb_poster_path="/tmdb-season-one.jpg",
        local_poster_path="/media/shows/severance/season-one.jpg",
    )

    response = client.get(
        f"/api/v1/shows/{show.id}/seasons",
    )

    assert response.status_code == 200

    body = response.json()

    assert body[0]["tmdb_poster_path"] == "/tmdb-season-one.jpg"

    assert body[0]["local_poster_path"] == "/media/shows/severance/season-one.jpg"


def test_list_show_seasons_returns_404_when_show_does_not_exist(
    client: TestClient,
) -> None:
    """Return HTTP 404 when the local TV series does not exist."""

    missing_show_id = uuid4()

    response = client.get(
        f"/api/v1/shows/{missing_show_id}/seasons",
    )

    assert response.status_code == 404

    assert response.json() == {
        "error": {
            "code": "show_not_found",
            "message": "TV series not found.",
        }
    }


@pytest.mark.parametrize(
    "show_id",
    [
        "not-a-valid-uuid",
        "123",
        "invalid",
    ],
)
def test_list_show_seasons_rejects_invalid_show_id(
    client: TestClient,
    show_id: str,
) -> None:
    """Reject an invalid local TV series identifier."""

    response = client.get(
        f"/api/v1/shows/{show_id}/seasons",
    )

    assert response.status_code == 422


def test_get_show_seasons_progress_returns_all_seasons(
    client: TestClient,
    db_session: Session,
    local_user: User,
) -> None:
    """Return viewing progress for every locally stored Season."""

    today = date.today()

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

    third_season = create_local_season(
        db_session,
        show=show,
        tmdb_id=1003,
        season_number=3,
        title="Season 3",
    )

    create_local_episode(
        db_session,
        season=first_season,
        tmdb_id=2001,
        episode_number=1,
        title="S01E01",
        air_date=today - timedelta(days=2),
    )

    create_local_episode(
        db_session,
        season=first_season,
        tmdb_id=2002,
        episode_number=2,
        title="S01E02",
        air_date=today + timedelta(days=2),
    )

    create_local_episode(
        db_session,
        season=first_season,
        tmdb_id=2003,
        episode_number=3,
        title="S01E03",
        air_date=None,
    )

    create_local_episode(
        db_session,
        season=second_season,
        tmdb_id=3001,
        episode_number=1,
        title="S02E01",
        air_date=today - timedelta(days=1),
    )

    create_local_episode(
        db_session,
        season=second_season,
        tmdb_id=3002,
        episode_number=2,
        title="S02E02",
        air_date=today,
    )

    response = client.get(
        f"/api/v1/shows/{show.id}/seasons/progress",
    )

    assert response.status_code == 200

    body = response.json()

    assert len(body) == 3

    assert body[0] == {
        "season_id": str(first_season.id),
        "watched_episodes": 0,
        "total_episodes": 3,
        "progress_percentage": 0.0,
        "aired_episodes": 1,
        "watched_aired_episodes": 0,
        "aired_progress_percentage": 0.0,
        "caught_up": False,
    }

    assert body[1] == {
        "season_id": str(second_season.id),
        "watched_episodes": 0,
        "total_episodes": 2,
        "progress_percentage": 0.0,
        "aired_episodes": 2,
        "watched_aired_episodes": 0,
        "aired_progress_percentage": 0.0,
        "caught_up": False,
    }

    assert body[2] == {
        "season_id": str(third_season.id),
        "watched_episodes": 0,
        "total_episodes": 0,
        "progress_percentage": 0.0,
        "aired_episodes": 0,
        "watched_aired_episodes": 0,
        "aired_progress_percentage": 0.0,
        "caught_up": False,
    }


def test_get_show_seasons_progress_orders_by_season_number(
    client: TestClient,
    db_session: Session,
    local_user: User,
) -> None:
    """Return Season progress in ascending Season order."""

    show = create_local_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    season_two = create_local_season(
        db_session,
        show=show,
        tmdb_id=3002,
        season_number=2,
        title="Season 2",
    )

    specials = create_local_season(
        db_session,
        show=show,
        tmdb_id=3000,
        season_number=0,
        title="Specials",
    )

    season_one = create_local_season(
        db_session,
        show=show,
        tmdb_id=3001,
        season_number=1,
        title="Season 1",
    )

    response = client.get(
        f"/api/v1/shows/{show.id}/seasons/progress",
    )

    assert response.status_code == 200

    body = response.json()

    assert [item["season_id"] for item in body] == [
        str(specials.id),
        str(season_one.id),
        str(season_two.id),
    ]


def test_get_show_seasons_progress_returns_empty_list_without_seasons(
    client: TestClient,
    db_session: Session,
    local_user: User,
) -> None:
    """Return an empty list when the TV series has no local Seasons."""

    show = create_local_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    response = client.get(
        f"/api/v1/shows/{show.id}/seasons/progress",
    )

    assert response.status_code == 200
    assert response.json() == []


def test_get_show_seasons_progress_returns_404_when_show_does_not_exist(
    client: TestClient,
    local_user: User,
) -> None:
    """Return HTTP 404 when the local TV series does not exist."""

    missing_show_id = uuid4()

    response = client.get(
        f"/api/v1/shows/{missing_show_id}/seasons/progress",
    )

    assert response.status_code == 404

    assert response.json() == {
        "error": {
            "code": "show_not_found",
            "message": "TV series not found.",
        }
    }


@pytest.mark.parametrize(
    "show_id",
    [
        "not-a-valid-uuid",
        "123",
        "invalid",
    ],
)
def test_get_show_seasons_progress_rejects_invalid_show_id(
    client: TestClient,
    local_user: User,
    show_id: str,
) -> None:
    """Reject an invalid local TV series identifier."""

    response = client.get(
        f"/api/v1/shows/{show_id}/seasons/progress",
    )

    assert response.status_code == 422


def test_mark_show_watched_marks_all_aired_unwatched_regular_episodes(
    client: TestClient,
    db_session: Session,
    local_user: User,
) -> None:
    """Mark every aired unwatched regular Episode in the Show as watched."""

    today = date.today()

    show = create_local_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    specials = create_local_season(
        db_session,
        show=show,
        tmdb_id=1000,
        season_number=0,
        title="Specials",
    )

    season_one = create_local_season(
        db_session,
        show=show,
        tmdb_id=1001,
        season_number=1,
        title="Season 1",
    )

    season_two = create_local_season(
        db_session,
        show=show,
        tmdb_id=1002,
        season_number=2,
        title="Season 2",
    )

    special_episode = create_local_episode(
        db_session,
        season=specials,
        tmdb_id=2000,
        episode_number=1,
        title="Special",
        air_date=today - timedelta(days=10),
    )

    season_one_episode = create_local_episode(
        db_session,
        season=season_one,
        tmdb_id=2001,
        episode_number=1,
        title="S01E01",
        air_date=today - timedelta(days=5),
    )

    season_two_episode = create_local_episode(
        db_session,
        season=season_two,
        tmdb_id=3001,
        episode_number=1,
        title="S02E01",
        air_date=today,
    )

    future_episode = create_local_episode(
        db_session,
        season=season_two,
        tmdb_id=3002,
        episode_number=2,
        title="S02E02",
        air_date=today + timedelta(days=7),
    )

    unknown_air_date_episode = create_local_episode(
        db_session,
        season=season_two,
        tmdb_id=3003,
        episode_number=3,
        title="S02E03",
        air_date=None,
    )

    response = client.post(
        f"/api/v1/shows/{show.id}/watched",
    )

    assert response.status_code == 200

    body = response.json()

    assert body["show_id"] == str(show.id)

    assert body["watched_episodes"] == 2
    assert body["total_episodes"] == 4

    assert body["aired_episodes"] == 2
    assert body["watched_aired_episodes"] == 2
    assert body["aired_progress_percentage"] == 100.0
    assert body["caught_up"] is True

    progress_entries = {
        progress.episode_id: progress
        for progress in db_session.query(EpisodeProgress)
        .filter(
            EpisodeProgress.user_id == local_user.id,
        )
        .all()
    }

    assert progress_entries[season_one_episode.id].is_watched is True
    assert progress_entries[season_two_episode.id].is_watched is True

    assert special_episode.id not in progress_entries
    assert future_episode.id not in progress_entries
    assert unknown_air_date_episode.id not in progress_entries

    watch_events = (
        db_session.query(EpisodeWatchEvent)
        .filter(
            EpisodeWatchEvent.user_id == local_user.id,
        )
        .all()
    )

    assert {event.episode_id for event in watch_events} == {
        season_one_episode.id,
        season_two_episode.id,
    }

    assert len({event.watched_at for event in watch_events}) == 1


def test_mark_show_watched_preserves_existing_watched_episode_history(
    client: TestClient,
    db_session: Session,
    local_user: User,
) -> None:
    """Do not create another watch event for an already watched Episode."""

    today = date.today()

    show = create_local_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    season = create_local_season(
        db_session,
        show=show,
        tmdb_id=1001,
        season_number=1,
        title="Season 1",
    )

    already_watched_episode = create_local_episode(
        db_session,
        season=season,
        tmdb_id=2001,
        episode_number=1,
        title="S01E01",
        air_date=today - timedelta(days=2),
    )

    unwatched_episode = create_local_episode(
        db_session,
        season=season,
        tmdb_id=2002,
        episode_number=2,
        title="S01E02",
        air_date=today - timedelta(days=1),
    )

    original_watched_at = datetime(
        2026,
        8,
        10,
        20,
        tzinfo=UTC,
    )

    existing_progress = EpisodeProgress(
        user_id=local_user.id,
        episode_id=already_watched_episode.id,
        is_watched=True,
        watched_at=original_watched_at,
    )

    existing_event = EpisodeWatchEvent(
        user_id=local_user.id,
        episode_id=already_watched_episode.id,
        watched_at=original_watched_at,
    )

    db_session.add_all(
        [
            existing_progress,
            existing_event,
        ]
    )

    db_session.commit()

    response = client.post(
        f"/api/v1/shows/{show.id}/watched",
    )

    assert response.status_code == 200

    events = (
        db_session.query(EpisodeWatchEvent)
        .filter(
            EpisodeWatchEvent.user_id == local_user.id,
        )
        .all()
    )

    events_by_episode_id: dict = {}

    for event in events:
        events_by_episode_id.setdefault(
            event.episode_id,
            [],
        ).append(event)

    assert len(events_by_episode_id[already_watched_episode.id]) == 1
    assert len(events_by_episode_id[unwatched_episode.id]) == 1

    db_session.refresh(existing_progress)

    assert existing_progress.is_watched is True
    assert existing_progress.watched_at is not None
    assert as_utc(existing_progress.watched_at) == original_watched_at


def test_mark_show_watched_returns_404_when_show_does_not_exist(
    client: TestClient,
    local_user: User,
) -> None:
    """Return HTTP 404 when marking a missing Show as watched."""

    missing_show_id = uuid4()

    response = client.post(
        f"/api/v1/shows/{missing_show_id}/watched",
    )

    assert response.status_code == 404

    assert response.json() == {
        "error": {
            "code": "show_not_found",
            "message": "TV series not found.",
        }
    }
