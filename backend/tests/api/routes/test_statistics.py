from datetime import UTC, datetime, timedelta

import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.models.enums import LibraryStatus
from app.models.episode import Episode
from app.models.episode_watch_event import EpisodeWatchEvent
from app.models.genre import Genre
from app.models.library import LibraryEntry
from app.models.movie import Movie
from app.models.movie_watch_event import MovieWatchEvent
from app.models.season import Season
from app.models.show import Show
from app.models.user import User


def create_local_user(
    db_session: Session,
) -> User:
    """Create and persist the local SofaWatch user."""

    user = User(
        display_name="Local User",
    )

    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)

    return user


def test_get_weekly_statistics_returns_current_user_summary(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return a combined Episode and Movie summary for the local user."""

    user = create_local_user(
        db_session,
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

    create_local_user(
        db_session,
    )

    response = client.get(
        "/api/v1/statistics/weekly",
    )

    assert response.status_code == 200

    payload = response.json()

    assert payload["episodes_watched"] == 0
    assert payload["movies_watched"] == 0
    assert payload["watch_time_minutes"] == 0


def test_get_statistics_activity_returns_seven_days_by_default(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return seven consecutive activity days by default."""

    create_local_user(
        db_session,
    )

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


@pytest.mark.parametrize(
    ("activity_range", "expected_days"),
    [
        ("7d", 7),
        ("14d", 14),
        ("30d", 30),
        ("90d", 90),
        ("1y", 365),
    ],
)
def test_get_statistics_activity_supports_fixed_ranges(
    client: TestClient,
    db_session: Session,
    activity_range: str,
    expected_days: int,
) -> None:
    """Return the requested supported fixed activity range."""

    create_local_user(
        db_session,
    )

    response = client.get(
        "/api/v1/statistics/activity",
        params={
            "range": activity_range,
        },
    )

    assert response.status_code == 200

    payload = response.json()

    assert len(payload["days"]) == expected_days
    assert payload["start_date"] is not None
    assert payload["end_date"] is not None


def test_get_statistics_activity_all_without_history_returns_today(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return one zero-activity day for All when no history exists."""

    create_local_user(
        db_session,
    )

    response = client.get(
        "/api/v1/statistics/activity",
        params={
            "range": "all",
        },
    )

    assert response.status_code == 200

    payload = response.json()

    assert payload["start_date"] == payload["end_date"]

    assert len(payload["days"]) == 1

    day = payload["days"][0]

    assert day["day"] == payload["start_date"]
    assert day["episodes_watched"] == 0
    assert day["movies_watched"] == 0
    assert day["episode_watch_time_minutes"] == 0
    assert day["movie_watch_time_minutes"] == 0
    assert day["watch_time_minutes"] == 0


def test_get_statistics_activity_all_starts_at_earliest_viewing(
    client: TestClient,
    db_session: Session,
) -> None:
    """Start All activity at the user's earliest recorded viewing."""

    user = create_local_user(
        db_session,
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

    earliest_viewing = datetime(
        2025,
        6,
        10,
        20,
        0,
        tzinfo=UTC,
    )

    later_viewing = datetime(
        2026,
        1,
        15,
        21,
        0,
        tzinfo=UTC,
    )

    db_session.add_all(
        [
            EpisodeWatchEvent(
                user_id=user.id,
                episode_id=episode.id,
                watched_at=later_viewing,
            ),
            MovieWatchEvent(
                user_id=user.id,
                movie_id=movie.id,
                watched_at=earliest_viewing,
            ),
        ]
    )

    db_session.commit()

    response = client.get(
        "/api/v1/statistics/activity",
        params={
            "range": "all",
        },
    )

    assert response.status_code == 200

    payload = response.json()

    assert payload["start_date"] == "2025-06-10"

    assert payload["days"][0]["day"] == "2025-06-10"

    assert payload["days"][0]["movies_watched"] == 1
    assert payload["days"][0]["episodes_watched"] == 0


def test_get_statistics_activity_rejects_unsupported_range(
    client: TestClient,
    db_session: Session,
) -> None:
    """Reject unsupported activity-range enum values."""

    create_local_user(
        db_session,
    )

    response = client.get(
        "/api/v1/statistics/activity",
        params={
            "range": "invalid",
        },
    )

    assert response.status_code == 422


def test_get_statistics_habits_returns_current_and_longest_streaks(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return combined Episode and Movie streak statistics."""

    user = User(
        display_name="Local User",
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

    db_session.add(season)
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

    db_session.add(episode)
    db_session.commit()

    today = datetime.now(UTC).date()

    db_session.add_all(
        [
            EpisodeWatchEvent(
                user_id=user.id,
                episode_id=episode.id,
                watched_at=datetime.combine(
                    today - timedelta(days=3),
                    datetime.min.time(),
                    tzinfo=UTC,
                ),
            ),
            MovieWatchEvent(
                user_id=user.id,
                movie_id=movie.id,
                watched_at=datetime.combine(
                    today - timedelta(days=2),
                    datetime.min.time(),
                    tzinfo=UTC,
                ),
            ),
            EpisodeWatchEvent(
                user_id=user.id,
                episode_id=episode.id,
                watched_at=datetime.combine(
                    today - timedelta(days=1),
                    datetime.min.time(),
                    tzinfo=UTC,
                ),
            ),
            MovieWatchEvent(
                user_id=user.id,
                movie_id=movie.id,
                watched_at=datetime.combine(
                    today,
                    datetime.min.time(),
                    tzinfo=UTC,
                ),
            ),
        ]
    )

    db_session.commit()

    movie_days = [
        today - timedelta(days=2),
        today,
    ]

    expected_most_active_weekday = min(
        movie_days,
        key=lambda day: day.weekday(),
    ).strftime("%A")

    response = client.get(
        "/api/v1/statistics/habits",
    )

    assert response.status_code == 200

    assert response.json() == {
        "current_streak_days": 4,
        "longest_streak_days": 4,
        "biggest_marathon_watch_time_minutes": 155,
        "biggest_marathon_day": today.isoformat(),
        "longest_binge_episode_count": 1,
        "longest_binge_day": (today - timedelta(days=1)).isoformat(),
        "average_active_day_watch_time_minutes": 103,
        "most_active_weekday": expected_most_active_weekday,
        "most_active_weekday_watch_count": 1,
    }


def test_get_statistics_habits_returns_zeroes_without_viewing_history(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return zero streaks when the local user has no viewing history."""

    user = User(
        display_name="Local User",
    )

    db_session.add(user)
    db_session.commit()

    response = client.get(
        "/api/v1/statistics/habits",
    )

    assert response.status_code == 200

    assert response.json() == {
        "current_streak_days": 0,
        "longest_streak_days": 0,
        "biggest_marathon_watch_time_minutes": 0,
        "biggest_marathon_day": None,
        "longest_binge_episode_count": 0,
        "longest_binge_day": None,
        "average_active_day_watch_time_minutes": 0,
        "most_active_weekday": None,
        "most_active_weekday_watch_count": 0,
    }


def test_get_statistics_habits_keeps_yesterday_streak_alive(
    client: TestClient,
    db_session: Session,
) -> None:
    """Keep the current streak alive when the latest viewing was yesterday."""

    user = User(
        display_name="Local User",
    )

    show = Show(
        tmdb_id=95396,
        title="Severance",
        original_title="Severance",
        original_language="en",
        metadata_language="en-US",
    )

    db_session.add_all(
        [
            user,
            show,
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

    db_session.add(season)
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

    db_session.add(episode)
    db_session.commit()

    today = datetime.now(UTC).date()

    for days_ago in (
        3,
        2,
        1,
    ):
        db_session.add(
            EpisodeWatchEvent(
                user_id=user.id,
                episode_id=episode.id,
                watched_at=datetime.combine(
                    today - timedelta(days=days_ago),
                    datetime.min.time(),
                    tzinfo=UTC,
                ),
            )
        )

    db_session.commit()

    response = client.get(
        "/api/v1/statistics/habits",
    )

    active_days = [
        today - timedelta(days=3),
        today - timedelta(days=2),
        today - timedelta(days=1),
    ]

    expected_most_active_weekday = min(
        active_days,
        key=lambda day: day.weekday(),
    ).strftime("%A")

    assert response.status_code == 200

    assert response.json() == {
        "current_streak_days": 3,
        "longest_streak_days": 3,
        "biggest_marathon_watch_time_minutes": 50,
        "biggest_marathon_day": (today - timedelta(days=1)).isoformat(),
        "longest_binge_episode_count": 1,
        "longest_binge_day": (today - timedelta(days=1)).isoformat(),
        "average_active_day_watch_time_minutes": 50,
        "most_active_weekday": expected_most_active_weekday,
        "most_active_weekday_watch_count": 1,
    }


def test_get_statistics_content_insights_returns_ranked_content(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return all Content Insights rankings for the local user."""

    user = create_local_user(
        db_session,
    )

    drama = Genre(
        name="Drama",
        slug="drama",
    )

    science_fiction = Genre(
        name="Science Fiction",
        slug="science-fiction",
    )

    comedy = Genre(
        name="Comedy",
        slug="comedy",
    )

    severance = Show(
        tmdb_id=95396,
        title="Severance",
        original_title="Severance",
        original_language="en",
        metadata_language="en-US",
    )

    comedy_show = Show(
        tmdb_id=999001,
        title="Comedy Show",
        original_title="Comedy Show",
        original_language="en",
        metadata_language="en-US",
    )

    dune = Movie(
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

    arrival = Movie(
        tmdb_id=329865,
        title="Arrival",
        original_title="Arrival",
        original_language="en",
        runtime=116,
        status="Released",
        adult=False,
        video=False,
        popularity=10.0,
        vote_average=8.0,
        vote_count=100,
        metadata_language="en-US",
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

    dune.genres.extend(
        [
            drama,
            science_fiction,
        ]
    )

    arrival.genres.append(
        science_fiction,
    )

    db_session.add_all(
        [
            drama,
            science_fiction,
            comedy,
            severance,
            comedy_show,
            dune,
            arrival,
        ]
    )

    db_session.commit()

    severance_season = Season(
        show_id=severance.id,
        tmdb_id=134792,
        season_number=1,
        title="Season 1",
        overview=None,
        air_date=None,
        episode_count=2,
        vote_average=0.0,
    )

    comedy_season = Season(
        show_id=comedy_show.id,
        tmdb_id=999002,
        season_number=1,
        title="Season 1",
        overview=None,
        air_date=None,
        episode_count=1,
        vote_average=0.0,
    )

    db_session.add_all(
        [
            severance_season,
            comedy_season,
        ]
    )

    db_session.commit()

    first_episode = Episode(
        season_id=severance_season.id,
        tmdb_id=2101,
        episode_number=1,
        title="Good News About Hell",
        overview=None,
        air_date=None,
        runtime=50,
        vote_average=0.0,
        vote_count=0,
    )

    second_episode = Episode(
        season_id=severance_season.id,
        tmdb_id=2102,
        episode_number=2,
        title="Half Loop",
        overview=None,
        air_date=None,
        runtime=50,
        vote_average=0.0,
        vote_count=0,
    )

    comedy_episode = Episode(
        season_id=comedy_season.id,
        tmdb_id=999003,
        episode_number=1,
        title="Pilot",
        overview=None,
        air_date=None,
        runtime=30,
        vote_average=0.0,
        vote_count=0,
    )

    db_session.add_all(
        [
            first_episode,
            second_episode,
            comedy_episode,
        ]
    )

    db_session.commit()

    base_time = datetime(
        2026,
        8,
        18,
        10,
        0,
        tzinfo=UTC,
    )

    db_session.add_all(
        [
            # First Severance Episode:
            # 3 watches -> 2 rewatches.
            EpisodeWatchEvent(
                user_id=user.id,
                episode_id=first_episode.id,
                watched_at=base_time,
            ),
            EpisodeWatchEvent(
                user_id=user.id,
                episode_id=first_episode.id,
                watched_at=base_time + timedelta(hours=1),
            ),
            EpisodeWatchEvent(
                user_id=user.id,
                episode_id=first_episode.id,
                watched_at=base_time + timedelta(hours=2),
            ),
            # Second Severance Episode:
            # 2 watches -> 1 rewatch.
            EpisodeWatchEvent(
                user_id=user.id,
                episode_id=second_episode.id,
                watched_at=base_time + timedelta(hours=3),
            ),
            EpisodeWatchEvent(
                user_id=user.id,
                episode_id=second_episode.id,
                watched_at=base_time + timedelta(hours=4),
            ),
            # Comedy Show: one watch.
            EpisodeWatchEvent(
                user_id=user.id,
                episode_id=comedy_episode.id,
                watched_at=base_time + timedelta(hours=5),
            ),
            # Dune: 3 watches -> 2 rewatches.
            MovieWatchEvent(
                user_id=user.id,
                movie_id=dune.id,
                watched_at=base_time + timedelta(hours=6),
            ),
            MovieWatchEvent(
                user_id=user.id,
                movie_id=dune.id,
                watched_at=base_time + timedelta(hours=7),
            ),
            MovieWatchEvent(
                user_id=user.id,
                movie_id=dune.id,
                watched_at=base_time + timedelta(hours=8),
            ),
            # Arrival: 2 watches -> 1 rewatch.
            MovieWatchEvent(
                user_id=user.id,
                movie_id=arrival.id,
                watched_at=base_time + timedelta(hours=9),
            ),
            MovieWatchEvent(
                user_id=user.id,
                movie_id=arrival.id,
                watched_at=base_time + timedelta(hours=10),
            ),
        ]
    )

    db_session.commit()

    response = client.get(
        "/api/v1/statistics/content-insights",
    )

    assert response.status_code == 200

    payload = response.json()

    assert [
        (
            item["title"],
            item["watch_count"],
        )
        for item in payload["most_watched_shows"]
    ] == [
        (
            "Severance",
            5,
        ),
        (
            "Comedy Show",
            1,
        ),
    ]

    assert [
        (
            item["title"],
            item["watch_count"],
            item["rewatch_count"],
        )
        for item in payload["most_rewatched_shows"]
    ] == [
        (
            "Severance",
            5,
            3,
        ),
    ]

    assert [
        (
            item["episode_title"],
            item["watch_count"],
            item["rewatch_count"],
        )
        for item in payload["most_rewatched_episodes"]
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

    assert [
        (
            item["title"],
            item["watch_count"],
            item["rewatch_count"],
        )
        for item in payload["most_rewatched_movies"]
    ] == [
        (
            "Dune",
            3,
            2,
        ),
        (
            "Arrival",
            2,
            1,
        ),
    ]

    assert [
        (
            item["name"],
            item["watch_count"],
        )
        for item in payload["top_show_genres"]
    ] == [
        (
            "Drama",
            5,
        ),
        (
            "Science Fiction",
            5,
        ),
        (
            "Comedy",
            1,
        ),
    ]

    assert [
        (
            item["name"],
            item["watch_count"],
        )
        for item in payload["top_movie_genres"]
    ] == [
        (
            "Science Fiction",
            5,
        ),
        (
            "Drama",
            3,
        ),
    ]


def test_get_statistics_content_insights_returns_empty_lists_without_history(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return usable empty Content Insights without viewing history."""

    create_local_user(
        db_session,
    )

    response = client.get(
        "/api/v1/statistics/content-insights",
    )

    assert response.status_code == 200

    assert response.json() == {
        "most_watched_shows": [],
        "most_rewatched_shows": [],
        "most_rewatched_episodes": [],
        "most_rewatched_movies": [],
        "top_show_genres": [],
        "top_movie_genres": [],
    }


def test_get_statistics_library_returns_current_user_counts(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return current Library statistics for the local user."""

    user = create_local_user(
        db_session,
    )

    watching_show = Show(
        tmdb_id=95396,
        title="Severance",
        original_title="Severance",
        original_language="en",
        metadata_language="en-US",
    )

    completed_show = Show(
        tmdb_id=1396,
        title="Breaking Bad",
        original_title="Breaking Bad",
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
            watching_show,
            completed_show,
            movie,
        ]
    )

    db_session.commit()

    db_session.add_all(
        [
            LibraryEntry(
                user_id=user.id,
                show_id=watching_show.id,
                status=LibraryStatus.WATCHING,
            ),
            LibraryEntry(
                user_id=user.id,
                show_id=completed_show.id,
                status=LibraryStatus.COMPLETED,
            ),
            LibraryEntry(
                user_id=user.id,
                movie_id=movie.id,
                status=LibraryStatus.COMPLETED,
            ),
        ]
    )

    db_session.commit()

    response = client.get(
        "/api/v1/statistics/library",
    )

    assert response.status_code == 200

    assert response.json() == {
        "shows_added": 2,
        "movies_added": 1,
        "shows_completed": 1,
    }


def test_get_statistics_library_returns_zeroes_for_empty_library(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return usable zero Library statistics without entries."""

    create_local_user(
        db_session,
    )

    response = client.get(
        "/api/v1/statistics/library",
    )

    assert response.status_code == 200

    assert response.json() == {
        "shows_added": 0,
        "movies_added": 0,
        "shows_completed": 0,
    }


def test_get_statistics_backlog_returns_current_backlog(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return current backlog and future viewing statistics."""

    user = create_local_user(
        db_session,
    )

    show = Show(
        tmdb_id=95396,
        title="Severance",
        original_title="Severance",
        original_language="en",
        metadata_language="en-US",
    )

    planned_movie = Movie(
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
            show,
            planned_movie,
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

    today = datetime.now(
        UTC,
    ).date()

    episode = Episode(
        season_id=season.id,
        tmdb_id=2101,
        episode_number=1,
        title="Good News About Hell",
        overview=None,
        air_date=today,
        runtime=50,
        vote_average=0.0,
        vote_count=0,
    )

    db_session.add(
        episode,
    )

    db_session.commit()

    db_session.add_all(
        [
            LibraryEntry(
                user_id=user.id,
                show_id=show.id,
                status=LibraryStatus.WATCHING,
            ),
            LibraryEntry(
                user_id=user.id,
                movie_id=planned_movie.id,
                status=LibraryStatus.PLANNING,
            ),
        ]
    )

    db_session.commit()

    response = client.get(
        "/api/v1/statistics/backlog",
    )

    assert response.status_code == 200

    assert response.json() == {
        "unwatched_aired_episodes": 1,
        "planned_movies": 1,
        "future_watch_time_minutes": 205,
        "catch_up_speed_episodes_per_week": 0.0,
        "backlog_trend": "growing",
        "backlog_trend_episode_delta": 1,
    }


def test_get_statistics_backlog_returns_zeroes_without_backlog(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return usable zero backlog statistics when nothing is pending."""

    create_local_user(
        db_session,
    )

    response = client.get(
        "/api/v1/statistics/backlog",
    )

    assert response.status_code == 200

    assert response.json() == {
        "unwatched_aired_episodes": 0,
        "planned_movies": 0,
        "future_watch_time_minutes": 0,
        "catch_up_speed_episodes_per_week": 0.0,
        "backlog_trend": "stable",
        "backlog_trend_episode_delta": 0,
    }
