from datetime import UTC, datetime
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.movie import Movie
from app.models.movie_watch_event import MovieWatchEvent
from app.models.user import User
from app.repositories.movie_watch_event import MovieWatchEventRepository
from app.models.genre import Genre


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

def create_genre(
    db_session: Session,
    *,
    name: str,
    slug: str,
) -> Genre:
    """Create and persist a Genre."""

    genre = Genre(
        name=name,
        slug=slug,
    )

    db_session.add(genre)
    db_session.commit()
    db_session.refresh(genre)

    return genre


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


def test_get_statistics_for_period_counts_viewings_and_runtime(
    db_session: Session,
) -> None:
    """Aggregate Movie viewing count and runtime within a period."""

    user = create_user(
        db_session,
    )

    movie = create_movie(
        db_session,
        tmdb_id=438631,
        title="Dune",
    )

    movie.runtime = 155

    db_session.commit()

    create_watch_event(
        db_session,
        user=user,
        movie=movie,
        watched_at=datetime(
            2026,
            8,
            17,
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
            21,
            21,
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
            16,
            23,
            59,
            tzinfo=UTC,
        ),
    )

    repository = MovieWatchEventRepository(
        db_session,
    )

    count, watch_time = repository.get_statistics_for_period(
        user_id=user.id,
        start_at=datetime(
            2026,
            8,
            17,
            tzinfo=UTC,
        ),
        end_at=datetime(
            2026,
            8,
            24,
            tzinfo=UTC,
        ),
    )

    assert count == 2
    assert watch_time == 310


def test_get_statistics_for_period_counts_movie_without_runtime(
    db_session: Session,
) -> None:
    """Count a Movie viewing even when runtime is unknown."""

    user = create_user(
        db_session,
    )

    movie = create_movie(
        db_session,
        tmdb_id=438631,
        title="Dune",
    )

    movie.runtime = None

    db_session.commit()

    create_watch_event(
        db_session,
        user=user,
        movie=movie,
        watched_at=datetime(
            2026,
            8,
            19,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    repository = MovieWatchEventRepository(
        db_session,
    )

    count, watch_time = repository.get_statistics_for_period(
        user_id=user.id,
        start_at=datetime(
            2026,
            8,
            17,
            tzinfo=UTC,
        ),
        end_at=datetime(
            2026,
            8,
            24,
            tzinfo=UTC,
        ),
    )

    assert count == 1
    assert watch_time == 0

def test_get_all_time_statistics_counts_unique_movies_and_rewatches(
    db_session: Session,
) -> None:
    """Aggregate all-time Movie watches, unique Movies and rewatches."""

    user = create_user(
        db_session,
    )

    first_movie = create_movie(
        db_session,
        tmdb_id=438631,
        title="Dune",
    )

    second_movie = create_movie(
        db_session,
        tmdb_id=27205,
        title="Inception",
    )

    first_movie.runtime = 155
    second_movie.runtime = 148

    db_session.commit()

    # Dune: original watch + two rewatches.
    create_watch_event(
        db_session,
        user=user,
        movie=first_movie,
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
        movie=first_movie,
        watched_at=datetime(
            2026,
            8,
            2,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    create_watch_event(
        db_session,
        user=user,
        movie=first_movie,
        watched_at=datetime(
            2026,
            8,
            3,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    create_watch_event(
        db_session,
        user=user,
        movie=second_movie,
        watched_at=datetime(
            2026,
            8,
            4,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    repository = MovieWatchEventRepository(
        db_session,
    )

    (
        watch_count,
        unique_count,
        rewatch_count,
        watch_time_minutes,
        rewatch_time_minutes,
    ) = repository.get_all_time_statistics(
        user_id=user.id,
    )

    assert watch_count == 4
    assert unique_count == 2
    assert rewatch_count == 2

    # Dune 3x + Inception 1x.
    assert watch_time_minutes == 613

    # The second and third Dune views are rewatches.
    assert rewatch_time_minutes == 310

    assert watch_count == unique_count + rewatch_count


def test_get_all_time_statistics_counts_movie_without_runtime(
    db_session: Session,
) -> None:
    """Count Movie watches even when runtime is unknown."""

    user = create_user(
        db_session,
    )

    movie = create_movie(
        db_session,
        tmdb_id=438631,
        title="Dune",
    )

    movie.runtime = None

    db_session.commit()

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
            2,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    repository = MovieWatchEventRepository(
        db_session,
    )

    (
        watch_count,
        unique_count,
        rewatch_count,
        watch_time_minutes,
        rewatch_time_minutes,
    ) = repository.get_all_time_statistics(
        user_id=user.id,
    )

    assert watch_count == 2
    assert unique_count == 1
    assert rewatch_count == 1
    assert watch_time_minutes == 0
    assert rewatch_time_minutes == 0


def test_get_all_time_statistics_is_isolated_by_user(
    db_session: Session,
) -> None:
    """Only include Movie watches belonging to the requested user."""

    first_user = create_user(
        db_session,
        display_name="First User",
    )

    second_user = create_user(
        db_session,
        display_name="Second User",
    )

    movie = create_movie(
        db_session,
        tmdb_id=438631,
        title="Dune",
    )

    movie.runtime = 155

    db_session.commit()

    create_watch_event(
        db_session,
        user=first_user,
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
        user=second_user,
        movie=movie,
        watched_at=datetime(
            2026,
            8,
            2,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    create_watch_event(
        db_session,
        user=second_user,
        movie=movie,
        watched_at=datetime(
            2026,
            8,
            3,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    repository = MovieWatchEventRepository(
        db_session,
    )

    result = repository.get_all_time_statistics(
        user_id=first_user.id,
    )

    assert result == (
        1,
        1,
        0,
        155,
        0,
    )

def test_get_daily_statistics_for_period_groups_movie_activity_by_day(
    db_session: Session,
) -> None:
    """Group Movie viewing counts and runtime by calendar day."""

    user = create_user(
        db_session,
    )

    movie = create_movie(
        db_session,
        tmdb_id=438631,
        title="Dune",
    )

    movie.runtime = 155

    db_session.commit()

    create_watch_event(
        db_session,
        user=user,
        movie=movie,
        watched_at=datetime(
            2026,
            8,
            17,
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
            17,
            23,
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
            19,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    repository = MovieWatchEventRepository(
        db_session,
    )

    result = repository.get_daily_statistics_for_period(
        user_id=user.id,
        start_at=datetime(
            2026,
            8,
            17,
            tzinfo=UTC,
        ),
        end_at=datetime(
            2026,
            8,
            20,
            tzinfo=UTC,
        ),
    )

    assert [
        (
            item.day,
            item.watch_count,
            item.watch_time_minutes,
        )
        for item in result
    ] == [
        (
            "2026-08-17",
            2,
            310,
        ),
        (
            "2026-08-19",
            1,
            155,
        ),
    ]


def test_get_daily_statistics_for_period_counts_unknown_movie_runtime_as_zero(
    db_session: Session,
) -> None:
    """Keep Movie activity when runtime is unavailable."""

    user = create_user(
        db_session,
    )

    movie = create_movie(
        db_session,
        tmdb_id=438631,
        title="Dune",
    )

    movie.runtime = None

    db_session.commit()

    create_watch_event(
        db_session,
        user=user,
        movie=movie,
        watched_at=datetime(
            2026,
            8,
            17,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    repository = MovieWatchEventRepository(
        db_session,
    )

    result = repository.get_daily_statistics_for_period(
        user_id=user.id,
        start_at=datetime(
            2026,
            8,
            17,
            tzinfo=UTC,
        ),
        end_at=datetime(
            2026,
            8,
            18,
            tzinfo=UTC,
        ),
    )

    assert len(result) == 1
    assert result[0].watch_count == 1
    assert result[0].watch_time_minutes == 0


def test_get_earliest_watched_at_for_user(
    db_session: Session,
) -> None:
    user = create_user(
        db_session,
    )

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
            18,
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
            2024,
            7,
            11,
            21,
            0,
            tzinfo=UTC,
        ),
    )

    repository = MovieWatchEventRepository(
        db_session,
    )

    result = repository.get_earliest_watched_at_for_user(
        user_id=user.id,
    )

    assert result is not None
    assert as_utc(result) == datetime(
        2024,
        7,
        11,
        21,
        0,
        tzinfo=UTC,
    )


def test_get_earliest_watched_at_for_user_returns_none_without_history(
    db_session: Session,
) -> None:
    user = create_user(
        db_session,
    )

    repository = MovieWatchEventRepository(
        db_session,
    )

    assert (
        repository.get_earliest_watched_at_for_user(
            user_id=user.id,
        )
        is None
    )

def test_get_most_rewatched_movies_excludes_single_viewings(
    db_session: Session,
) -> None:
    """Rank Movies by Rewatch count and exclude Movies watched once."""

    user = create_user(
        db_session,
    )

    other_user = create_user(
        db_session,
        display_name="Other User",
    )

    dune = create_movie(
        db_session,
        tmdb_id=438631,
        title="Dune",
    )

    arrival = create_movie(
        db_session,
        tmdb_id=329865,
        title="Arrival",
    )

    blade_runner = create_movie(
        db_session,
        tmdb_id=335984,
        title="Blade Runner 2049",
    )

    for hour in (
        10,
        11,
        12,
    ):
        create_watch_event(
            db_session,
            user=user,
            movie=dune,
            watched_at=datetime(
                2026,
                8,
                18,
                hour,
                0,
                tzinfo=UTC,
            ),
        )

    for hour in (
        13,
        14,
    ):
        create_watch_event(
            db_session,
            user=user,
            movie=arrival,
            watched_at=datetime(
                2026,
                8,
                18,
                hour,
                0,
                tzinfo=UTC,
            ),
        )

    create_watch_event(
        db_session,
        user=user,
        movie=blade_runner,
        watched_at=datetime(
            2026,
            8,
            18,
            15,
            0,
            tzinfo=UTC,
        ),
    )

    # Must not affect requested user's ranking.
    for hour in (
        16,
        17,
        18,
    ):
        create_watch_event(
            db_session,
            user=other_user,
            movie=arrival,
            watched_at=datetime(
                2026,
                8,
                17,
                hour,
                0,
                tzinfo=UTC,
            ),
        )

    repository = MovieWatchEventRepository(
        db_session,
    )

    result = repository.get_most_rewatched_movies(
        user_id=user.id,
        limit=5,
    )

    assert [
        (
            item.title,
            item.watch_count,
            item.rewatch_count,
        )
        for item in result
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


def test_get_top_movie_genres_counts_movie_watch_events_for_each_genre(
    db_session: Session,
) -> None:
    """Rank Movie Genres by Movie watch events."""

    user = create_user(
        db_session,
    )

    science_fiction = create_genre(
        db_session,
        name="Science Fiction",
        slug="science-fiction",
    )

    drama = create_genre(
        db_session,
        name="Drama",
        slug="drama",
    )

    dune = create_movie(
        db_session,
        tmdb_id=438631,
        title="Dune",
    )

    arrival = create_movie(
        db_session,
        tmdb_id=329865,
        title="Arrival",
    )

    dune.genres.extend(
        [
            science_fiction,
            drama,
        ]
    )

    arrival.genres.append(
        science_fiction,
    )

    db_session.commit()

    for hour in (
        10,
        11,
        12,
    ):
        create_watch_event(
            db_session,
            user=user,
            movie=dune,
            watched_at=datetime(
                2026,
                8,
                18,
                hour,
                0,
                tzinfo=UTC,
            ),
        )

    for hour in (
        13,
        14,
    ):
        create_watch_event(
            db_session,
            user=user,
            movie=arrival,
            watched_at=datetime(
                2026,
                8,
                18,
                hour,
                0,
                tzinfo=UTC,
            ),
        )

    repository = MovieWatchEventRepository(
        db_session,
    )

    result = repository.get_top_movie_genres(
        user_id=user.id,
        limit=5,
    )

    assert [
        (
            item.name,
            item.watch_count,
        )
        for item in result
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

def test_list_watch_history_returns_newest_events_first(
    db_session: Session,
) -> None:
    """Return global Movie History from newest to oldest."""

    user = create_user(db_session)

    dune = create_movie(
        db_session,
        tmdb_id=438631,
        title="Dune",
    )

    arrival = create_movie(
        db_session,
        tmdb_id=329865,
        title="Arrival",
    )

    older_event = create_watch_event(
        db_session,
        user=user,
        movie=dune,
        watched_at=datetime(
            2026,
            8,
            10,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    newer_event = create_watch_event(
        db_session,
        user=user,
        movie=arrival,
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

    page = repository.list_watch_history(
        user_id=user.id,
        limit=30,
    )

    assert page.has_more is False

    assert len(page.items) == 2

    assert page.items[0].event_id == newer_event.id
    assert page.items[0].movie.id == arrival.id
    assert page.items[0].movie.title == "Arrival"

    assert page.items[1].event_id == older_event.id
    assert page.items[1].movie.id == dune.id
    assert page.items[1].movie.title == "Dune"

    assert as_utc(page.items[0].watched_at) == datetime(
        2026,
        8,
        14,
        21,
        30,
        tzinfo=UTC,
    )


def test_list_watch_history_keeps_rewatches_as_independent_items(
    db_session: Session,
) -> None:
    """Keep every Movie Rewatch as an independent History entry."""

    user = create_user(db_session)

    movie = create_movie(
        db_session,
        tmdb_id=438631,
        title="Dune",
    )

    first_event = create_watch_event(
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

    rewatch_event = create_watch_event(
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

    page = repository.list_watch_history(
        user_id=user.id,
    )

    assert len(page.items) == 2

    assert page.items[0].event_id == rewatch_event.id
    assert page.items[1].event_id == first_event.id

    assert page.items[0].movie.id == movie.id
    assert page.items[1].movie.id == movie.id


def test_list_watch_history_is_isolated_by_user(
    db_session: Session,
) -> None:
    """Do not leak global Movie History between users."""

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

    repository = MovieWatchEventRepository(
        db_session,
    )

    page = repository.list_watch_history(
        user_id=user.id,
    )

    assert len(page.items) == 1
    assert page.items[0].event_id == expected_event.id


def test_list_watch_history_reports_when_more_items_exist(
    db_session: Session,
) -> None:
    """Report when another Movie History page exists."""

    user = create_user(db_session)

    movie = create_movie(
        db_session,
        tmdb_id=438631,
        title="Dune",
    )

    for day in range(1, 4):
        create_watch_event(
            db_session,
            user=user,
            movie=movie,
            watched_at=datetime(
                2026,
                8,
                day,
                20,
                0,
                tzinfo=UTC,
            ),
        )

    repository = MovieWatchEventRepository(
        db_session,
    )

    page = repository.list_watch_history(
        user_id=user.id,
        limit=2,
    )

    assert len(page.items) == 2
    assert page.has_more is True


def test_list_watch_history_supports_cursor_pagination(
    db_session: Session,
) -> None:
    """Continue Movie History before the previous page's last event."""

    user = create_user(db_session)

    movie = create_movie(
        db_session,
        tmdb_id=438631,
        title="Dune",
    )

    oldest_event = create_watch_event(
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

    middle_event = create_watch_event(
        db_session,
        user=user,
        movie=movie,
        watched_at=datetime(
            2026,
            8,
            2,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    newest_event = create_watch_event(
        db_session,
        user=user,
        movie=movie,
        watched_at=datetime(
            2026,
            8,
            3,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    repository = MovieWatchEventRepository(
        db_session,
    )

    first_page = repository.list_watch_history(
        user_id=user.id,
        limit=2,
    )

    assert len(first_page.items) == 2
    assert first_page.has_more is True

    assert first_page.items[0].event_id == newest_event.id
    assert first_page.items[1].event_id == middle_event.id

    second_page = repository.list_watch_history(
        user_id=user.id,
        limit=2,
        before_watched_at=middle_event.watched_at,
        before_event_id=middle_event.id,
    )

    assert len(second_page.items) == 1
    assert second_page.has_more is False

    assert second_page.items[0].event_id == oldest_event.id


def test_list_watch_history_uses_event_id_to_break_timestamp_ties(
    db_session: Session,
) -> None:
    """Use event ID when multiple Movie events share the same timestamp."""

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

    lower_id = UUID(
        "00000000-0000-0000-0000-000000000001",
    )

    higher_id = UUID(
        "00000000-0000-0000-0000-000000000002",
    )

    lower_event = create_watch_event(
        db_session,
        user=user,
        movie=movie,
        watched_at=watched_at,
        event_id=lower_id,
    )

    higher_event = create_watch_event(
        db_session,
        user=user,
        movie=movie,
        watched_at=watched_at,
        event_id=higher_id,
    )

    repository = MovieWatchEventRepository(
        db_session,
    )

    first_page = repository.list_watch_history(
        user_id=user.id,
        limit=1,
    )

    assert len(first_page.items) == 1
    assert first_page.items[0].event_id == higher_event.id
    assert first_page.has_more is True

    second_page = repository.list_watch_history(
        user_id=user.id,
        limit=1,
        before_watched_at=higher_event.watched_at,
        before_event_id=higher_event.id,
    )

    assert len(second_page.items) == 1
    assert second_page.items[0].event_id == lower_event.id
    assert second_page.has_more is False


def test_list_watch_history_rejects_incomplete_cursor(
    db_session: Session,
) -> None:
    """Reject an incomplete Movie History cursor."""

    user = create_user(db_session)

    repository = MovieWatchEventRepository(
        db_session,
    )

    try:
        repository.list_watch_history(
            user_id=user.id,
            before_watched_at=datetime(
                2026,
                8,
                14,
                21,
                30,
                tzinfo=UTC,
            ),
        )
    except ValueError as error:
        assert str(error) == (
            "Movie History cursor requires both "
            "before_watched_at and before_event_id."
        )
    else:
        raise AssertionError(
            "Expected incomplete Movie History cursor to be rejected."
        )


def test_list_watch_history_returns_empty_page_for_non_positive_limit(
    db_session: Session,
) -> None:
    """Return an empty Movie History page for a non-positive limit."""

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
            14,
            21,
            30,
            tzinfo=UTC,
        ),
    )

    repository = MovieWatchEventRepository(
        db_session,
    )

    page = repository.list_watch_history(
        user_id=user.id,
        limit=0,
    )

    assert page.items == []
    assert page.has_more is False


def test_list_all_for_user_returns_complete_movie_history_in_chronological_order(
    db_session: Session,
) -> None:
    """Return every Movie viewing from oldest to newest."""

    user = create_user(
        db_session,
    )

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
            8,
            1,
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

    result = repository.list_all_for_user(
        user_id=user.id,
    )

    assert [
        item.event_id
        for item in result
    ] == [
        older_event.id,
        newer_event.id,
    ]

    assert result[0].movie.id == movie.id
    assert result[0].movie.tmdb_id == 438631


def test_list_all_for_user_is_isolated_by_user(
    db_session: Session,
) -> None:
    """Return only Movie viewing events belonging to the requested user."""

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

    expected_event = create_watch_event(
        db_session,
        user=user,
        movie=movie,
        watched_at=datetime(
            2026,
            8,
            10,
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
            11,
            20,
            0,
            tzinfo=UTC,
        ),
    )

    repository = MovieWatchEventRepository(
        db_session,
    )

    result = repository.list_all_for_user(
        user_id=user.id,
    )

    assert len(result) == 1
    assert result[0].event_id == expected_event.id

def test_list_all_for_user_returns_complete_movie_history(
    db_session: Session,
) -> None:
    """Return every Movie watch event for a user."""

    user = create_user(
        db_session,
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

    older_event = create_watch_event(
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

    create_watch_event(
        db_session,
        user=other_user,
        movie=movie,
        watched_at=datetime(
            2026,
            8,
            15,
            21,
            30,
            tzinfo=UTC,
        ),
    )

    repository = MovieWatchEventRepository(
        db_session,
    )

    result = repository.list_all_for_user(
        user_id=user.id,
    )

    assert [
        item.event_id
        for item in result
    ] == [
        older_event.id,
        newer_event.id,
    ]

    assert all(
        item.movie.id == movie.id
        for item in result
    )

def test_exists_at_finds_exact_movie_watch_event(
    db_session: Session,
) -> None:
    """Detect an existing Movie viewing using media and timestamp."""

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

    create_watch_event(
        db_session,
        user=user,
        movie=movie,
        watched_at=watched_at,
    )

    repository = MovieWatchEventRepository(
        db_session,
    )

    assert repository.exists_at(
        user_id=user.id,
        movie_id=movie.id,
        watched_at=watched_at,
    )

    assert not repository.exists_at(
        user_id=user.id,
        movie_id=movie.id,
        watched_at=datetime(
            2026,
            8,
            14,
            22,
            0,
            tzinfo=UTC,
        ),
    )