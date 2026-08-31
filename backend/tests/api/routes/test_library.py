from datetime import UTC, date, datetime, timedelta
from uuid import uuid4

import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.models.enums import LibraryStatus
from app.models.episode import Episode
from app.models.episode_progress import EpisodeProgress
from app.models.episode_watch_event import EpisodeWatchEvent
from app.models.library import LibraryEntry
from app.models.movie import Movie
from app.models.movie_watch_event import MovieWatchEvent
from app.models.season import Season
from app.models.show import Show
from app.models.user import User


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


def create_user(
    db_session: Session,
    *,
    display_name: str,
) -> User:
    """Create and persist a non-local user."""

    user = User(
        display_name=display_name,
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


def create_library_entry(
    db_session: Session,
    *,
    user: User,
    show: Show,
    status: LibraryStatus = LibraryStatus.PLANNING,
) -> LibraryEntry:
    """Create and persist a library entry."""

    entry = LibraryEntry(
        user_id=user.id,
        show_id=show.id,
        status=status,
    )

    db_session.add(entry)
    db_session.commit()
    db_session.refresh(entry)

    return entry


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
    air_date: date | None,
) -> Episode:
    """Create and persist a TV episode."""

    episode = Episode(
        season_id=season.id,
        tmdb_id=tmdb_id,
        episode_number=episode_number,
        title=title,
        overview=None,
        air_date=air_date,
        runtime=52,
        vote_average=0.0,
        vote_count=0,
    )

    db_session.add(episode)
    db_session.commit()
    db_session.refresh(episode)

    return episode


def create_episode_watch_event(
    db_session: Session,
    *,
    user: User,
    episode: Episode,
    watched_at: datetime,
) -> EpisodeWatchEvent:
    """Create and persist one historical Episode viewing event."""

    event = EpisodeWatchEvent(
        user_id=user.id,
        episode_id=episode.id,
        watched_at=watched_at,
    )

    db_session.add(event)
    db_session.commit()
    db_session.refresh(event)

    return event


def create_episode_progress(
    db_session: Session,
    *,
    user: User,
    episode: Episode,
    is_watched: bool,
) -> EpisodeProgress:
    """Create and persist Episode progress for a user."""

    progress = EpisodeProgress(
        user_id=user.id,
        episode_id=episode.id,
        is_watched=is_watched,
        watched_at=datetime.now(UTC) if is_watched else None,
    )

    db_session.add(progress)
    db_session.commit()
    db_session.refresh(progress)

    return progress


def create_movie(
    db_session: Session,
    *,
    tmdb_id: int,
    title: str,
) -> Movie:
    """Create and persist a locally stored Movie."""

    movie = Movie(
        tmdb_id=tmdb_id,
        title=title,
        original_title=title,
        original_language="en",
        runtime=120,
        status="Released",
        adult=False,
        video=False,
        popularity=10.0,
        vote_average=8.0,
        vote_count=100,
        metadata_language="en-US",
    )

    db_session.add(movie)
    db_session.commit()
    db_session.refresh(movie)

    return movie


def create_movie_library_entry(
    db_session: Session,
    *,
    user: User,
    movie: Movie,
    status: LibraryStatus = LibraryStatus.PLANNING,
) -> LibraryEntry:
    """Create and persist a Movie library entry."""

    entry = LibraryEntry(
        user_id=user.id,
        movie_id=movie.id,
        status=status,
    )

    db_session.add(entry)
    db_session.commit()
    db_session.refresh(entry)

    return entry


def create_movie_watch_event(
    db_session: Session,
    *,
    user: User,
    movie: Movie,
    watched_at: datetime,
) -> MovieWatchEvent:
    """Create and persist one historical Movie viewing."""

    event = MovieWatchEvent(
        user_id=user.id,
        movie_id=movie.id,
        watched_at=watched_at,
    )

    db_session.add(event)
    db_session.commit()
    db_session.refresh(event)

    return event


def test_add_show_to_library(
    client: TestClient,
    db_session: Session,
) -> None:
    """Add a locally stored TV series to the current user's library."""

    local_user = create_local_user(db_session)

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    response = client.post(
        f"/api/v1/library/shows/{show.id}",
    )

    assert response.status_code == 200

    body = response.json()

    assert body["show_id"] == str(show.id)
    assert body["status"] == "planning"
    assert body["rating"] is None
    assert body["started_at"] is None
    assert body["completed_at"] is None

    entry = (
        db_session.query(LibraryEntry)
        .filter(
            LibraryEntry.user_id == local_user.id,
            LibraryEntry.show_id == show.id,
        )
        .one_or_none()
    )

    assert entry is not None
    assert entry.status == LibraryStatus.PLANNING


def test_add_show_to_library_returns_404_when_show_does_not_exist(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return HTTP 404 when the TV series does not exist locally."""

    create_local_user(db_session)

    response = client.post(
        f"/api/v1/library/shows/{uuid4()}",
    )

    assert response.status_code == 404
    assert response.json() == {
        "error": {
            "code": "show_not_found",
            "message": "TV series not found.",
        }
    }


def test_add_show_to_library_is_idempotent_when_already_present(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return the existing entry when the TV series is already in the library."""

    local_user = create_local_user(db_session)

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    existing_entry = create_library_entry(
        db_session,
        user=local_user,
        show=show,
    )

    response = client.post(
        f"/api/v1/library/shows/{show.id}",
    )

    assert response.status_code == 200

    body = response.json()

    assert body["id"] == str(existing_entry.id)
    assert body["show_id"] == str(show.id)
    assert body["movie_id"] is None
    assert body["status"] == "planning"

    entries = (
        db_session.query(LibraryEntry)
        .filter(
            LibraryEntry.user_id == local_user.id,
            LibraryEntry.show_id == show.id,
        )
        .all()
    )

    assert len(entries) == 1


def test_add_show_to_library_rejects_invalid_show_id(
    client: TestClient,
    db_session: Session,
) -> None:
    """Reject an invalid TV series identifier."""

    create_local_user(db_session)

    response = client.post(
        "/api/v1/library/shows/not-a-valid-uuid",
    )

    assert response.status_code == 422


def test_remove_show_from_library(
    client: TestClient,
    db_session: Session,
) -> None:
    """Remove a TV series from the current user's library."""

    local_user = create_local_user(db_session)

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    create_library_entry(
        db_session,
        user=local_user,
        show=show,
    )

    response = client.delete(
        f"/api/v1/library/shows/{show.id}",
    )

    assert response.status_code == 204
    assert response.content == b""

    entry = (
        db_session.query(LibraryEntry)
        .filter(
            LibraryEntry.user_id == local_user.id,
            LibraryEntry.show_id == show.id,
        )
        .one_or_none()
    )

    assert entry is None


def test_remove_show_from_library_returns_404_when_missing(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return HTTP 404 when the TV series is not in the library."""

    create_local_user(db_session)

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    response = client.delete(
        f"/api/v1/library/shows/{show.id}",
    )

    assert response.status_code == 404
    assert response.json() == {
        "error": {
            "code": "library_entry_not_found",
            "message": "TV series is not in the library.",
        }
    }


def test_update_library_status(
    client: TestClient,
    db_session: Session,
) -> None:
    """Update the tracking status of a library entry."""

    local_user = create_local_user(db_session)

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    entry = create_library_entry(
        db_session,
        user=local_user,
        show=show,
        status=LibraryStatus.PLANNING,
    )

    response = client.patch(
        f"/api/v1/library/shows/{show.id}/status",
        json={
            "status": "watching",
        },
    )

    assert response.status_code == 200

    body = response.json()

    assert body["id"] == str(entry.id)
    assert body["show_id"] == str(show.id)
    assert body["status"] == "watching"

    db_session.refresh(entry)

    assert entry.status == LibraryStatus.WATCHING


def test_update_library_status_returns_404_when_missing(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return HTTP 404 when updating a show outside the library."""

    create_local_user(db_session)

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    response = client.patch(
        f"/api/v1/library/shows/{show.id}/status",
        json={
            "status": "watching",
        },
    )

    assert response.status_code == 404
    assert response.json() == {
        "error": {
            "code": "library_entry_not_found",
            "message": "TV series is not in the library.",
        }
    }


@pytest.mark.parametrize(
    "library_status",
    [
        "banana",
        "finished",
        "",
    ],
)
def test_update_library_status_rejects_invalid_status(
    client: TestClient,
    db_session: Session,
    library_status: str,
) -> None:
    """Reject unsupported library tracking states."""

    local_user = create_local_user(db_session)

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    create_library_entry(
        db_session,
        user=local_user,
        show=show,
    )

    response = client.patch(
        f"/api/v1/library/shows/{show.id}/status",
        json={
            "status": library_status,
        },
    )

    assert response.status_code == 422


def test_list_library_returns_current_user_entries(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return the current user's personal library."""

    local_user = create_local_user(db_session)

    first_show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )
    second_show = create_show(
        db_session,
        tmdb_id=1396,
        title="Breaking Bad",
    )

    create_library_entry(
        db_session,
        user=local_user,
        show=first_show,
        status=LibraryStatus.WATCHING,
    )
    create_library_entry(
        db_session,
        user=local_user,
        show=second_show,
        status=LibraryStatus.PLANNING,
    )

    response = client.get("/api/v1/library")

    assert response.status_code == 200

    body = response.json()

    assert len(body) == 2

    assert {item["show_id"] for item in body} == {
        str(first_show.id),
        str(second_show.id),
    }


def test_list_library_filters_by_status(
    client: TestClient,
    db_session: Session,
) -> None:
    """Filter the current user's library by tracking status."""

    local_user = create_local_user(db_session)

    watching_show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )
    planning_show = create_show(
        db_session,
        tmdb_id=1396,
        title="Breaking Bad",
    )

    create_library_entry(
        db_session,
        user=local_user,
        show=watching_show,
        status=LibraryStatus.WATCHING,
    )
    create_library_entry(
        db_session,
        user=local_user,
        show=planning_show,
        status=LibraryStatus.PLANNING,
    )

    response = client.get(
        "/api/v1/library",
        params={
            "status": "watching",
        },
    )

    assert response.status_code == 200

    body = response.json()

    assert len(body) == 1
    assert body[0]["show_id"] == str(watching_show.id)
    assert body[0]["status"] == "watching"


def test_list_library_rejects_invalid_status(
    client: TestClient,
    db_session: Session,
) -> None:
    """Reject an unsupported library status filter."""

    create_local_user(db_session)

    response = client.get(
        "/api/v1/library",
        params={
            "status": "banana",
        },
    )

    assert response.status_code == 422


def test_library_isolated_between_users(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return only entries belonging to the current local user."""

    local_user = create_local_user(db_session)

    other_user = create_user(
        db_session,
        display_name="Other User",
    )

    local_show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )
    other_show = create_show(
        db_session,
        tmdb_id=1396,
        title="Breaking Bad",
    )

    create_library_entry(
        db_session,
        user=local_user,
        show=local_show,
    )
    create_library_entry(
        db_session,
        user=other_user,
        show=other_show,
    )

    response = client.get("/api/v1/library")

    assert response.status_code == 200

    body = response.json()

    assert len(body) == 1
    assert body[0]["show_id"] == str(local_show.id)


def test_add_movie_to_library(
    client: TestClient,
    db_session: Session,
) -> None:
    """Add a locally stored Movie to the current user's library."""

    local_user = create_local_user(db_session)

    movie = create_movie(
        db_session,
        tmdb_id=438631,
        title="Dune",
    )

    response = client.post(
        f"/api/v1/library/movies/{movie.id}",
    )

    assert response.status_code == 200

    body = response.json()

    assert body["show_id"] is None
    assert body["movie_id"] == str(movie.id)
    assert body["status"] == "planning"
    assert body["rating"] is None
    assert body["started_at"] is None
    assert body["completed_at"] is None

    entry = (
        db_session.query(LibraryEntry)
        .filter(
            LibraryEntry.user_id == local_user.id,
            LibraryEntry.movie_id == movie.id,
        )
        .one_or_none()
    )

    assert entry is not None
    assert entry.show_id is None
    assert entry.movie_id == movie.id
    assert entry.status == LibraryStatus.PLANNING


def test_add_movie_to_library_returns_404_when_movie_does_not_exist(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return HTTP 404 when the Movie does not exist locally."""

    create_local_user(db_session)

    response = client.post(
        f"/api/v1/library/movies/{uuid4()}",
    )

    assert response.status_code == 404

    assert response.json() == {
        "error": {
            "code": "movie_not_found",
            "message": "The requested movie was not found.",
        }
    }


def test_add_movie_to_library_is_idempotent_when_already_present(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return the existing entry when the Movie is already in the library."""

    local_user = create_local_user(db_session)

    movie = create_movie(
        db_session,
        tmdb_id=438631,
        title="Dune",
    )

    existing_entry = create_movie_library_entry(
        db_session,
        user=local_user,
        movie=movie,
    )

    response = client.post(
        f"/api/v1/library/movies/{movie.id}",
    )

    assert response.status_code == 200

    body = response.json()

    assert body["id"] == str(existing_entry.id)
    assert body["show_id"] is None
    assert body["movie_id"] == str(movie.id)
    assert body["status"] == "planning"

    entries = (
        db_session.query(LibraryEntry)
        .filter(
            LibraryEntry.user_id == local_user.id,
            LibraryEntry.movie_id == movie.id,
        )
        .all()
    )

    assert len(entries) == 1


def test_add_movie_to_library_rejects_invalid_movie_id(
    client: TestClient,
    db_session: Session,
) -> None:
    """Reject an invalid Movie identifier."""

    create_local_user(db_session)

    response = client.post(
        "/api/v1/library/movies/not-a-valid-uuid",
    )

    assert response.status_code == 422


def test_get_movie_library_entry(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return the current user's library entry for a Movie."""

    local_user = create_local_user(db_session)

    movie = create_movie(
        db_session,
        tmdb_id=438631,
        title="Dune",
    )

    entry = create_movie_library_entry(
        db_session,
        user=local_user,
        movie=movie,
    )

    response = client.get(
        f"/api/v1/library/movies/{movie.id}",
    )

    assert response.status_code == 200

    body = response.json()

    assert body["id"] == str(entry.id)
    assert body["show_id"] is None
    assert body["movie_id"] == str(movie.id)
    assert body["status"] == "planning"
    assert body["rating"] is None
    assert body["started_at"] is None
    assert body["completed_at"] is None


def test_get_movie_library_entry_returns_404_when_missing(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return HTTP 404 when the Movie is not in the current user's library."""

    create_local_user(db_session)

    movie = create_movie(
        db_session,
        tmdb_id=438631,
        title="Dune",
    )

    response = client.get(
        f"/api/v1/library/movies/{movie.id}",
    )

    assert response.status_code == 404

    assert response.json() == {
        "error": {
            "code": "library_entry_not_found",
            "message": "The movie is not in the user's library.",
        }
    }


def test_get_movie_library_entry_rejects_invalid_movie_id(
    client: TestClient,
    db_session: Session,
) -> None:
    """Reject an invalid Movie identifier."""

    create_local_user(db_session)

    response = client.get(
        "/api/v1/library/movies/not-a-valid-uuid",
    )

    assert response.status_code == 422


def test_remove_movie_from_library(
    client: TestClient,
    db_session: Session,
) -> None:
    """Remove a Movie from the current user's library."""

    local_user = create_local_user(db_session)

    movie = create_movie(
        db_session,
        tmdb_id=438631,
        title="Dune",
    )

    create_movie_library_entry(
        db_session,
        user=local_user,
        movie=movie,
    )

    response = client.delete(
        f"/api/v1/library/movies/{movie.id}",
    )

    assert response.status_code == 204
    assert response.content == b""

    entry = (
        db_session.query(LibraryEntry)
        .filter(
            LibraryEntry.user_id == local_user.id,
            LibraryEntry.movie_id == movie.id,
        )
        .one_or_none()
    )

    assert entry is None


def test_remove_movie_from_library_returns_404_when_missing(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return HTTP 404 when the Movie is not in the library."""

    create_local_user(db_session)

    movie = create_movie(
        db_session,
        tmdb_id=438631,
        title="Dune",
    )

    response = client.delete(
        f"/api/v1/library/movies/{movie.id}",
    )

    assert response.status_code == 404

    assert response.json() == {
        "error": {
            "code": "library_entry_not_found",
            "message": "The movie is not in the user's library.",
        }
    }


def test_update_movie_library_status_to_completed(
    client: TestClient,
    db_session: Session,
) -> None:
    """Mark a Movie in the library as completed."""

    local_user = create_local_user(db_session)

    movie = create_movie(
        db_session,
        tmdb_id=438631,
        title="Dune",
    )

    entry = create_movie_library_entry(
        db_session,
        user=local_user,
        movie=movie,
        status=LibraryStatus.PLANNING,
    )

    assert entry.completed_at is None

    response = client.patch(
        f"/api/v1/library/movies/{movie.id}/status",
        json={
            "status": "completed",
        },
    )

    assert response.status_code == 200

    body = response.json()

    assert body["movie_id"] == str(movie.id)
    assert body["show_id"] is None
    assert body["status"] == "completed"
    assert body["completed_at"] is not None

    db_session.refresh(entry)

    assert entry.status == LibraryStatus.COMPLETED
    assert entry.completed_at is not None


def test_update_movie_library_status_to_planning(
    client: TestClient,
    db_session: Session,
) -> None:
    """Mark a completed Movie as not watched."""

    local_user = create_local_user(db_session)

    movie = create_movie(
        db_session,
        tmdb_id=438631,
        title="Dune",
    )

    entry = create_movie_library_entry(
        db_session,
        user=local_user,
        movie=movie,
        status=LibraryStatus.COMPLETED,
    )

    entry.completed_at = datetime.now(UTC)

    db_session.commit()
    db_session.refresh(entry)

    response = client.patch(
        f"/api/v1/library/movies/{movie.id}/status",
        json={
            "status": "planning",
        },
    )

    assert response.status_code == 200

    body = response.json()

    assert body["movie_id"] == str(movie.id)
    assert body["status"] == "planning"
    assert body["completed_at"] is None

    db_session.refresh(entry)

    assert entry.status == LibraryStatus.PLANNING
    assert entry.completed_at is None


def test_update_movie_library_status_returns_404_when_missing(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return HTTP 404 when the Movie is not in the library."""

    create_local_user(db_session)

    movie = create_movie(
        db_session,
        tmdb_id=438631,
        title="Dune",
    )

    response = client.patch(
        f"/api/v1/library/movies/{movie.id}/status",
        json={
            "status": "completed",
        },
    )

    assert response.status_code == 404

    assert response.json() == {
        "error": {
            "code": "library_entry_not_found",
            "message": "The movie is not in the user's library.",
        }
    }


def test_update_movie_library_status_rejects_invalid_status(
    client: TestClient,
    db_session: Session,
) -> None:
    """Reject an unsupported Movie library status."""

    local_user = create_local_user(db_session)

    movie = create_movie(
        db_session,
        tmdb_id=438631,
        title="Dune",
    )

    create_movie_library_entry(
        db_session,
        user=local_user,
        movie=movie,
    )

    response = client.patch(
        f"/api/v1/library/movies/{movie.id}/status",
        json={
            "status": "banana",
        },
    )

    assert response.status_code == 422


def test_get_show_library_entry(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return the current user's library entry for a TV series."""

    local_user = create_local_user(db_session)

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    entry = create_library_entry(
        db_session,
        user=local_user,
        show=show,
        status=LibraryStatus.WATCHING,
    )

    response = client.get(
        f"/api/v1/library/shows/{show.id}",
    )

    assert response.status_code == 200

    body = response.json()

    assert body["id"] == str(entry.id)
    assert body["show_id"] == str(show.id)
    assert body["movie_id"] is None
    assert body["status"] == "watching"


def test_get_show_library_entry_returns_404_when_missing(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return HTTP 404 when the TV series is not in the library."""

    create_local_user(db_session)

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    response = client.get(
        f"/api/v1/library/shows/{show.id}",
    )

    assert response.status_code == 404

    assert response.json() == {
        "error": {
            "code": "library_entry_not_found",
            "message": "TV series is not in the library.",
        }
    }


def test_list_library_shows_returns_show_metadata(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return Library state together with TV series metadata."""

    local_user = create_local_user(db_session)

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    entry = create_library_entry(
        db_session,
        user=local_user,
        show=show,
        status=LibraryStatus.WATCHING,
    )

    response = client.get(
        "/api/v1/library/shows",
    )

    assert response.status_code == 200

    body = response.json()

    assert len(body) == 1

    item = body[0]

    assert item["id"] == str(entry.id)
    assert item["status"] == "watching"

    assert item["show"]["id"] == str(show.id)
    assert item["show"]["tmdb_id"] == 95396
    assert item["show"]["title"] == "Severance"


def test_list_library_shows_excludes_movies(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return only TV series from a mixed media library."""

    local_user = create_local_user(db_session)

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    movie = create_movie(
        db_session,
        tmdb_id=438631,
        title="Dune",
    )

    create_library_entry(
        db_session,
        user=local_user,
        show=show,
    )

    create_movie_library_entry(
        db_session,
        user=local_user,
        movie=movie,
    )

    response = client.get(
        "/api/v1/library/shows",
    )

    assert response.status_code == 200

    body = response.json()

    assert len(body) == 1
    assert body[0]["show"]["tmdb_id"] == 95396


def test_list_library_shows_filters_by_status(
    client: TestClient,
    db_session: Session,
) -> None:
    """Filter Library TV series by tracking status."""

    local_user = create_local_user(db_session)

    watching_show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    planning_show = create_show(
        db_session,
        tmdb_id=1396,
        title="Breaking Bad",
    )

    create_library_entry(
        db_session,
        user=local_user,
        show=watching_show,
        status=LibraryStatus.WATCHING,
    )

    create_library_entry(
        db_session,
        user=local_user,
        show=planning_show,
        status=LibraryStatus.PLANNING,
    )

    response = client.get(
        "/api/v1/library/shows",
        params={
            "status": "watching",
        },
    )

    assert response.status_code == 200

    body = response.json()

    assert len(body) == 1
    assert body[0]["status"] == "watching"
    assert body[0]["show"]["tmdb_id"] == 95396


def test_start_library_show_marks_first_aired_episode_as_watched(
    client: TestClient,
    db_session: Session,
) -> None:
    """Start a Planning Show from its first aired regular Episode."""

    local_user = create_local_user(db_session)

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    entry = create_library_entry(
        db_session,
        user=local_user,
        show=show,
        status=LibraryStatus.PLANNING,
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
        tmdb_id=1947647,
        episode_number=1,
        title="Good News About Hell",
        air_date=date(2026, 8, 1),
    )

    second_episode = create_episode(
        db_session,
        season=season,
        tmdb_id=1947648,
        episode_number=2,
        title="Half Loop",
        air_date=date(2026, 8, 8),
    )

    response = client.post(
        f"/api/v1/library/shows/{show.id}/start",
    )

    assert response.status_code == 200

    body = response.json()

    assert body["library_entry_id"] == str(entry.id)
    assert body["library_status"] == "watching"
    assert body["show_id"] == str(show.id)
    assert body["started_episode_id"] == str(first_episode.id)

    db_session.refresh(entry)

    assert entry.status == LibraryStatus.WATCHING

    first_progress = (
        db_session.query(EpisodeProgress)
        .filter(
            EpisodeProgress.user_id == local_user.id,
            EpisodeProgress.episode_id == first_episode.id,
        )
        .one_or_none()
    )

    assert first_progress is not None
    assert first_progress.is_watched is True
    assert first_progress.watched_at is not None

    second_progress = (
        db_session.query(EpisodeProgress)
        .filter(
            EpisodeProgress.user_id == local_user.id,
            EpisodeProgress.episode_id == second_episode.id,
        )
        .one_or_none()
    )

    assert second_progress is None


def test_start_library_show_uses_first_aired_regular_episode(
    client: TestClient,
    db_session: Session,
) -> None:
    """Ignore Specials and future Episodes when starting a Show."""

    local_user = create_local_user(db_session)

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    entry = create_library_entry(
        db_session,
        user=local_user,
        show=show,
        status=LibraryStatus.PLANNING,
    )

    specials = create_season(
        db_session,
        show=show,
        tmdb_id=134791,
        season_number=0,
        title="Specials",
    )

    first_season = create_season(
        db_session,
        show=show,
        tmdb_id=134792,
        season_number=1,
        title="Season 1",
    )

    special_episode = create_episode(
        db_session,
        season=specials,
        tmdb_id=1900001,
        episode_number=1,
        title="Behind the Scenes",
        air_date=date(2026, 7, 1),
    )

    expected_episode = create_episode(
        db_session,
        season=first_season,
        tmdb_id=1947647,
        episode_number=1,
        title="Good News About Hell",
        air_date=date(2026, 8, 1),
    )

    future_episode = create_episode(
        db_session,
        season=first_season,
        tmdb_id=1947648,
        episode_number=2,
        title="Future Episode",
        air_date=date(2099, 1, 1),
    )

    response = client.post(
        f"/api/v1/library/shows/{show.id}/start",
    )

    assert response.status_code == 200

    body = response.json()

    assert body["library_entry_id"] == str(entry.id)
    assert body["library_status"] == "watching"
    assert body["show_id"] == str(show.id)
    assert body["started_episode_id"] == str(expected_episode.id)

    expected_progress = (
        db_session.query(EpisodeProgress)
        .filter(
            EpisodeProgress.user_id == local_user.id,
            EpisodeProgress.episode_id == expected_episode.id,
        )
        .one_or_none()
    )

    assert expected_progress is not None
    assert expected_progress.is_watched is True
    assert expected_progress.watched_at is not None

    special_progress = (
        db_session.query(EpisodeProgress)
        .filter(
            EpisodeProgress.user_id == local_user.id,
            EpisodeProgress.episode_id == special_episode.id,
        )
        .one_or_none()
    )

    assert special_progress is None

    future_progress = (
        db_session.query(EpisodeProgress)
        .filter(
            EpisodeProgress.user_id == local_user.id,
            EpisodeProgress.episode_id == future_episode.id,
        )
        .one_or_none()
    )

    assert future_progress is None


def test_start_library_show_returns_404_when_no_aired_episode_exists(
    client: TestClient,
    db_session: Session,
) -> None:
    """Do not start a Show without an aired regular Episode."""

    local_user = create_local_user(db_session)

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    entry = create_library_entry(
        db_session,
        user=local_user,
        show=show,
        status=LibraryStatus.PLANNING,
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
        tmdb_id=1947647,
        episode_number=1,
        title="Future Episode",
        air_date=date(2099, 1, 1),
    )

    response = client.post(
        f"/api/v1/library/shows/{show.id}/start",
    )

    assert response.status_code == 404

    assert response.json() == {
        "error": {
            "code": "show_cannot_be_started",
            "message": "TV series cannot be started.",
        }
    }

    db_session.refresh(entry)

    assert entry.status == LibraryStatus.PLANNING

    progress = (
        db_session.query(EpisodeProgress)
        .filter(
            EpisodeProgress.user_id == local_user.id,
            EpisodeProgress.episode_id == episode.id,
        )
        .one_or_none()
    )

    assert progress is None


def test_start_library_show_returns_404_when_show_is_not_in_library(
    client: TestClient,
    db_session: Session,
) -> None:
    """Do not start a Show that is not in the current user's Library."""

    create_local_user(db_session)

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
        tmdb_id=1947647,
        episode_number=1,
        title="Good News About Hell",
        air_date=date(2026, 8, 1),
    )

    response = client.post(
        f"/api/v1/library/shows/{show.id}/start",
    )

    assert response.status_code == 404

    assert response.json() == {
        "error": {
            "code": "show_cannot_be_started",
            "message": "TV series cannot be started.",
        }
    }

    progress = (
        db_session.query(EpisodeProgress)
        .filter(
            EpisodeProgress.episode_id == episode.id,
        )
        .one_or_none()
    )

    assert progress is None


def test_list_watch_next_returns_next_unwatched_episode(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return the next aired unwatched Episode for a Watching Show."""

    local_user = create_local_user(db_session)

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    create_library_entry(
        db_session,
        user=local_user,
        show=show,
        status=LibraryStatus.WATCHING,
    )

    season = create_season(
        db_session,
        show=show,
        tmdb_id=134792,
        season_number=2,
        title="Season 2",
    )

    first_episode = create_episode(
        db_session,
        season=season,
        tmdb_id=1947647,
        episode_number=1,
        title="Hello, Ms. Cobel",
        air_date=date(2026, 8, 1),
    )

    second_episode = create_episode(
        db_session,
        season=season,
        tmdb_id=1947648,
        episode_number=2,
        title="Goodbye, Mrs. Selvig",
        air_date=date(2026, 8, 8),
    )

    create_episode_progress(
        db_session,
        user=local_user,
        episode=first_episode,
        is_watched=True,
    )

    response = client.get(
        "/api/v1/library/shows/watch-next",
    )

    assert response.status_code == 200

    body = response.json()

    assert len(body) == 1

    item = body[0]

    assert item["library_status"] == "watching"

    assert item["show"]["id"] == str(show.id)
    assert item["show"]["tmdb_id"] == 95396
    assert item["show"]["title"] == "Severance"

    assert item["next_episode"]["id"] == str(second_episode.id)
    assert item["next_episode"]["tmdb_id"] == 1947648
    assert item["next_episode"]["season_number"] == 2
    assert item["next_episode"]["episode_number"] == 2
    assert item["next_episode"]["title"] == "Goodbye, Mrs. Selvig"


def test_list_watch_next_excludes_planning_shows(
    client: TestClient,
    db_session: Session,
) -> None:
    """Do not include Shows that have not been started yet."""

    local_user = create_local_user(db_session)

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    create_library_entry(
        db_session,
        user=local_user,
        show=show,
        status=LibraryStatus.PLANNING,
    )

    season = create_season(
        db_session,
        show=show,
        tmdb_id=134792,
        season_number=1,
        title="Season 1",
    )

    create_episode(
        db_session,
        season=season,
        tmdb_id=1947647,
        episode_number=1,
        title="Good News About Hell",
        air_date=date(2026, 8, 1),
    )

    response = client.get(
        "/api/v1/library/shows/watch-next",
    )

    assert response.status_code == 200
    assert response.json() == []


def test_list_watch_next_excludes_caught_up_show(
    client: TestClient,
    db_session: Session,
) -> None:
    """Do not include a Show when all aired Episodes are already watched."""

    local_user = create_local_user(db_session)

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    create_library_entry(
        db_session,
        user=local_user,
        show=show,
        status=LibraryStatus.WATCHING,
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
        tmdb_id=1947647,
        episode_number=1,
        title="Good News About Hell",
        air_date=date(2026, 8, 1),
    )

    create_episode_progress(
        db_session,
        user=local_user,
        episode=episode,
        is_watched=True,
    )

    response = client.get(
        "/api/v1/library/shows/watch-next",
    )

    assert response.status_code == 200
    assert response.json() == []


def test_list_watch_next_excludes_future_episode(
    client: TestClient,
    db_session: Session,
) -> None:
    """Do not expose an Episode that has not aired yet."""

    local_user = create_local_user(db_session)

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    create_library_entry(
        db_session,
        user=local_user,
        show=show,
        status=LibraryStatus.WATCHING,
    )

    season = create_season(
        db_session,
        show=show,
        tmdb_id=134792,
        season_number=2,
        title="Season 2",
    )

    create_episode(
        db_session,
        season=season,
        tmdb_id=1947648,
        episode_number=2,
        title="Future Episode",
        air_date=date(2099, 1, 1),
    )

    response = client.get(
        "/api/v1/library/shows/watch-next",
    )

    assert response.status_code == 200
    assert response.json() == []


def test_list_stale_watching_returns_inactive_show_with_next_episode(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return a Watching Show inactive for at least 60 days."""

    local_user = create_local_user(db_session)

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    create_library_entry(
        db_session,
        user=local_user,
        show=show,
        status=LibraryStatus.WATCHING,
    )

    season = create_season(
        db_session,
        show=show,
        tmdb_id=134792,
        season_number=1,
        title="Season 1",
    )

    last_watched_episode = create_episode(
        db_session,
        season=season,
        tmdb_id=1947647,
        episode_number=1,
        title="Good News About Hell",
        air_date=date(2026, 1, 1),
    )

    next_episode = create_episode(
        db_session,
        season=season,
        tmdb_id=1947648,
        episode_number=2,
        title="Half Loop",
        air_date=date(2026, 1, 8),
    )

    progress = create_episode_progress(
        db_session,
        user=local_user,
        episode=last_watched_episode,
        is_watched=True,
    )

    progress.watched_at = datetime(
        2026,
        5,
        1,
        20,
        0,
        tzinfo=UTC,
    )

    db_session.commit()

    response = client.get(
        "/api/v1/library/shows/stale-watching",
    )

    assert response.status_code == 200

    body = response.json()

    assert len(body) == 1

    item = body[0]

    assert item["library_status"] == "watching"

    assert item["show"]["id"] == str(show.id)
    assert item["show"]["tmdb_id"] == 95396
    assert item["show"]["title"] == "Severance"

    assert item["last_watched"]["id"] == str(
        last_watched_episode.id,
    )
    assert item["last_watched"]["season_number"] == 1
    assert item["last_watched"]["episode_number"] == 1
    assert item["last_watched"]["title"] == "Good News About Hell"
    assert item["last_watched"]["watched_at"].startswith(
        "2026-05-01T20:00:00",
    )

    assert item["next_episode"]["id"] == str(
        next_episode.id,
    )
    assert item["next_episode"]["season_number"] == 1
    assert item["next_episode"]["episode_number"] == 2
    assert item["next_episode"]["title"] == "Half Loop"


def test_list_stale_watching_excludes_recently_watched_show(
    client: TestClient,
    db_session: Session,
) -> None:
    """Do not include a Show whose last activity is recent."""

    local_user = create_local_user(db_session)

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    create_library_entry(
        db_session,
        user=local_user,
        show=show,
        status=LibraryStatus.WATCHING,
    )

    season = create_season(
        db_session,
        show=show,
        tmdb_id=134792,
        season_number=1,
        title="Season 1",
    )

    watched_episode = create_episode(
        db_session,
        season=season,
        tmdb_id=1947647,
        episode_number=1,
        title="Good News About Hell",
        air_date=date(2026, 8, 1),
    )

    create_episode(
        db_session,
        season=season,
        tmdb_id=1947648,
        episode_number=2,
        title="Half Loop",
        air_date=date(2026, 8, 8),
    )

    create_episode_progress(
        db_session,
        user=local_user,
        episode=watched_episode,
        is_watched=True,
    )

    response = client.get(
        "/api/v1/library/shows/stale-watching",
    )

    assert response.status_code == 200
    assert response.json() == []


def test_list_stale_watching_excludes_never_started_show(
    client: TestClient,
    db_session: Session,
) -> None:
    """Do not treat a never-started Show as stale Watching."""

    local_user = create_local_user(db_session)

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    create_library_entry(
        db_session,
        user=local_user,
        show=show,
        status=LibraryStatus.WATCHING,
    )

    season = create_season(
        db_session,
        show=show,
        tmdb_id=134792,
        season_number=1,
        title="Season 1",
    )

    create_episode(
        db_session,
        season=season,
        tmdb_id=1947647,
        episode_number=1,
        title="Good News About Hell",
        air_date=date(2026, 1, 1),
    )

    response = client.get(
        "/api/v1/library/shows/stale-watching",
    )

    assert response.status_code == 200
    assert response.json() == []


def test_list_stale_watching_excludes_caught_up_show(
    client: TestClient,
    db_session: Session,
) -> None:
    """Do not include stale Shows with no aired Episode left to watch."""

    local_user = create_local_user(db_session)

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    create_library_entry(
        db_session,
        user=local_user,
        show=show,
        status=LibraryStatus.WATCHING,
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
        tmdb_id=1947647,
        episode_number=1,
        title="Good News About Hell",
        air_date=date(2026, 1, 1),
    )

    progress = create_episode_progress(
        db_session,
        user=local_user,
        episode=episode,
        is_watched=True,
    )

    progress.watched_at = datetime(
        2026,
        5,
        1,
        tzinfo=UTC,
    )

    db_session.commit()

    response = client.get(
        "/api/v1/library/shows/stale-watching",
    )

    assert response.status_code == 200
    assert response.json() == []


def test_list_stale_watching_isolated_to_current_user(
    client: TestClient,
    db_session: Session,
) -> None:
    """Ignore viewing progress belonging to another user."""

    local_user = create_local_user(db_session)

    other_user = create_user(
        db_session,
        display_name="Other User",
    )

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    create_library_entry(
        db_session,
        user=local_user,
        show=show,
        status=LibraryStatus.WATCHING,
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
        tmdb_id=1947647,
        episode_number=1,
        title="Good News About Hell",
        air_date=date(2026, 1, 1),
    )

    create_episode(
        db_session,
        season=season,
        tmdb_id=1947648,
        episode_number=2,
        title="Half Loop",
        air_date=date(2026, 1, 8),
    )

    progress = create_episode_progress(
        db_session,
        user=other_user,
        episode=first_episode,
        is_watched=True,
    )

    progress.watched_at = datetime(
        2026,
        1,
        1,
        tzinfo=UTC,
    )

    db_session.commit()

    response = client.get(
        "/api/v1/library/shows/stale-watching",
    )

    assert response.status_code == 200

    # The local user has never watched this Show.
    assert response.json() == []


def test_list_watch_history_returns_recently_watched_episodes(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return Episode watch events ordered from newest to oldest."""

    local_user = create_local_user(db_session)

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
        tmdb_id=1947647,
        episode_number=1,
        title="Good News About Hell",
        air_date=date(2026, 8, 1),
    )

    second_episode = create_episode(
        db_session,
        season=season,
        tmdb_id=1947648,
        episode_number=2,
        title="Half Loop",
        air_date=date(2026, 8, 8),
    )

    first_watched_at = datetime(
        2026,
        8,
        10,
        20,
        tzinfo=UTC,
    )

    second_watched_at = datetime(
        2026,
        8,
        12,
        21,
        tzinfo=UTC,
    )

    first_event = create_episode_watch_event(
        db_session,
        user=local_user,
        episode=first_episode,
        watched_at=first_watched_at,
    )

    second_event = create_episode_watch_event(
        db_session,
        user=local_user,
        episode=second_episode,
        watched_at=second_watched_at,
    )

    response = client.get(
        "/api/v1/library/shows/watch-history",
    )

    assert response.status_code == 200

    body = response.json()

    assert body["has_more"] is False
    assert body["next_cursor"] is None

    assert len(body["items"]) == 2

    newest = body["items"][0]

    assert newest["event_id"] == str(second_event.id)
    assert newest["show"]["id"] == str(show.id)
    assert newest["show"]["tmdb_id"] == 95396
    assert newest["show"]["title"] == "Severance"

    assert newest["episode"]["id"] == str(second_episode.id)
    assert newest["episode"]["tmdb_id"] == 1947648
    assert newest["episode"]["season_number"] == 1
    assert newest["episode"]["episode_number"] == 2
    assert newest["episode"]["title"] == "Half Loop"
    assert newest["episode"]["watch_count"] == 1

    assert (
        as_utc(
            datetime.fromisoformat(
                newest["episode"]["watched_at"],
            )
        )
        == second_watched_at
    )

    oldest = body["items"][1]

    assert oldest["event_id"] == str(first_event.id)
    assert oldest["episode"]["id"] == str(first_episode.id)
    assert oldest["episode"]["episode_number"] == 1
    assert oldest["episode"]["watch_count"] == 1

    assert (
        as_utc(
            datetime.fromisoformat(
                oldest["episode"]["watched_at"],
            )
        )
        == first_watched_at
    )


def test_list_watch_history_supports_cursor_pagination(
    client: TestClient,
    db_session: Session,
) -> None:
    """Load older Watch History events using the returned opaque cursor."""

    local_user = create_local_user(db_session)

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

    episodes = [
        create_episode(
            db_session,
            season=season,
            tmdb_id=3000 + index,
            episode_number=index,
            title=f"Episode {index}",
            air_date=date(2026, 8, index),
        )
        for index in range(1, 6)
    ]

    events: list[EpisodeWatchEvent] = []

    for index, episode in enumerate(
        episodes,
        start=1,
    ):
        event = create_episode_watch_event(
            db_session,
            user=local_user,
            episode=episode,
            watched_at=datetime(
                2026,
                8,
                index,
                20,
                tzinfo=UTC,
            ),
        )

        events.append(event)

    first_response = client.get(
        "/api/v1/library/shows/watch-history",
        params={
            "limit": 2,
        },
    )

    assert first_response.status_code == 200

    first_page = first_response.json()

    assert len(first_page["items"]) == 2
    assert first_page["has_more"] is True
    assert first_page["next_cursor"] is not None

    assert first_page["items"][0]["event_id"] == str(events[4].id)
    assert first_page["items"][0]["episode"]["episode_number"] == 5

    assert first_page["items"][1]["event_id"] == str(events[3].id)
    assert first_page["items"][1]["episode"]["episode_number"] == 4

    second_response = client.get(
        "/api/v1/library/shows/watch-history",
        params={
            "limit": 2,
            "cursor": first_page["next_cursor"],
        },
    )

    assert second_response.status_code == 200

    second_page = second_response.json()

    assert len(second_page["items"]) == 2
    assert second_page["has_more"] is True
    assert second_page["next_cursor"] is not None

    assert second_page["items"][0]["event_id"] == str(events[2].id)
    assert second_page["items"][0]["episode"]["episode_number"] == 3

    assert second_page["items"][1]["event_id"] == str(events[1].id)
    assert second_page["items"][1]["episode"]["episode_number"] == 2

    third_response = client.get(
        "/api/v1/library/shows/watch-history",
        params={
            "limit": 2,
            "cursor": second_page["next_cursor"],
        },
    )

    assert third_response.status_code == 200

    third_page = third_response.json()

    assert len(third_page["items"]) == 1
    assert third_page["has_more"] is False
    assert third_page["next_cursor"] is None

    assert third_page["items"][0]["event_id"] == str(events[0].id)
    assert third_page["items"][0]["episode"]["episode_number"] == 1


def test_list_watch_history_returns_400_for_invalid_cursor(
    client: TestClient,
    db_session: Session,
) -> None:
    """Reject malformed Watch History cursors safely."""

    create_local_user(db_session)

    response = client.get(
        "/api/v1/library/shows/watch-history",
        params={
            "cursor": "definitely-not-valid",
        },
    )

    assert response.status_code == 400

    assert response.json() == {
        "error": {
            "code": "invalid_watch_history_cursor",
            "message": "Invalid Watch History cursor.",
        }
    }


def test_list_watch_history_rejects_invalid_limit(
    client: TestClient,
    db_session: Session,
) -> None:
    """Validate the supported Watch History page size."""

    create_local_user(db_session)

    response = client.get(
        "/api/v1/library/shows/watch-history",
        params={
            "limit": 0,
        },
    )

    assert response.status_code == 422


def test_list_library_shows_includes_first_available_episode_for_planning_show(
    client: TestClient,
    db_session: Session,
) -> None:
    """Expose the first aired regular Episode for a Planning Show."""

    local_user = create_local_user(db_session)

    show = create_show(
        db_session,
        tmdb_id=1396,
        title="Breaking Bad",
    )

    create_library_entry(
        db_session,
        user=local_user,
        show=show,
        status=LibraryStatus.PLANNING,
    )

    season = create_season(
        db_session,
        show=show,
        tmdb_id=3572,
        season_number=1,
        title="Season 1",
    )

    first_episode = create_episode(
        db_session,
        season=season,
        tmdb_id=62085,
        episode_number=1,
        title="Pilot",
        air_date=date(2008, 1, 20),
    )

    create_episode(
        db_session,
        season=season,
        tmdb_id=62086,
        episode_number=2,
        title="Cat's in the Bag...",
        air_date=date(2008, 1, 27),
    )

    response = client.get(
        "/api/v1/library/shows",
    )

    assert response.status_code == 200

    body = response.json()

    assert len(body) == 1

    episode = body[0]["first_available_episode"]

    assert episode is not None
    assert episode["id"] == str(first_episode.id)
    assert episode["tmdb_id"] == 62085
    assert episode["season_number"] == 1
    assert episode["episode_number"] == 1
    assert episode["title"] == "Pilot"


def test_list_library_shows_returns_null_first_episode_when_none_has_aired(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return no first available Episode when a Planning Show has not aired."""

    local_user = create_local_user(db_session)

    show = create_show(
        db_session,
        tmdb_id=123456,
        title="Future Show",
    )

    create_library_entry(
        db_session,
        user=local_user,
        show=show,
        status=LibraryStatus.PLANNING,
    )

    season = create_season(
        db_session,
        show=show,
        tmdb_id=999001,
        season_number=1,
        title="Season 1",
    )

    create_episode(
        db_session,
        season=season,
        tmdb_id=999002,
        episode_number=1,
        title="Premiere",
        air_date=date(2099, 1, 1),
    )

    response = client.get(
        "/api/v1/library/shows",
    )

    assert response.status_code == 200

    body = response.json()

    assert len(body) == 1
    assert body[0]["first_available_episode"] is None


def test_list_havent_started_returns_planning_show_with_first_episode(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return Planning Shows with their first aired regular Episode."""

    local_user = create_local_user(db_session)

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    create_library_entry(
        db_session,
        user=local_user,
        show=show,
        status=LibraryStatus.PLANNING,
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
        tmdb_id=1947647,
        episode_number=1,
        title="Good News About Hell",
        air_date=date(2022, 2, 18),
    )

    create_episode(
        db_session,
        season=season,
        tmdb_id=1947648,
        episode_number=2,
        title="Half Loop",
        air_date=date(2022, 2, 25),
    )

    response = client.get(
        "/api/v1/library/shows/havent-started",
    )

    assert response.status_code == 200

    body = response.json()

    assert len(body) == 1

    item = body[0]

    assert item["library_status"] == "planning"

    assert item["show"]["id"] == str(show.id)
    assert item["show"]["tmdb_id"] == 95396
    assert item["show"]["title"] == "Severance"

    assert item["first_episode"]["id"] == str(first_episode.id)
    assert item["first_episode"]["tmdb_id"] == 1947647
    assert item["first_episode"]["season_number"] == 1
    assert item["first_episode"]["episode_number"] == 1
    assert item["first_episode"]["title"] == "Good News About Hell"
    assert item["first_episode"]["air_date"] == "2022-02-18"


def test_list_upcoming_returns_future_episodes_for_watching_and_planning_shows(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return future regular Episodes for eligible Library Shows."""

    local_user = create_local_user(db_session)

    watching_show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    planning_show = create_show(
        db_session,
        tmdb_id=100088,
        title="The Last of Us",
    )

    create_library_entry(
        db_session,
        user=local_user,
        show=watching_show,
        status=LibraryStatus.WATCHING,
    )

    create_library_entry(
        db_session,
        user=local_user,
        show=planning_show,
        status=LibraryStatus.PLANNING,
    )

    watching_season = create_season(
        db_session,
        show=watching_show,
        tmdb_id=134792,
        season_number=2,
        title="Season 2",
    )

    planning_season = create_season(
        db_session,
        show=planning_show,
        tmdb_id=200001,
        season_number=3,
        title="Season 3",
    )

    watching_episode = create_episode(
        db_session,
        season=watching_season,
        tmdb_id=300001,
        episode_number=3,
        title="Severance Future Episode",
        air_date=date(2026, 9, 20),
    )

    planning_episode = create_episode(
        db_session,
        season=planning_season,
        tmdb_id=300002,
        episode_number=1,
        title="The Last of Us Future Episode",
        air_date=date(2026, 9, 21),
    )

    response = client.get(
        "/api/v1/library/shows/upcoming",
    )

    assert response.status_code == 200

    body = response.json()

    assert len(body) == 2

    assert body[0]["library_status"] == "watching"
    assert body[0]["show"]["id"] == str(watching_show.id)
    assert body[0]["show"]["title"] == "Severance"

    assert body[0]["episode"]["id"] == str(watching_episode.id)
    assert body[0]["episode"]["season_number"] == 2
    assert body[0]["episode"]["episode_number"] == 3
    assert body[0]["episode"]["title"] == "Severance Future Episode"
    assert body[0]["episode"]["air_date"] == "2026-09-20"

    assert body[1]["library_status"] == "planning"
    assert body[1]["show"]["id"] == str(planning_show.id)
    assert body[1]["show"]["title"] == "The Last of Us"

    assert body[1]["episode"]["id"] == str(planning_episode.id)
    assert body[1]["episode"]["season_number"] == 3
    assert body[1]["episode"]["episode_number"] == 1
    assert body[1]["episode"]["title"] == "The Last of Us Future Episode"
    assert body[1]["episode"]["air_date"] == "2026-09-21"


def test_list_upcoming_returns_multiple_future_episodes_for_same_show(
    client: TestClient,
    db_session: Session,
) -> None:
    """Upcoming is a timeline and may contain multiple Episodes per Show."""

    local_user = create_local_user(db_session)

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    create_library_entry(
        db_session,
        user=local_user,
        show=show,
        status=LibraryStatus.WATCHING,
    )

    season = create_season(
        db_session,
        show=show,
        tmdb_id=134792,
        season_number=2,
        title="Season 2",
    )

    first_episode = create_episode(
        db_session,
        season=season,
        tmdb_id=300001,
        episode_number=1,
        title="Episode One",
        air_date=date(2026, 9, 20),
    )

    second_episode = create_episode(
        db_session,
        season=season,
        tmdb_id=300002,
        episode_number=2,
        title="Episode Two",
        air_date=date(2026, 9, 27),
    )

    response = client.get(
        "/api/v1/library/shows/upcoming",
    )

    assert response.status_code == 200

    body = response.json()

    assert [item["episode"]["id"] for item in body] == [
        str(first_episode.id),
        str(second_episode.id),
    ]


def test_list_upcoming_excludes_completed_dropped_and_paused_shows(
    client: TestClient,
    db_session: Session,
) -> None:
    """Do not include future Episodes from ineligible Library statuses."""

    local_user = create_local_user(db_session)

    for index, library_status in enumerate(
        (
            LibraryStatus.COMPLETED,
            LibraryStatus.DROPPED,
            LibraryStatus.PAUSED,
        )
    ):
        show = create_show(
            db_session,
            tmdb_id=110000 + index,
            title=f"Excluded {library_status.value}",
        )

        create_library_entry(
            db_session,
            user=local_user,
            show=show,
            status=library_status,
        )

        season = create_season(
            db_session,
            show=show,
            tmdb_id=120000 + index,
            season_number=1,
            title="Season 1",
        )

        create_episode(
            db_session,
            season=season,
            tmdb_id=130000 + index,
            episode_number=1,
            title="Future Episode",
            air_date=date(2026, 8, 20),
        )

    response = client.get(
        "/api/v1/library/shows/upcoming",
    )

    assert response.status_code == 200
    assert response.json() == []


def test_list_upcoming_excludes_unknown_dates_and_shows_without_future_episodes(
    client: TestClient,
    db_session: Session,
) -> None:
    """Unknown or absent future Episodes must not create timeline items."""

    local_user = create_local_user(db_session)

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    create_library_entry(
        db_session,
        user=local_user,
        show=show,
        status=LibraryStatus.WATCHING,
    )

    season = create_season(
        db_session,
        show=show,
        tmdb_id=134792,
        season_number=2,
        title="Season 2",
    )

    create_episode(
        db_session,
        season=season,
        tmdb_id=300001,
        episode_number=1,
        title="Unknown Date",
        air_date=None,
    )

    create_episode(
        db_session,
        season=season,
        tmdb_id=300002,
        episode_number=2,
        title="Already Aired",
        air_date=date(2026, 8, 1),
    )

    response = client.get(
        "/api/v1/library/shows/upcoming",
    )

    assert response.status_code == 200
    assert response.json() == []


def test_list_upcoming_supports_past_and_future_date_range(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return dated Episodes on both sides of Today when explicitly requested."""

    local_user = create_local_user(db_session)

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    create_library_entry(
        db_session,
        user=local_user,
        show=show,
        status=LibraryStatus.WATCHING,
    )

    season = create_season(
        db_session,
        show=show,
        tmdb_id=134792,
        season_number=2,
        title="Season 2",
    )

    previous_episode = create_episode(
        db_session,
        season=season,
        tmdb_id=300001,
        episode_number=1,
        title="Previous Episode",
        air_date=date(2026, 8, 14),
    )

    today_episode = create_episode(
        db_session,
        season=season,
        tmdb_id=300002,
        episode_number=2,
        title="Today Episode",
        air_date=date(2026, 8, 15),
    )

    future_episode = create_episode(
        db_session,
        season=season,
        tmdb_id=300003,
        episode_number=3,
        title="Future Episode",
        air_date=date(2026, 8, 16),
    )

    response = client.get(
        "/api/v1/library/shows/upcoming",
        params={
            "from_date": "2026-08-14",
            "to_date": "2026-08-16",
        },
    )

    assert response.status_code == 200

    body = response.json()

    assert [item["episode"]["id"] for item in body] == [
        str(previous_episode.id),
        str(today_episode.id),
        str(future_episode.id),
    ]


def test_list_upcoming_date_range_is_inclusive(
    client: TestClient,
    db_session: Session,
) -> None:
    """Include Episodes airing exactly on both requested boundaries."""

    local_user = create_local_user(db_session)

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    create_library_entry(
        db_session,
        user=local_user,
        show=show,
        status=LibraryStatus.WATCHING,
    )

    season = create_season(
        db_session,
        show=show,
        tmdb_id=134792,
        season_number=2,
        title="Season 2",
    )

    first = create_episode(
        db_session,
        season=season,
        tmdb_id=300001,
        episode_number=1,
        title="First Boundary",
        air_date=date(2026, 8, 10),
    )

    create_episode(
        db_session,
        season=season,
        tmdb_id=300002,
        episode_number=2,
        title="Outside",
        air_date=date(2026, 8, 11),
    )

    last = create_episode(
        db_session,
        season=season,
        tmdb_id=300003,
        episode_number=3,
        title="Last Boundary",
        air_date=date(2026, 8, 12),
    )

    response = client.get(
        "/api/v1/library/shows/upcoming",
        params={
            "from_date": "2026-08-10",
            "to_date": "2026-08-12",
        },
    )

    assert response.status_code == 200

    body = response.json()

    assert body[0]["episode"]["id"] == str(first.id)
    assert body[-1]["episode"]["id"] == str(last.id)
    assert len(body) == 3


def test_list_upcoming_supports_past_only_range(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return previously aired Episodes when requesting a historical range."""

    local_user = create_local_user(db_session)

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    create_library_entry(
        db_session,
        user=local_user,
        show=show,
        status=LibraryStatus.WATCHING,
    )

    season = create_season(
        db_session,
        show=show,
        tmdb_id=134792,
        season_number=2,
        title="Season 2",
    )

    included = create_episode(
        db_session,
        season=season,
        tmdb_id=300001,
        episode_number=1,
        title="Historical Episode",
        air_date=date(2026, 8, 5),
    )

    create_episode(
        db_session,
        season=season,
        tmdb_id=300002,
        episode_number=2,
        title="Too New",
        air_date=date(2026, 8, 12),
    )

    response = client.get(
        "/api/v1/library/shows/upcoming",
        params={
            "from_date": "2026-08-01",
            "to_date": "2026-08-10",
        },
    )

    assert response.status_code == 200

    body = response.json()

    assert len(body) == 1
    assert body[0]["episode"]["id"] == str(included.id)


def test_list_upcoming_rejects_invalid_date_range(
    client: TestClient,
    db_session: Session,
) -> None:
    """Reject an Upcoming range whose start is after its end."""

    create_local_user(db_session)

    response = client.get(
        "/api/v1/library/shows/upcoming",
        params={
            "from_date": "2026-08-20",
            "to_date": "2026-08-10",
        },
    )

    assert response.status_code == 400

    assert response.json() == {
        "error": {
            "code": "invalid_upcoming_date_range",
            "message": "Upcoming date range is invalid.",
        }
    }


def test_list_upcoming_uses_today_when_only_to_date_is_provided(
    client: TestClient,
    db_session: Session,
) -> None:
    """Keep Today as the lower boundary when only to_date is provided."""

    today = date.today()

    local_user = create_local_user(db_session)

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    create_library_entry(
        db_session,
        user=local_user,
        show=show,
        status=LibraryStatus.WATCHING,
    )

    season = create_season(
        db_session,
        show=show,
        tmdb_id=134792,
        season_number=2,
        title="Season 2",
    )

    create_episode(
        db_session,
        season=season,
        tmdb_id=300001,
        episode_number=1,
        title="Past Episode",
        air_date=today - timedelta(days=1),
    )

    today_episode = create_episode(
        db_session,
        season=season,
        tmdb_id=300002,
        episode_number=2,
        title="Today Episode",
        air_date=today,
    )

    response = client.get(
        "/api/v1/library/shows/upcoming",
        params={
            "to_date": today.isoformat(),
        },
    )

    assert response.status_code == 200

    body = response.json()

    assert len(body) == 1
    assert body[0]["episode"]["id"] == str(today_episode.id)


def test_list_library_movies_returns_current_users_movies(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return Movies belonging to the current user's library."""

    local_user = create_local_user(db_session)

    movie = create_movie(
        db_session,
        tmdb_id=438631,
        title="Dune",
    )

    entry = create_movie_library_entry(
        db_session,
        user=local_user,
        movie=movie,
    )

    response = client.get(
        "/api/v1/library/movies",
    )

    assert response.status_code == 200

    body = response.json()

    assert len(body) == 1

    assert body[0]["id"] == str(entry.id)
    assert body[0]["status"] == "planning"
    assert body[0]["rating"] is None
    assert body[0]["started_at"] is None
    assert body[0]["completed_at"] is None

    assert body[0]["movie"]["id"] == str(movie.id)
    assert body[0]["movie"]["tmdb_id"] == 438631
    assert body[0]["movie"]["title"] == "Dune"
    assert body[0]["movie"]["original_title"] == "Dune"
    assert body[0]["movie"]["status"] == "Released"
    assert body[0]["movie"]["vote_average"] == 8.0


def test_list_library_movies_does_not_return_shows(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return only Movie entries from the Movie library endpoint."""

    local_user = create_local_user(db_session)

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    create_library_entry(
        db_session,
        user=local_user,
        show=show,
    )

    movie = create_movie(
        db_session,
        tmdb_id=438631,
        title="Dune",
    )

    create_movie_library_entry(
        db_session,
        user=local_user,
        movie=movie,
    )

    response = client.get(
        "/api/v1/library/movies",
    )

    assert response.status_code == 200

    body = response.json()

    assert len(body) == 1
    assert body[0]["movie"]["id"] == str(movie.id)
    assert body[0]["movie"]["title"] == "Dune"


def test_list_library_movies_filters_planning_movies(
    client: TestClient,
    db_session: Session,
) -> None:
    """Filter Movie library entries by Planning status."""

    local_user = create_local_user(db_session)

    planning_movie = create_movie(
        db_session,
        tmdb_id=438631,
        title="Dune",
    )

    completed_movie = create_movie(
        db_session,
        tmdb_id=693134,
        title="Dune: Part Two",
    )

    create_movie_library_entry(
        db_session,
        user=local_user,
        movie=planning_movie,
        status=LibraryStatus.PLANNING,
    )

    create_movie_library_entry(
        db_session,
        user=local_user,
        movie=completed_movie,
        status=LibraryStatus.COMPLETED,
    )

    response = client.get(
        "/api/v1/library/movies",
        params={
            "status": "planning",
        },
    )

    assert response.status_code == 200

    body = response.json()

    assert len(body) == 1
    assert body[0]["status"] == "planning"
    assert body[0]["movie"]["id"] == str(planning_movie.id)
    assert body[0]["movie"]["title"] == "Dune"


def test_list_library_movies_filters_completed_movies(
    client: TestClient,
    db_session: Session,
) -> None:
    """Filter Movie library entries by Completed status."""

    local_user = create_local_user(db_session)

    planning_movie = create_movie(
        db_session,
        tmdb_id=438631,
        title="Dune",
    )

    completed_movie = create_movie(
        db_session,
        tmdb_id=693134,
        title="Dune: Part Two",
    )

    create_movie_library_entry(
        db_session,
        user=local_user,
        movie=planning_movie,
        status=LibraryStatus.PLANNING,
    )

    completed_entry = create_movie_library_entry(
        db_session,
        user=local_user,
        movie=completed_movie,
        status=LibraryStatus.COMPLETED,
    )

    response = client.get(
        "/api/v1/library/movies",
        params={
            "status": "completed",
        },
    )

    assert response.status_code == 200

    body = response.json()

    assert len(body) == 1
    assert body[0]["id"] == str(completed_entry.id)
    assert body[0]["status"] == "completed"
    assert body[0]["movie"]["id"] == str(completed_movie.id)


def test_list_library_movies_only_returns_current_users_movies(
    client: TestClient,
    db_session: Session,
) -> None:
    """Do not expose another user's Movie library entries."""

    local_user = create_local_user(db_session)

    other_user = User(
        display_name="Other User",
    )

    db_session.add(other_user)
    db_session.commit()
    db_session.refresh(other_user)

    local_movie = create_movie(
        db_session,
        tmdb_id=438631,
        title="Dune",
    )

    other_movie = create_movie(
        db_session,
        tmdb_id=693134,
        title="Dune: Part Two",
    )

    create_movie_library_entry(
        db_session,
        user=local_user,
        movie=local_movie,
    )

    create_movie_library_entry(
        db_session,
        user=other_user,
        movie=other_movie,
    )

    response = client.get(
        "/api/v1/library/movies",
    )

    assert response.status_code == 200

    body = response.json()

    assert len(body) == 1
    assert body[0]["movie"]["id"] == str(local_movie.id)


def test_list_library_movies_returns_empty_list_when_library_has_no_movies(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return an empty list when the user has no Movies."""

    create_local_user(db_session)

    response = client.get(
        "/api/v1/library/movies",
    )

    assert response.status_code == 200
    assert response.json() == []


def test_record_first_movie_watch_event(
    client: TestClient,
    db_session: Session,
) -> None:
    """Record the first real viewing of a Movie."""

    local_user = create_local_user(db_session)

    movie = create_movie(
        db_session,
        tmdb_id=438631,
        title="Dune",
    )

    entry = create_movie_library_entry(
        db_session,
        user=local_user,
        movie=movie,
        status=LibraryStatus.PLANNING,
    )

    response = client.post(
        f"/api/v1/library/movies/{movie.id}/watch-events",
    )

    assert response.status_code == 201

    body = response.json()

    assert body["movie_id"] == str(movie.id)
    assert body["watched_at"] is not None

    events = (
        db_session.query(MovieWatchEvent)
        .filter(
            MovieWatchEvent.user_id == local_user.id,
            MovieWatchEvent.movie_id == movie.id,
        )
        .all()
    )

    assert len(events) == 1

    db_session.refresh(entry)

    assert entry.status == LibraryStatus.COMPLETED
    assert entry.completed_at is not None


def test_record_movie_rewatch_creates_another_event(
    client: TestClient,
    db_session: Session,
) -> None:
    """Record a Rewatch without moving the original completion timestamp."""

    local_user = create_local_user(db_session)

    movie = create_movie(
        db_session,
        tmdb_id=438631,
        title="Dune",
    )

    entry = create_movie_library_entry(
        db_session,
        user=local_user,
        movie=movie,
        status=LibraryStatus.PLANNING,
    )

    first_response = client.post(
        f"/api/v1/library/movies/{movie.id}/watch-events",
    )

    assert first_response.status_code == 201

    db_session.refresh(entry)

    original_completed_at = as_utc(entry.completed_at)

    second_response = client.post(
        f"/api/v1/library/movies/{movie.id}/watch-events",
    )

    assert second_response.status_code == 201

    events = (
        db_session.query(MovieWatchEvent)
        .filter(
            MovieWatchEvent.user_id == local_user.id,
            MovieWatchEvent.movie_id == movie.id,
        )
        .all()
    )

    assert len(events) == 2

    db_session.refresh(entry)

    assert entry.status == LibraryStatus.COMPLETED

    assert (
        as_utc(
            entry.completed_at,
        )
        == original_completed_at
    )


def test_record_movie_watch_event_returns_404_when_movie_does_not_exist(
    client: TestClient,
    db_session: Session,
) -> None:
    """Reject viewing history for an unknown Movie."""

    create_local_user(db_session)

    response = client.post(
        f"/api/v1/library/movies/{uuid4()}/watch-events",
    )

    assert response.status_code == 404

    assert response.json() == {
        "error": {
            "code": "movie_not_available_for_watching",
            "message": "The requested movie cannot be watched.",
        }
    }


def test_record_movie_watch_event_returns_404_when_movie_is_not_in_library(
    client: TestClient,
    db_session: Session,
) -> None:
    """A Movie must belong to the current user's Library before watching."""

    create_local_user(db_session)

    movie = create_movie(
        db_session,
        tmdb_id=438631,
        title="Dune",
    )

    response = client.post(
        f"/api/v1/library/movies/{movie.id}/watch-events",
    )

    assert response.status_code == 404

    assert response.json() == {
        "error": {
            "code": "movie_not_available_for_watching",
            "message": "The requested movie cannot be watched.",
        }
    }


def test_list_movie_watch_events_returns_newest_first(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return all Movie viewings from newest to oldest."""

    local_user = create_local_user(db_session)

    movie = create_movie(
        db_session,
        tmdb_id=438631,
        title="Dune",
    )

    create_movie_library_entry(
        db_session,
        user=local_user,
        movie=movie,
        status=LibraryStatus.COMPLETED,
    )

    older_event = create_movie_watch_event(
        db_session,
        user=local_user,
        movie=movie,
        watched_at=datetime(
            2026,
            7,
            20,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    newer_event = create_movie_watch_event(
        db_session,
        user=local_user,
        movie=movie,
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
        f"/api/v1/library/movies/{movie.id}/watch-events",
    )

    assert response.status_code == 200

    body = response.json()

    assert len(body) == 2

    assert body[0]["id"] == str(newer_event.id)
    assert body[1]["id"] == str(older_event.id)

    assert body[0]["movie_id"] == str(movie.id)
    assert body[1]["movie_id"] == str(movie.id)


def test_list_movie_watch_events_is_isolated_to_current_user(
    client: TestClient,
    db_session: Session,
) -> None:
    """Do not expose another user's Movie viewing history."""

    local_user = create_local_user(db_session)

    other_user = create_user(
        db_session,
        display_name="Other User",
    )

    movie = create_movie(
        db_session,
        tmdb_id=438631,
        title="Dune",
    )

    create_movie_library_entry(
        db_session,
        user=local_user,
        movie=movie,
    )

    local_event = create_movie_watch_event(
        db_session,
        user=local_user,
        movie=movie,
        watched_at=datetime(
            2026,
            8,
            14,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    create_movie_watch_event(
        db_session,
        user=other_user,
        movie=movie,
        watched_at=datetime(
            2026,
            8,
            14,
            21,
            0,
            tzinfo=UTC,
        ),
    )

    response = client.get(
        f"/api/v1/library/movies/{movie.id}/watch-events",
    )

    assert response.status_code == 200

    body = response.json()

    assert len(body) == 1
    assert body[0]["id"] == str(local_event.id)


def test_delete_movie_watch_event_keeps_movie_completed_when_history_remains(
    client: TestClient,
    db_session: Session,
) -> None:
    """Deleting one Rewatch preserves Completed while another viewing exists."""

    local_user = create_local_user(db_session)

    movie = create_movie(
        db_session,
        tmdb_id=438631,
        title="Dune",
    )

    entry = create_movie_library_entry(
        db_session,
        user=local_user,
        movie=movie,
        status=LibraryStatus.COMPLETED,
    )

    older_event = create_movie_watch_event(
        db_session,
        user=local_user,
        movie=movie,
        watched_at=datetime(
            2026,
            7,
            20,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    newer_event = create_movie_watch_event(
        db_session,
        user=local_user,
        movie=movie,
        watched_at=datetime(
            2026,
            8,
            14,
            21,
            30,
            tzinfo=UTC,
        ),
    )

    entry.completed_at = older_event.watched_at
    db_session.commit()

    response = client.delete(
        f"/api/v1/library/movies/{movie.id}/watch-events/{newer_event.id}",
    )

    assert response.status_code == 204
    assert response.content == b""

    db_session.refresh(entry)

    assert entry.status == LibraryStatus.COMPLETED

    assert as_utc(
        entry.completed_at,
    ) == as_utc(
        older_event.watched_at,
    )

    remaining_events = (
        db_session.query(MovieWatchEvent)
        .filter(
            MovieWatchEvent.user_id == local_user.id,
            MovieWatchEvent.movie_id == movie.id,
        )
        .all()
    )

    assert len(remaining_events) == 1
    assert remaining_events[0].id == older_event.id


def test_delete_original_movie_watch_event_moves_completed_at(
    client: TestClient,
    db_session: Session,
) -> None:
    """Deleting the first viewing moves completion to the oldest remaining event."""

    local_user = create_local_user(db_session)

    movie = create_movie(
        db_session,
        tmdb_id=438631,
        title="Dune",
    )

    entry = create_movie_library_entry(
        db_session,
        user=local_user,
        movie=movie,
        status=LibraryStatus.COMPLETED,
    )

    original_event = create_movie_watch_event(
        db_session,
        user=local_user,
        movie=movie,
        watched_at=datetime(
            2026,
            7,
            1,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    remaining_event = create_movie_watch_event(
        db_session,
        user=local_user,
        movie=movie,
        watched_at=datetime(
            2026,
            8,
            14,
            21,
            30,
            tzinfo=UTC,
        ),
    )

    entry.completed_at = original_event.watched_at
    db_session.commit()

    response = client.delete(
        f"/api/v1/library/movies/{movie.id}/watch-events/{original_event.id}",
    )

    assert response.status_code == 204

    db_session.refresh(entry)

    assert entry.status == LibraryStatus.COMPLETED

    assert as_utc(
        entry.completed_at,
    ) == as_utc(
        remaining_event.watched_at,
    )


def test_delete_last_movie_watch_event_returns_movie_to_watchlist(
    client: TestClient,
    db_session: Session,
) -> None:
    """Deleting the final viewing makes the Movie unwatched again."""

    local_user = create_local_user(db_session)

    movie = create_movie(
        db_session,
        tmdb_id=438631,
        title="Dune",
    )

    entry = create_movie_library_entry(
        db_session,
        user=local_user,
        movie=movie,
        status=LibraryStatus.COMPLETED,
    )

    event = create_movie_watch_event(
        db_session,
        user=local_user,
        movie=movie,
        watched_at=datetime(
            2026,
            8,
            14,
            21,
            30,
            tzinfo=UTC,
        ),
    )

    entry.completed_at = event.watched_at
    db_session.commit()

    response = client.delete(
        f"/api/v1/library/movies/{movie.id}/watch-events/{event.id}",
    )

    assert response.status_code == 204

    db_session.refresh(entry)

    assert entry.status == LibraryStatus.PLANNING
    assert entry.completed_at is None

    remaining_events = (
        db_session.query(MovieWatchEvent)
        .filter(
            MovieWatchEvent.user_id == local_user.id,
            MovieWatchEvent.movie_id == movie.id,
        )
        .all()
    )

    assert remaining_events == []


def test_delete_movie_watch_event_returns_404_for_unknown_event(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return 404 when a Movie viewing event cannot be found."""

    local_user = create_local_user(db_session)

    movie = create_movie(
        db_session,
        tmdb_id=438631,
        title="Dune",
    )

    create_movie_library_entry(
        db_session,
        user=local_user,
        movie=movie,
    )

    response = client.delete(
        f"/api/v1/library/movies/{movie.id}/watch-events/{uuid4()}",
    )

    assert response.status_code == 404

    assert response.json() == {
        "error": {
            "code": "movie_watch_event_not_found",
            "message": "Movie watch event not found.",
        }
    }


def test_delete_movie_watch_event_cannot_delete_another_users_event(
    client: TestClient,
    db_session: Session,
) -> None:
    """Do not allow a user to delete another user's Movie watch event."""

    local_user = create_local_user(
        db_session,
    )

    other_user = User(
        username="other-user",
        display_name="Other User",
        is_active=True,
    )

    db_session.add(other_user)
    db_session.commit()
    db_session.refresh(other_user)

    movie = create_movie(
        db_session,
        tmdb_id=438631,
        title="Dune",
    )

    create_movie_library_entry(
        db_session,
        user=local_user,
        movie=movie,
    )

    create_movie_library_entry(
        db_session,
        user=other_user,
        movie=movie,
    )

    event = MovieWatchEvent(
        user_id=other_user.id,
        movie_id=movie.id,
        watched_at=datetime(
            2026,
            8,
            14,
            21,
            0,
            tzinfo=UTC,
        ),
    )

    db_session.add(event)
    db_session.commit()
    db_session.refresh(event)

    response = client.delete(
        f"/api/v1/library/movies/{movie.id}/watch-events/{event.id}",
    )

    assert response.status_code == 404

    assert response.json() == {
        "error": {
            "code": "movie_watch_event_not_found",
            "message": "Movie watch event not found.",
        }
    }

    stored_event = db_session.get(
        MovieWatchEvent,
        event.id,
    )

    assert stored_event is not None
    assert stored_event.user_id == other_user.id


def test_delete_all_movie_watch_events_returns_movie_to_watchlist(
    client: TestClient,
    db_session: Session,
) -> None:
    """Delete all historical Movie viewings."""

    local_user = create_local_user(db_session)

    movie = create_movie(
        db_session,
        tmdb_id=438631,
        title="Dune",
    )

    entry = create_movie_library_entry(
        db_session,
        user=local_user,
        movie=movie,
        status=LibraryStatus.COMPLETED,
    )

    create_movie_watch_event(
        db_session,
        user=local_user,
        movie=movie,
        watched_at=datetime(
            2026,
            7,
            20,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    create_movie_watch_event(
        db_session,
        user=local_user,
        movie=movie,
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
        f"/api/v1/library/movies/{movie.id}/watch-events",
    )

    assert response.status_code == 204
    assert response.content == b""

    db_session.refresh(entry)

    assert entry.status == LibraryStatus.PLANNING
    assert entry.completed_at is None

    events = (
        db_session.query(MovieWatchEvent)
        .filter(
            MovieWatchEvent.user_id == local_user.id,
            MovieWatchEvent.movie_id == movie.id,
        )
        .all()
    )

    assert events == []


def test_delete_all_movie_watch_events_is_idempotent(
    client: TestClient,
    db_session: Session,
) -> None:
    """Deleting an already empty Movie history still succeeds."""

    local_user = create_local_user(db_session)

    movie = create_movie(
        db_session,
        tmdb_id=438631,
        title="Dune",
    )

    entry = create_movie_library_entry(
        db_session,
        user=local_user,
        movie=movie,
        status=LibraryStatus.PLANNING,
    )

    response = client.delete(
        f"/api/v1/library/movies/{movie.id}/watch-events",
    )

    assert response.status_code == 204

    db_session.refresh(entry)

    assert entry.status == LibraryStatus.PLANNING
    assert entry.completed_at is None


def test_list_missed_recently_returns_home_collection(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return recently missed Episodes from actively Watching Shows."""

    local_user = create_local_user(db_session)

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    create_library_entry(
        db_session,
        user=local_user,
        show=show,
        status=LibraryStatus.WATCHING,
    )

    season = create_season(
        db_session,
        show=show,
        tmdb_id=134792,
        season_number=2,
        title="Season 2",
    )

    episode = create_episode(
        db_session,
        season=season,
        tmdb_id=300001,
        episode_number=3,
        title="Who Is Alive?",
        air_date=date.today() - timedelta(days=1),
    )

    response = client.get(
        "/api/v1/library/shows/missed-recently",
    )

    assert response.status_code == 200

    body = response.json()

    assert len(body) == 1

    item = body[0]

    assert item["library_status"] == "watching"

    assert item["show"]["id"] == str(show.id)
    assert item["show"]["tmdb_id"] == 95396
    assert item["show"]["title"] == "Severance"

    assert item["episode"]["id"] == str(episode.id)
    assert item["episode"]["tmdb_id"] == 300001
    assert item["episode"]["season_number"] == 2
    assert item["episode"]["episode_number"] == 3
    assert item["episode"]["title"] == "Who Is Alive?"
    assert item["episode"]["is_watched"] is False


def test_list_upcoming_respects_limit(
    client: TestClient,
    db_session: Session,
) -> None:
    local_user = create_local_user(db_session)

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    create_library_entry(
        db_session,
        user=local_user,
        show=show,
        status=LibraryStatus.WATCHING,
    )

    season = create_season(
        db_session,
        show=show,
        tmdb_id=134792,
        season_number=2,
        title="Season 2",
    )

    for index in range(5):
        create_episode(
            db_session,
            season=season,
            tmdb_id=300000 + index,
            episode_number=index + 1,
            title=f"Episode {index + 1}",
            air_date=date(2026, 8, 20 + index),
        )

    response = client.get(
        "/api/v1/library/shows/upcoming",
        params={
            "from_date": "2026-08-20",
            "to_date": "2026-08-24",
            "limit": 2,
        },
    )

    assert response.status_code == 200

    body = response.json()

    assert len(body) == 2
    assert body[0]["episode"]["episode_number"] == 1
    assert body[1]["episode"]["episode_number"] == 2


def test_get_library_preview_returns_recent_shows_and_movies(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return recent Show and Movie additions for the Profile Library preview."""

    user = create_local_user(
        db_session,
    )

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    create_library_entry(
        db_session,
        user=user,
        show=show,
        status=LibraryStatus.WATCHING,
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
        air_date=date.today() - timedelta(days=2),
    )

    create_episode(
        db_session,
        season=season,
        tmdb_id=2102,
        episode_number=2,
        title="Half Loop",
        air_date=date.today() - timedelta(days=1),
    )

    create_episode_progress(
        db_session,
        user=user,
        episode=first_episode,
        is_watched=True,
    )

    movie = create_movie(
        db_session,
        tmdb_id=438631,
        title="Dune",
    )

    create_movie_library_entry(
        db_session,
        user=user,
        movie=movie,
        status=LibraryStatus.PLANNING,
    )

    response = client.get(
        "/api/v1/library/preview",
    )

    assert response.status_code == 200

    body = response.json()

    assert set(body) == {
        "total_shows",
        "total_movies",
        "shows",
        "movies",
    }

    assert body["total_shows"] == 1
    assert body["total_movies"] == 1

    assert len(body["shows"]) == 1

    show_item = body["shows"][0]

    assert show_item["show"]["id"] == str(show.id)
    assert show_item["show"]["tmdb_id"] == 95396
    assert show_item["show"]["title"] == "Severance"

    assert len(body["movies"]) == 1

    movie_item = body["movies"][0]

    assert movie_item["movie"]["id"] == str(movie.id)
    assert movie_item["movie"]["tmdb_id"] == 438631
    assert movie_item["movie"]["title"] == "Dune"


def test_get_library_preview_returns_empty_collections_for_empty_library(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return usable empty preview collections when the Library is empty."""

    create_local_user(
        db_session,
    )

    response = client.get(
        "/api/v1/library/preview",
    )

    assert response.status_code == 200

    assert response.json() == {
        "total_shows": 0,
        "total_movies": 0,
        "shows": [],
        "movies": [],
    }


def test_get_library_preview_returns_ten_most_recent_shows_and_movies(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return at most the ten most recently added items of each media type."""

    user = create_local_user(
        db_session,
    )

    base_time = datetime(
        2026,
        8,
        1,
        12,
        0,
        tzinfo=UTC,
    )

    show_entries: list[LibraryEntry] = []
    movie_entries: list[LibraryEntry] = []

    for index in range(12):
        show = create_show(
            db_session,
            tmdb_id=100000 + index,
            title=f"Show {index}",
        )

        show_entry = create_library_entry(
            db_session,
            user=user,
            show=show,
        )

        show_entry.created_at = base_time + timedelta(
            minutes=index,
        )

        show_entries.append(
            show_entry,
        )

        movie = create_movie(
            db_session,
            tmdb_id=200000 + index,
            title=f"Movie {index}",
        )

        movie_entry = create_movie_library_entry(
            db_session,
            user=user,
            movie=movie,
        )

        movie_entry.created_at = base_time + timedelta(
            minutes=index,
        )

        movie_entries.append(
            movie_entry,
        )

    db_session.commit()

    response = client.get(
        "/api/v1/library/preview",
    )

    assert response.status_code == 200

    body = response.json()

    assert len(body["shows"]) == 10
    assert len(body["movies"]) == 10

    assert [item["show"]["tmdb_id"] for item in body["shows"]] == [
        100011,
        100010,
        100009,
        100008,
        100007,
        100006,
        100005,
        100004,
        100003,
        100002,
    ]

    assert [item["movie"]["tmdb_id"] for item in body["movies"]] == [
        200011,
        200010,
        200009,
        200008,
        200007,
        200006,
        200005,
        200004,
        200003,
        200002,
    ]


def test_get_library_preview_is_isolated_to_current_user(
    client: TestClient,
    db_session: Session,
) -> None:
    """Exclude Library media belonging to another user."""

    local_user = create_local_user(
        db_session,
    )

    other_user = create_user(
        db_session,
        display_name="Other User",
    )

    local_show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    other_show = create_show(
        db_session,
        tmdb_id=1396,
        title="Breaking Bad",
    )

    create_library_entry(
        db_session,
        user=local_user,
        show=local_show,
    )

    create_library_entry(
        db_session,
        user=other_user,
        show=other_show,
    )

    local_movie = create_movie(
        db_session,
        tmdb_id=438631,
        title="Dune",
    )

    other_movie = create_movie(
        db_session,
        tmdb_id=603,
        title="The Matrix",
    )

    create_movie_library_entry(
        db_session,
        user=local_user,
        movie=local_movie,
    )

    create_movie_library_entry(
        db_session,
        user=other_user,
        movie=other_movie,
    )

    response = client.get(
        "/api/v1/library/preview",
    )

    assert response.status_code == 200

    body = response.json()

    assert [item["show"]["tmdb_id"] for item in body["shows"]] == [
        95396,
    ]

    assert [item["movie"]["tmdb_id"] for item in body["movies"]] == [
        438631,
    ]


def test_get_library_preview_limits_shows_and_movies_independently(
    client: TestClient,
    db_session: Session,
) -> None:
    """Apply the preview limit independently to Shows and Movies."""

    user = create_local_user(
        db_session,
    )

    for index in range(12):
        show = create_show(
            db_session,
            tmdb_id=300000 + index,
            title=f"Show {index}",
        )

        create_library_entry(
            db_session,
            user=user,
            show=show,
        )

    movie = create_movie(
        db_session,
        tmdb_id=400000,
        title="Only Movie",
    )

    create_movie_library_entry(
        db_session,
        user=user,
        movie=movie,
    )

    response = client.get(
        "/api/v1/library/preview",
    )

    assert response.status_code == 200

    body = response.json()

    assert len(body["shows"]) == 10
    assert len(body["movies"]) == 1

    assert body["movies"][0]["movie"]["tmdb_id"] == 400000


def test_get_history_preview_returns_recent_episode_and_movie_events(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return independent recent Episode and Movie History previews."""

    user = create_local_user(
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
        air_date=date(2022, 2, 18),
    )

    episode_event = create_episode_watch_event(
        db_session,
        user=user,
        episode=episode,
        watched_at=datetime(
            2026,
            8,
            19,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    movie = create_movie(
        db_session,
        tmdb_id=438631,
        title="Dune",
    )

    movie_event = create_movie_watch_event(
        db_session,
        user=user,
        movie=movie,
        watched_at=datetime(
            2026,
            8,
            19,
            19,
            0,
            tzinfo=UTC,
        ),
    )

    response = client.get(
        "/api/v1/library/history/preview",
    )

    assert response.status_code == 200

    body = response.json()

    assert set(body) == {
        "episodes",
        "movies",
    }

    assert len(body["episodes"]) == 1
    assert len(body["movies"]) == 1

    episode_item = body["episodes"][0]

    assert episode_item["media_type"] == "episode"
    assert episode_item["event_id"] == str(episode_event.id)

    assert episode_item["show"]["id"] == str(show.id)
    assert episode_item["show"]["tmdb_id"] == 95396
    assert episode_item["show"]["title"] == "Severance"

    assert episode_item["episode"]["id"] == str(episode.id)
    assert episode_item["episode"]["tmdb_id"] == 2101
    assert episode_item["episode"]["season_number"] == 1
    assert episode_item["episode"]["episode_number"] == 1
    assert episode_item["episode"]["title"] == "Good News About Hell"

    movie_item = body["movies"][0]

    assert movie_item["media_type"] == "movie"
    assert movie_item["event_id"] == str(movie_event.id)

    assert movie_item["movie"]["id"] == str(movie.id)
    assert movie_item["movie"]["tmdb_id"] == 438631
    assert movie_item["movie"]["title"] == "Dune"


def test_list_history_combines_episode_and_movie_events_newest_first(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return Episode and Movie viewings in one chronological timeline."""

    user = create_local_user(
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
        air_date=date(2022, 2, 18),
    )

    episode_event = create_episode_watch_event(
        db_session,
        user=user,
        episode=episode,
        watched_at=datetime(
            2026,
            8,
            19,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    older_movie = create_movie(
        db_session,
        tmdb_id=438631,
        title="Dune",
    )

    older_movie_event = create_movie_watch_event(
        db_session,
        user=user,
        movie=older_movie,
        watched_at=datetime(
            2026,
            8,
            19,
            19,
            0,
            tzinfo=UTC,
        ),
    )

    newer_movie = create_movie(
        db_session,
        tmdb_id=329865,
        title="Arrival",
    )

    newer_movie_event = create_movie_watch_event(
        db_session,
        user=user,
        movie=newer_movie,
        watched_at=datetime(
            2026,
            8,
            19,
            21,
            0,
            tzinfo=UTC,
        ),
    )

    response = client.get(
        "/api/v1/library/history",
    )

    assert response.status_code == 200

    body = response.json()

    assert body["has_more"] is False
    assert body["next_cursor"] is None

    assert [item["event_id"] for item in body["items"]] == [
        str(newer_movie_event.id),
        str(episode_event.id),
        str(older_movie_event.id),
    ]

    assert [item["media_type"] for item in body["items"]] == [
        "movie",
        "episode",
        "movie",
    ]


def test_list_history_supports_cursor_pagination(
    client: TestClient,
    db_session: Session,
) -> None:
    """Continue combined History from the opaque cursor."""

    user = create_local_user(
        db_session,
    )

    movies = [
        create_movie(
            db_session,
            tmdb_id=438631 + index,
            title=f"Movie {index + 1}",
        )
        for index in range(3)
    ]

    events = [
        create_movie_watch_event(
            db_session,
            user=user,
            movie=movie,
            watched_at=datetime(
                2026,
                8,
                19,
                22 - index,
                0,
                tzinfo=UTC,
            ),
        )
        for index, movie in enumerate(movies)
    ]

    first_response = client.get(
        "/api/v1/library/history",
        params={
            "limit": 2,
        },
    )

    assert first_response.status_code == 200

    first_body = first_response.json()

    assert [item["event_id"] for item in first_body["items"]] == [
        str(events[0].id),
        str(events[1].id),
    ]

    assert first_body["has_more"] is True
    assert first_body["next_cursor"] is not None

    second_response = client.get(
        "/api/v1/library/history",
        params={
            "limit": 2,
            "cursor": first_body["next_cursor"],
        },
    )

    assert second_response.status_code == 200

    second_body = second_response.json()

    assert [item["event_id"] for item in second_body["items"]] == [
        str(events[2].id),
    ]

    assert second_body["has_more"] is False
    assert second_body["next_cursor"] is None


def test_list_history_returns_400_for_invalid_cursor(
    client: TestClient,
    db_session: Session,
) -> None:
    """Map malformed History cursor to a safe API error."""

    create_local_user(
        db_session,
    )

    response = client.get(
        "/api/v1/library/history",
        params={
            "cursor": "invalid-history-cursor",
        },
    )

    assert response.status_code == 400

    body = response.json()

    assert body["error"]["code"] == "invalid_history_cursor"


def test_list_history_rejects_invalid_limit(
    client: TestClient,
    db_session: Session,
) -> None:
    """Reject History limits outside the public API contract."""

    create_local_user(
        db_session,
    )

    response = client.get(
        "/api/v1/library/history",
        params={
            "limit": 0,
        },
    )

    assert response.status_code == 422

def test_list_history_can_filter_episode_history(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return only Episode events when media_type=episode."""

    user = create_local_user(db_session)

    show = create_show(
        db_session,
        tmdb_id=95396,
        title="Severance",
    )

    season = create_season(
        db_session,
        show=show,
        tmdb_id=200001,
        season_number=1,
        title="Season 1",
    )

    episode = create_episode(
        db_session,
        season=season,
        tmdb_id=123456,
        episode_number=1,
        title="Good News About Hell",
        air_date=date(2022, 2, 18),
    )

    episode_event = create_episode_watch_event(
        db_session,
        user=user,
        episode=episode,
        watched_at=datetime(
            2026,
            8,
            19,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    movie = create_movie(
        db_session,
        tmdb_id=438631,
        title="Dune",
    )

    create_movie_watch_event(
        db_session,
        user=user,
        movie=movie,
        watched_at=datetime(
            2026,
            8,
            19,
            21,
            0,
            tzinfo=UTC,
        ),
    )

    response = client.get(
        "/api/v1/library/history",
        params={
            "media_type": "episode",
        },
    )

    assert response.status_code == 200

    body = response.json()

    assert [item["event_id"] for item in body["items"]] == [
        str(episode_event.id),
    ]

    assert [item["media_type"] for item in body["items"]] == [
        "episode",
    ]

def test_list_history_rejects_invalid_media_type(
    client: TestClient,
    db_session: Session,
) -> None:
    """Reject unsupported History media types."""

    create_local_user(db_session)

    response = client.get(
        "/api/v1/library/history",
        params={
            "media_type": "show",
        },
    )

    assert response.status_code == 422

