from datetime import UTC, date, datetime

import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session
from uuid import UUID, uuid4

from app.models.enums import LibraryStatus
from app.models.library import LibraryEntry
from app.models.movie import Movie
from app.models.show import Show
from app.models.user import User
from app.models.episode import Episode
from app.models.episode_progress import EpisodeProgress
from app.models.season import Season



def create_local_user(
    db_session: Session,
) -> User:
    """Create and persist the local SofaWatch user."""

    user = User(
        display_name="Local User",
        is_local=True,
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
        is_local=False,
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