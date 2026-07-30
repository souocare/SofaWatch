from uuid import uuid4

import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.models.enums import LibraryStatus
from app.models.library import LibraryEntry
from app.models.show import Show
from app.models.user import User


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

    assert response.status_code == 201

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
        "detail": "TV series not found.",
    }


def test_add_show_to_library_returns_409_when_already_present(
    client: TestClient,
    db_session: Session,
) -> None:
    """Return HTTP 409 when the TV series already exists in the library."""

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

    response = client.post(
        f"/api/v1/library/shows/{show.id}",
    )

    assert response.status_code == 409
    assert response.json() == {
        "detail": "TV series is already in the library.",
    }


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
        "detail": "TV series is not in the library.",
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
        "detail": "TV series is not in the library.",
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
