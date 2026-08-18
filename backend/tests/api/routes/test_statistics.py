from datetime import UTC, datetime

from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.models.episode import Episode
from app.models.episode_watch_event import EpisodeWatchEvent
from app.models.movie import Movie
from app.models.movie_watch_event import MovieWatchEvent
from app.models.season import Season
from app.models.show import Show
from app.models.user import User


def test_get_weekly_statistics_returns_current_user_summary(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return a combined Episode and Movie summary for the local user."""

    user = User(
        display_name="Local User",
        is_local=True,
    )

    show = Show(
        tmdb_id=95396,
        title="Severance",
        original_title="Severance",
        original_language="en",
        metadata_language="en-US",
    )

    movie = Movie(
        tmdb_id=438631,
        title="Dune",
        original_title="Dune",
        original_language="en",
        runtime=155,
        status="Released",
        adult=False,
        video=False,
        popularity=10.0,
        vote_average=8.0,
        vote_count=100,
        metadata_language="en-US",
    )

    db_session.add_all(
        [
            user,
            show,
            movie,
        ]
    )

    db_session.commit()

    season = Season(
        show_id=show.id,
        tmdb_id=134792,
        season_number=1,
        title="Season 1",
        overview=None,
        air_date=None,
        episode_count=1,
        vote_average=0.0,
    )

    db_session.add(
        season,
    )

    db_session.commit()

    episode = Episode(
        season_id=season.id,
        tmdb_id=2101,
        episode_number=1,
        title="Good News About Hell",
        overview=None,
        air_date=None,
        runtime=50,
        vote_average=0.0,
        vote_count=0,
    )

    db_session.add(
        episode,
    )

    db_session.commit()

    now = datetime.now(
        UTC,
    )

    db_session.add_all(
        [
            EpisodeWatchEvent(
                user_id=user.id,
                episode_id=episode.id,
                watched_at=now,
            ),
            EpisodeWatchEvent(
                user_id=user.id,
                episode_id=episode.id,
                watched_at=now,
            ),
            MovieWatchEvent(
                user_id=user.id,
                movie_id=movie.id,
                watched_at=now,
            ),
        ]
    )

    db_session.commit()

    response = client.get(
        "/api/v1/statistics/weekly",
    )

    assert response.status_code == 200

    body = response.json()

    assert body["episodes_watched"] == 2
    assert body["movies_watched"] == 1

    assert body["watch_time_minutes"] == 255

    assert body["week_start"] is not None
    assert body["week_end"] is not None


def test_get_weekly_statistics_returns_zero_summary_without_viewings(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return a usable zero summary when the local user watched nothing."""

    user = User(
        display_name="Local User",
        is_local=True,
    )

    db_session.add(
        user,
    )

    db_session.commit()

    response = client.get(
        "/api/v1/statistics/weekly",
    )

    assert response.status_code == 200

    assert response.json()["episodes_watched"] == 0
    assert response.json()["movies_watched"] == 0
    assert response.json()["watch_time_minutes"] == 0


def test_get_statistics_activity_returns_seven_days_by_default(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return seven consecutive activity days by default."""

    user = User(
        display_name="Local User",
        is_local=True,
    )

    db_session.add(user)
    db_session.commit()

    response = client.get(
        "/api/v1/statistics/activity",
    )

    assert response.status_code == 200

    payload = response.json()

    assert len(payload["days"]) == 7

    assert payload["start_date"] is not None
    assert payload["end_date"] is not None

    assert set(payload["days"][0]) == {
        "day",
        "episodes_watched",
        "movies_watched",
        "episode_watch_time_minutes",
        "movie_watch_time_minutes",
        "watch_time_minutes",
    }

def test_get_statistics_activity_supports_fourteen_days(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return fourteen consecutive activity days when requested."""

    user = User(
        display_name="Local User",
        is_local=True,
    )

    db_session.add(user)
    db_session.commit()

    response = client.get(
        "/api/v1/statistics/activity",
        params={
            "days": 14,
        },
    )

    assert response.status_code == 200

    payload = response.json()

    assert len(payload["days"]) == 14

def test_get_statistics_activity_rejects_unsupported_range(
    client: TestClient,
    db_session: Session,
) -> None:
    """Reject unsupported activity ranges."""

    user = User(
        display_name="Local User",
        is_local=True,
    )

    db_session.add(user)
    db_session.commit()

    response = client.get(
        "/api/v1/statistics/activity",
        params={
            "days": 30,
        },
    )

    assert response.status_code == 400

    assert response.json() == {
        "error": {
            "code": "invalid_statistics_activity_range",
            "message": (
                "Statistics activity supports only 7 or 14 days."
            ),
        }
    }