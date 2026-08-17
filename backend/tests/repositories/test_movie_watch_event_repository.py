from datetime import UTC, datetime
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.movie import Movie
from app.models.movie_watch_event import MovieWatchEvent
from app.models.user import User
from app.repositories.movie_watch_event import MovieWatchEventRepository


def as_utc(value: datetime) -> datetime:
    """Normalize a database datetime to UTC."""

    if value.tzinfo is None:
        return value.replace(tzinfo=UTC)

    return value.astimezone(UTC)


def create_user(
    db_session: Session,
    *,
    display_name: str = "Test User",
) -> User:
    """Create and persist a user."""

    user = User(
        display_name=display_name,
        is_local=False,
    )

    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)

    return user


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


def create_watch_event(
    db_session: Session,
    *,
    user: User,
    movie: Movie,
    watched_at: datetime,
    event_id: UUID | None = None,
) -> MovieWatchEvent:
    """Create and persist one historical Movie viewing."""

    if event_id is None:
        event = MovieWatchEvent(
            user_id=user.id,
            movie_id=movie.id,
            watched_at=watched_at,
        )
    else:
        event = MovieWatchEvent(
            id=event_id,
            user_id=user.id,
            movie_id=movie.id,
            watched_at=watched_at,
        )

    db_session.add(event)
    db_session.commit()
    db_session.refresh(event)

    return event


def test_add_movie_watch_event(
    db_session: Session,
) -> None:
    """Add a Movie watch event to the current unit of work."""

    user = create_user(db_session)

    movie = create_movie(
        db_session,
        tmdb_id=438631,
        title="Dune",
    )

    watched_at = datetime(
        2026,
        8,
        14,
        21,
        30,
        tzinfo=UTC,
    )

    repository = MovieWatchEventRepository(
        db_session,
    )

    event = MovieWatchEvent(
        user_id=user.id,
        movie_id=movie.id,
        watched_at=watched_at,
    )

    result = repository.add(
        event,
    )

    assert result is event

    db_session.commit()
    db_session.refresh(event)

    persisted_event = db_session.scalar(
        select(MovieWatchEvent).where(
            MovieWatchEvent.id == event.id,
        )
    )

    assert persisted_event is not None
    assert persisted_event.user_id == user.id
    assert persisted_event.movie_id == movie.id

    assert as_utc(
        persisted_event.watched_at,
    ) == watched_at


def test_allows_multiple_watch_events_for_same_movie(
    db_session: Session,
) -> None:
    """Store multiple historical viewings for the same Movie."""

    user = create_user(db_session)

    movie = create_movie(
        db_session,
        tmdb_id=438631,
        title="Dune",
    )

    repository = MovieWatchEventRepository(
        db_session,
    )

    first_event = MovieWatchEvent(
        user_id=user.id,
        movie_id=movie.id,
        watched_at=datetime(
            2026,
            8,
            1,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    second_event = MovieWatchEvent(
        user_id=user.id,
        movie_id=movie.id,
        watched_at=datetime(
            2026,
            8,
            14,
            21,
            30,
            tzinfo=UTC,
        ),
    )

    repository.add(first_event)
    repository.add(second_event)

    db_session.commit()

    events = list(
        db_session.scalars(
            select(MovieWatchEvent)
            .where(
                MovieWatchEvent.user_id == user.id,
                MovieWatchEvent.movie_id == movie.id,
            )
            .order_by(
                MovieWatchEvent.watched_at.asc(),
            )
        ).all()
    )

    assert len(events) == 2

    assert events[0].id == first_event.id
    assert events[1].id == second_event.id


def test_get_by_id_returns_movie_watch_event(
    db_session: Session,
) -> None:
    """Return a Movie watch event by its UUID."""

    user = create_user(db_session)

    movie = create_movie(
        db_session,
        tmdb_id=438631,
        title="Dune",
    )

    event = create_watch_event(
        db_session,
        user=user,
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

    repository = MovieWatchEventRepository(
        db_session,
    )

    result = repository.get_by_id(
        event.id,
    )

    assert result is not None
    assert result.id == event.id
    assert result.user_id == user.id
    assert result.movie_id == movie.id


def test_get_by_id_for_user_and_movie_requires_matching_owner_and_movie(
    db_session: Session,
) -> None:
    """Return an event only for its owning user and Movie."""

    user = create_user(
        db_session,
        display_name="First User",
    )

    other_user = create_user(
        db_session,
        display_name="Other User",
    )

    movie = create_movie(
        db_session,
        tmdb_id=438631,
        title="Dune",
    )

    other_movie = create_movie(
        db_session,
        tmdb_id=329865,
        title="Arrival",
    )

    event = create_watch_event(
        db_session,
        user=user,
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

    repository = MovieWatchEventRepository(
        db_session,
    )

    matching = repository.get_by_id_for_user_and_movie(
        event_id=event.id,
        user_id=user.id,
        movie_id=movie.id,
    )

    wrong_user = repository.get_by_id_for_user_and_movie(
        event_id=event.id,
        user_id=other_user.id,
        movie_id=movie.id,
    )

    wrong_movie = repository.get_by_id_for_user_and_movie(
        event_id=event.id,
        user_id=user.id,
        movie_id=other_movie.id,
    )

    assert matching is not None
    assert matching.id == event.id

    assert wrong_user is None
    assert wrong_movie is None


def test_list_by_user_and_movie_returns_newest_first(
    db_session: Session,
) -> None:
    """Return Movie viewings from newest to oldest."""

    user = create_user(db_session)

    movie = create_movie(
        db_session,
        tmdb_id=438631,
        title="Dune",
    )

    older_event = create_watch_event(
        db_session,
        user=user,
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

    newer_event = create_watch_event(
        db_session,
        user=user,
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

    repository = MovieWatchEventRepository(
        db_session,
    )

    result = repository.list_by_user_and_movie(
        user_id=user.id,
        movie_id=movie.id,
    )

    assert len(result) == 2

    assert result[0].id == newer_event.id
    assert result[1].id == older_event.id


def test_list_by_user_and_movie_is_isolated_by_user_and_movie(
    db_session: Session,
) -> None:
    """Do not leak Movie viewing history across users or Movies."""

    user = create_user(
        db_session,
        display_name="First User",
    )

    other_user = create_user(
        db_session,
        display_name="Other User",
    )

    movie = create_movie(
        db_session,
        tmdb_id=438631,
        title="Dune",
    )

    other_movie = create_movie(
        db_session,
        tmdb_id=329865,
        title="Arrival",
    )

    expected_event = create_watch_event(
        db_session,
        user=user,
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

    create_watch_event(
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

    create_watch_event(
        db_session,
        user=user,
        movie=other_movie,
        watched_at=datetime(
            2026,
            8,
            14,
            22,
            0,
            tzinfo=UTC,
        ),
    )

    repository = MovieWatchEventRepository(
        db_session,
    )

    result = repository.list_by_user_and_movie(
        user_id=user.id,
        movie_id=movie.id,
    )

    assert len(result) == 1
    assert result[0].id == expected_event.id


def test_count_by_user_and_movie_counts_rewatches(
    db_session: Session,
) -> None:
    """Count every real Movie viewing, including Rewatches."""

    user = create_user(db_session)

    movie = create_movie(
        db_session,
        tmdb_id=438631,
        title="Dune",
    )

    create_watch_event(
        db_session,
        user=user,
        movie=movie,
        watched_at=datetime(
            2026,
            8,
            1,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    create_watch_event(
        db_session,
        user=user,
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

    repository = MovieWatchEventRepository(
        db_session,
    )

    result = repository.count_by_user_and_movie(
        user_id=user.id,
        movie_id=movie.id,
    )

    assert result == 2


def test_get_latest_for_user_and_movie(
    db_session: Session,
) -> None:
    """Return the most recent Movie viewing."""

    user = create_user(db_session)

    movie = create_movie(
        db_session,
        tmdb_id=438631,
        title="Dune",
    )

    create_watch_event(
        db_session,
        user=user,
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

    latest = create_watch_event(
        db_session,
        user=user,
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

    repository = MovieWatchEventRepository(
        db_session,
    )

    result = repository.get_latest_for_user_and_movie(
        user_id=user.id,
        movie_id=movie.id,
    )

    assert result is not None
    assert result.id == latest.id


def test_get_earliest_for_user_and_movie(
    db_session: Session,
) -> None:
    """Return the oldest recorded Movie viewing."""

    user = create_user(db_session)

    movie = create_movie(
        db_session,
        tmdb_id=438631,
        title="Dune",
    )

    earliest = create_watch_event(
        db_session,
        user=user,
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

    create_watch_event(
        db_session,
        user=user,
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

    repository = MovieWatchEventRepository(
        db_session,
    )

    result = repository.get_earliest_for_user_and_movie(
        user_id=user.id,
        movie_id=movie.id,
    )

    assert result is not None
    assert result.id == earliest.id


def test_delete_removes_one_movie_watch_event(
    db_session: Session,
) -> None:
    """Delete one historical Movie viewing."""

    user = create_user(db_session)

    movie = create_movie(
        db_session,
        tmdb_id=438631,
        title="Dune",
    )

    event = create_watch_event(
        db_session,
        user=user,
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

    repository = MovieWatchEventRepository(
        db_session,
    )

    repository.delete(
        event,
    )

    db_session.commit()

    persisted = db_session.get(
        MovieWatchEvent,
        event.id,
    )

    assert persisted is None


def test_delete_all_for_user_and_movie_is_scoped(
    db_session: Session,
) -> None:
    """Delete only events belonging to the requested user and Movie."""

    user = create_user(
        db_session,
        display_name="First User",
    )

    other_user = create_user(
        db_session,
        display_name="Other User",
    )

    movie = create_movie(
        db_session,
        tmdb_id=438631,
        title="Dune",
    )

    other_movie = create_movie(
        db_session,
        tmdb_id=329865,
        title="Arrival",
    )

    create_watch_event(
        db_session,
        user=user,
        movie=movie,
        watched_at=datetime(
            2026,
            8,
            1,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    create_watch_event(
        db_session,
        user=user,
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

    other_user_event = create_watch_event(
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

    other_movie_event = create_watch_event(
        db_session,
        user=user,
        movie=other_movie,
        watched_at=datetime(
            2026,
            8,
            14,
            22,
            0,
            tzinfo=UTC,
        ),
    )

    repository = MovieWatchEventRepository(
        db_session,
    )

    deleted_count = repository.delete_all_for_user_and_movie(
        user_id=user.id,
        movie_id=movie.id,
    )

    db_session.commit()

    assert deleted_count == 2

    remaining = list(
        db_session.scalars(
            select(MovieWatchEvent)
        ).all()
    )

    assert len(remaining) == 2

    remaining_ids = {
        event.id
        for event in remaining
    }

    assert remaining_ids == {
        other_user_event.id,
        other_movie_event.id,
    }


def test_delete_all_for_user_and_movie_is_idempotent(
    db_session: Session,
) -> None:
    """Deleting an already empty Movie history returns zero."""

    user = create_user(db_session)

    movie = create_movie(
        db_session,
        tmdb_id=438631,
        title="Dune",
    )

    repository = MovieWatchEventRepository(
        db_session,
    )

    deleted_count = repository.delete_all_for_user_and_movie(
        user_id=user.id,
        movie_id=movie.id,
    )

    assert deleted_count == 0