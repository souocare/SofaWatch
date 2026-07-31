from datetime import date
from uuid import uuid4

import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.models.episode import Episode
from app.models.season import Season
from app.models.show import Show


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
