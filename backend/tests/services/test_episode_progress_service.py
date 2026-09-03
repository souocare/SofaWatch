from datetime import UTC, date, datetime
from types import SimpleNamespace
from unittest.mock import Mock
from uuid import uuid4

import pytest
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.enums import LibraryStatus
from app.models.episode import Episode
from app.models.episode_progress import EpisodeProgress
from app.models.episode_watch_event import EpisodeWatchEvent
from app.models.library import LibraryEntry
from app.models.season import Season
from app.models.show import Show
from app.models.user import User
from app.repositories.episode import EpisodeRepository
from app.repositories.episode_progress import EpisodeProgressRepository
from app.repositories.episode_watch_event import EpisodeWatchEventRepository
from app.repositories.library import LibraryRepository
from app.repositories.season import SeasonRepository
from app.repositories.show import ShowRepository
from app.services.episode_progress import (
    EpisodeNotWatchableError,
    EpisodeProgressService,
)
from app.services.show_library_status import ShowLibraryStatusSynchronizer

FIXED_TODAY = date(2026, 8, 15)


def as_utc(
    value: datetime,
) -> datetime:
    """Interpret timezone-naive database datetimes as UTC."""

    if value.tzinfo is None:
        return value.replace(
            tzinfo=UTC,
        )

    return value.astimezone(
        UTC,
    )


def persist_user(
    db_session: Session,
) -> User:
    user = User(
        display_name="Test User",
    )
    db_session.add(user)
    db_session.flush()
    return user


def persist_show(
    db_session: Session,
    *,
    tmdb_id: int = 95396,
    title: str = "Severance",
) -> Show:
    """Persist a TV series for service tests."""

    show = Show(
        tmdb_id=tmdb_id,
        title=title,
        original_title=title,
        original_language="en",
        metadata_language="en-US",
    )

    db_session.add(show)
    db_session.flush()

    return show


def persist_season(
    db_session: Session,
    *,
    show: Show,
) -> Season:
    season = Season(
        show_id=show.id,
        tmdb_id=999002,
        season_number=1,
        title="Season 1",
    )
    db_session.add(season)
    db_session.flush()
    return season


def persist_episode(
    db_session: Session,
    *,
    season: Season,
) -> Episode:
    episode = Episode(
        season_id=season.id,
        tmdb_id=999003,
        episode_number=1,
        title="Episode 1",
    )
    db_session.add(episode)
    db_session.flush()
    return episode


def make_real_show_status_synchronizer(
    db_session: Session,
) -> ShowLibraryStatusSynchronizer:
    """Build a Show Library status synchronizer using real repositories."""

    return ShowLibraryStatusSynchronizer(
        session=db_session,
        library_repository=LibraryRepository(db_session),
        show_repository=ShowRepository(db_session),
        episode_repository=EpisodeRepository(db_session),
        progress_repository=EpisodeProgressRepository(db_session),
    )


def persist_library_entry(
    db_session: Session,
    *,
    user: User,
    show: Show,
    status: LibraryStatus = LibraryStatus.PLANNING,
    started_at: datetime | None = None,
    completed_at: datetime | None = None,
) -> LibraryEntry:
    """Persist a Library entry for Show status synchronization tests."""

    entry = LibraryEntry(
        user_id=user.id,
        show_id=show.id,
        status=status,
        started_at=started_at,
        completed_at=completed_at,
    )

    db_session.add(entry)
    db_session.flush()

    return entry


@pytest.fixture
def progress_repository() -> Mock:
    """Provide a mocked episode progress repository."""

    return Mock(spec=EpisodeProgressRepository)


@pytest.fixture
def episode_repository() -> Mock:
    """Provide a mocked episode repository."""

    return Mock(spec=EpisodeRepository)


@pytest.fixture
def season_repository() -> Mock:
    """Provide a mocked season repository."""

    return Mock(spec=SeasonRepository)


@pytest.fixture
def show_repository() -> Mock:
    """Provide a mocked show repository."""

    return Mock(spec=ShowRepository)


@pytest.fixture
def library_repository() -> Mock:
    """Provide a mocked Library repository."""

    repository = Mock(spec=LibraryRepository)
    repository.get_by_user_and_show.return_value = None

    return repository


@pytest.fixture
def progress_service(
    db_session: Session,
    progress_repository: Mock,
    episode_repository: Mock,
    season_repository: Mock,
    show_repository: Mock,
    watch_event_repository: Mock,
    show_status_synchronizer: Mock,
) -> EpisodeProgressService:
    """Provide an episode progress service using mocked repositories."""

    return EpisodeProgressService(
        session=db_session,
        progress_repository=progress_repository,
        episode_repository=episode_repository,
        season_repository=season_repository,
        show_repository=show_repository,
        watch_event_repository=watch_event_repository,
        show_status_synchronizer=show_status_synchronizer,
        today=lambda: date(2026, 8, 15),
    )


@pytest.fixture
def watch_event_repository() -> Mock:
    """Provide a mocked episode watch event repository."""

    repository = Mock(
        spec=EpisodeWatchEventRepository,
    )

    repository.count_by_user_and_episode.return_value = 0

    return repository


@pytest.fixture
def show_status_synchronizer() -> Mock:
    """Provide a mocked Show Library status synchronizer."""

    return Mock(spec=ShowLibraryStatusSynchronizer)


def test_mark_watched_returns_none_when_episode_does_not_exist(
    progress_service: EpisodeProgressService,
    progress_repository: Mock,
    episode_repository: Mock,
    watch_event_repository: Mock,
) -> None:
    """Return None when marking a missing episode as watched."""

    user_id = uuid4()
    episode_id = uuid4()

    episode_repository.get_by_id.return_value = None

    result = progress_service.mark_watched(
        user_id=user_id,
        episode_id=episode_id,
    )

    assert result is None

    progress_repository.get_by_user_and_episode.assert_not_called()
    progress_repository.add.assert_not_called()
    watch_event_repository.add.assert_not_called()


def test_mark_watched_creates_progress(
    db_session: Session,
    progress_service: EpisodeProgressService,
    progress_repository: Mock,
    episode_repository: Mock,
    watch_event_repository: Mock,
) -> None:
    """Create progress when an episode is marked watched for the first time."""

    user = persist_user(db_session)
    show = persist_show(db_session)
    season = persist_season(
        db_session,
        show=show,
    )
    episode = persist_episode(
        db_session,
        season=season,
    )

    episode.air_date = date(2026, 8, 1)
    db_session.flush()

    episode_repository.get_by_id.return_value = episode
    progress_repository.get_by_user_and_episode.return_value = None

    def add_progress(
        progress: EpisodeProgress,
    ) -> EpisodeProgress:
        db_session.add(progress)
        return progress

    progress_repository.add.side_effect = add_progress
    watch_event_repository.count_by_user_and_episode.return_value = 1
    result = progress_service.mark_watched(
        user_id=user.id,
        episode_id=episode.id,
    )

    assert result is not None
    assert result.episode_id == episode.id
    assert result.is_watched is True
    assert result.watched_at is not None
    assert result.watch_count == 1

    progress_repository.add.assert_called_once()

    created_progress = progress_repository.add.call_args.args[0]

    assert created_progress.user_id == user.id
    assert created_progress.episode_id == episode.id
    assert created_progress.is_watched is True


def test_mark_watched_uses_explicit_watched_at(
    db_session: Session,
    progress_service: EpisodeProgressService,
    progress_repository: Mock,
    episode_repository: Mock,
) -> None:
    """Store the explicitly supplied viewing date."""

    user = persist_user(db_session)
    show = persist_show(db_session)
    season = persist_season(
        db_session,
        show=show,
    )
    episode = persist_episode(
        db_session,
        season=season,
    )

    episode.air_date = date(2026, 8, 1)
    db_session.flush()

    episode_repository.get_by_id.return_value = episode
    progress_repository.get_by_user_and_episode.return_value = None

    def add_progress(
        progress: EpisodeProgress,
    ) -> EpisodeProgress:
        db_session.add(progress)
        return progress

    progress_repository.add.side_effect = add_progress

    watched_at = datetime(
        2026,
        7,
        20,
        21,
        30,
        tzinfo=UTC,
    )

    result = progress_service.mark_watched(
        user_id=user.id,
        episode_id=episode.id,
        watched_at=watched_at,
    )

    assert result is not None
    assert result.watched_at is not None
    assert as_utc(result.watched_at) == watched_at


def test_mark_watched_normalizes_naive_watched_at_to_utc(
    db_session: Session,
    progress_service: EpisodeProgressService,
    progress_repository: Mock,
    episode_repository: Mock,
) -> None:
    """Interpret a timezone-naive viewing date as UTC."""

    user = persist_user(db_session)
    show = persist_show(db_session)
    season = persist_season(
        db_session,
        show=show,
    )
    episode = persist_episode(
        db_session,
        season=season,
    )

    episode.air_date = date(2026, 8, 1)
    db_session.flush()

    episode_repository.get_by_id.return_value = episode
    progress_repository.get_by_user_and_episode.return_value = None

    def add_progress(
        progress: EpisodeProgress,
    ) -> EpisodeProgress:
        db_session.add(progress)
        return progress

    progress_repository.add.side_effect = add_progress

    watched_at = datetime(
        2026,
        7,
        20,
        21,
        30,
    )

    result = progress_service.mark_watched(
        user_id=user.id,
        episode_id=episode.id,
        watched_at=watched_at,
    )

    assert result is not None
    assert result.watched_at is not None

    assert as_utc(result.watched_at) == datetime(
        2026,
        7,
        20,
        21,
        30,
        tzinfo=UTC,
    )


def test_mark_watched_updates_existing_unwatched_progress(
    db_session: Session,
    progress_service: EpisodeProgressService,
    progress_repository: Mock,
    episode_repository: Mock,
    watch_event_repository: Mock,
) -> None:
    """Mark an existing unwatched progress entry as watched."""

    user = persist_user(db_session)
    show = persist_show(db_session)
    season = persist_season(
        db_session,
        show=show,
    )
    episode = persist_episode(
        db_session,
        season=season,
    )

    episode.air_date = date(2026, 8, 1)
    db_session.flush()

    episode_repository.get_by_id.return_value = episode

    progress = EpisodeProgress(
        user_id=user.id,
        episode_id=episode.id,
        is_watched=False,
        watched_at=None,
    )

    db_session.add(progress)
    db_session.flush()

    progress_repository.get_by_user_and_episode.return_value = progress
    watch_event_repository.count_by_user_and_episode.return_value = 1
    result = progress_service.mark_watched(
        user_id=user.id,
        episode_id=episode.id,
    )

    assert result is not None
    assert result.id == progress.id
    assert result.episode_id == episode.id
    assert result.is_watched is True
    assert result.watched_at is not None
    assert result.watch_count == 1

    progress_repository.add.assert_not_called()


def test_mark_watched_updates_existing_watched_at(
    db_session: Session,
    progress_service: EpisodeProgressService,
    progress_repository: Mock,
    episode_repository: Mock,
    watch_event_repository: Mock,
) -> None:
    """Update the viewing date when an already watched episode is marked again."""

    user = persist_user(db_session)

    show = persist_show(db_session)

    season = persist_season(
        db_session,
        show=show,
    )

    episode = persist_episode(
        db_session,
        season=season,
    )

    episode.air_date = date(2026, 8, 1)
    db_session.flush()

    episode_repository.get_by_id.return_value = episode

    original_watched_at = datetime(
        2026,
        7,
        10,
        20,
        0,
        tzinfo=UTC,
    )

    progress = EpisodeProgress(
        user_id=user.id,
        episode_id=episode.id,
        is_watched=True,
        watched_at=original_watched_at,
    )

    db_session.add(progress)
    db_session.flush()

    progress_repository.get_by_user_and_episode.return_value = progress

    rewatched_at = datetime(
        2026,
        8,
        11,
        20,
        15,
        tzinfo=UTC,
    )
    watch_event_repository.count_by_user_and_episode.return_value = 2

    result = progress_service.mark_watched(
        user_id=user.id,
        episode_id=episode.id,
        watched_at=rewatched_at,
    )

    assert result is not None
    assert result.id == progress.id
    assert result.episode_id == episode.id
    assert result.is_watched is True
    assert result.watched_at is not None
    assert result.watch_count == 2

    assert as_utc(result.watched_at) == rewatched_at

    assert as_utc(result.watched_at) != original_watched_at

    progress_repository.add.assert_not_called()


def test_mark_unwatched_returns_none_when_episode_does_not_exist(
    progress_service: EpisodeProgressService,
    progress_repository: Mock,
    episode_repository: Mock,
) -> None:
    """Return None when marking a missing episode as unwatched."""

    user_id = uuid4()
    episode_id = uuid4()

    episode_repository.get_by_id.return_value = None

    result = progress_service.mark_unwatched(
        user_id=user_id,
        episode_id=episode_id,
    )

    assert result is None

    progress_repository.get_by_user_and_episode.assert_not_called()


def test_mark_unwatched_creates_unwatched_progress_when_missing(
    db_session: Session,
    progress_service: EpisodeProgressService,
    progress_repository: Mock,
    episode_repository: Mock,
) -> None:
    """Create an unwatched progress entry when none exists."""

    user = persist_user(db_session)
    show = persist_show(db_session)
    season = persist_season(
        db_session,
        show=show,
    )
    episode = persist_episode(
        db_session,
        season=season,
    )

    episode_repository.get_by_id.return_value = episode
    progress_repository.get_by_user_and_episode.return_value = None

    def add_progress(
        progress: EpisodeProgress,
    ) -> EpisodeProgress:
        db_session.add(progress)
        return progress

    progress_repository.add.side_effect = add_progress

    result = progress_service.mark_unwatched(
        user_id=user.id,
        episode_id=episode.id,
    )

    assert result is not None
    assert result.episode_id == episode.id
    assert result.is_watched is False
    assert result.watched_at is None
    assert result.watch_count == 0

    progress_repository.add.assert_called_once()

    created_progress = progress_repository.add.call_args.args[0]

    assert created_progress.user_id == user.id
    assert created_progress.episode_id == episode.id
    assert created_progress.is_watched is False
    assert created_progress.watched_at is None


def test_mark_unwatched_clears_existing_progress(
    db_session: Session,
    progress_service: EpisodeProgressService,
    progress_repository: Mock,
    episode_repository: Mock,
) -> None:
    """Clear watched state and viewing date from existing progress."""

    user = persist_user(db_session)
    show = persist_show(db_session)
    season = persist_season(
        db_session,
        show=show,
    )
    episode = persist_episode(
        db_session,
        season=season,
    )

    episode_repository.get_by_id.return_value = episode

    progress = EpisodeProgress(
        user_id=user.id,
        episode_id=episode.id,
        is_watched=True,
        watched_at=datetime.now(UTC),
    )

    db_session.add(progress)
    db_session.flush()

    progress_repository.get_by_user_and_episode.return_value = progress

    result = progress_service.mark_unwatched(
        user_id=user.id,
        episode_id=episode.id,
    )

    assert result is not None
    assert result.id == progress.id
    assert result.episode_id == episode.id
    assert result.is_watched is False
    assert result.watched_at is None
    assert result.watch_count == 0


def test_get_season_progress_returns_none_when_season_does_not_exist(
    progress_service: EpisodeProgressService,
    season_repository: Mock,
    episode_repository: Mock,
    progress_repository: Mock,
) -> None:
    """Return None when calculating progress for a missing season."""

    user_id = uuid4()
    season_id = uuid4()

    season_repository.get_by_id.return_value = None

    result = progress_service.get_season_progress(
        user_id=user_id,
        season_id=season_id,
    )

    assert result is None

    episode_repository.count_by_season_id.assert_not_called()
    episode_repository.count_aired_by_season_id.assert_not_called()
    progress_repository.count_watched_for_season.assert_not_called()
    progress_repository.count_watched_aired_for_season.assert_not_called()


def test_get_show_progress_returns_none_when_show_does_not_exist(
    progress_service: EpisodeProgressService,
    show_repository: Mock,
    episode_repository: Mock,
    progress_repository: Mock,
) -> None:
    """Return None when calculating progress for a missing TV series."""

    user_id = uuid4()
    show_id = uuid4()

    show_repository.get_by_id.return_value = None

    result = progress_service.get_show_progress(
        user_id=user_id,
        show_id=show_id,
    )

    assert result is None

    episode_repository.count_regular_by_show_id.assert_not_called()
    episode_repository.count_aired_by_show_id.assert_not_called()
    progress_repository.count_watched_for_show.assert_not_called()
    progress_repository.count_watched_aired_for_show.assert_not_called()


def test_get_next_episode_returns_none_when_show_does_not_exist(
    progress_service: EpisodeProgressService,
    show_repository: Mock,
    progress_repository: Mock,
) -> None:
    """Return None when requesting the next episode of a missing show."""

    user_id = uuid4()
    show_id = uuid4()

    show_repository.get_by_id.return_value = None

    result = progress_service.get_next_episode(
        user_id=user_id,
        show_id=show_id,
    )

    assert result is None

    progress_repository.get_next_unwatched_for_show.assert_not_called()


def test_get_next_episode_returns_next_unwatched_episode(
    progress_service: EpisodeProgressService,
    show_repository: Mock,
    progress_repository: Mock,
) -> None:
    """Return the next unwatched episode of an existing TV series."""

    user_id = uuid4()
    show_id = uuid4()
    episode_id = uuid4()
    season_id = uuid4()

    show_repository.get_by_id.return_value = SimpleNamespace(
        id=show_id,
    )

    episode = SimpleNamespace(
        id=episode_id,
        season_id=season_id,
        tmdb_id=2103,
        episode_number=3,
        title="Episode 3",
        overview=None,
        air_date=None,
        runtime=55,
        vote_average=8.4,
        vote_count=20,
        tmdb_still_path=None,
        local_still_path=None,
    )

    progress_repository.get_next_unwatched_for_show.return_value = episode

    result = progress_service.get_next_episode(
        user_id=user_id,
        show_id=show_id,
    )

    assert result is not None
    assert result.show_id == show_id
    assert result.next_episode is not None
    assert result.next_episode.id == episode_id
    assert result.next_episode.episode_number == 3

    progress_repository.get_next_unwatched_for_show.assert_called_once_with(
        user_id=user_id,
        show_id=show_id,
        as_of=date(2026, 8, 15),
    )


def test_get_next_episode_returns_null_when_show_is_complete(
    progress_service: EpisodeProgressService,
    show_repository: Mock,
    progress_repository: Mock,
) -> None:
    """Return a response without a next episode when all episodes are watched."""

    user_id = uuid4()
    show_id = uuid4()

    show_repository.get_by_id.return_value = SimpleNamespace(
        id=show_id,
    )
    progress_repository.get_next_unwatched_for_show.return_value = None

    result = progress_service.get_next_episode(
        user_id=user_id,
        show_id=show_id,
    )

    assert result is not None
    assert result.show_id == show_id
    assert result.next_episode is None


def test_get_season_progress_calculates_progress(
    progress_service: EpisodeProgressService,
    season_repository: Mock,
    episode_repository: Mock,
    progress_repository: Mock,
) -> None:
    """Calculate overall and aired progress for a season."""

    user_id = uuid4()
    season_id = uuid4()

    season_repository.get_by_id.return_value = SimpleNamespace(
        id=season_id,
    )

    episode_repository.count_by_season_id.return_value = 10
    progress_repository.count_watched_for_season.return_value = 5

    episode_repository.count_aired_by_season_id.return_value = 5
    progress_repository.count_watched_aired_for_season.return_value = 5

    result = progress_service.get_season_progress(
        user_id=user_id,
        season_id=season_id,
    )

    assert result is not None
    assert result.season_id == season_id

    assert result.watched_episodes == 5
    assert result.total_episodes == 10
    assert result.progress_percentage == 50.0

    assert result.aired_episodes == 5
    assert result.watched_aired_episodes == 5
    assert result.aired_progress_percentage == 100.0
    assert result.caught_up is True


def test_get_season_progress_is_not_caught_up_when_aired_episode_is_unwatched(
    progress_service: EpisodeProgressService,
    season_repository: Mock,
    episode_repository: Mock,
    progress_repository: Mock,
) -> None:
    """Return false when not every aired episode has been watched."""

    user_id = uuid4()
    season_id = uuid4()

    season_repository.get_by_id.return_value = SimpleNamespace(
        id=season_id,
    )

    episode_repository.count_by_season_id.return_value = 10
    progress_repository.count_watched_for_season.return_value = 3

    episode_repository.count_aired_by_season_id.return_value = 5
    progress_repository.count_watched_aired_for_season.return_value = 3

    result = progress_service.get_season_progress(
        user_id=user_id,
        season_id=season_id,
    )

    assert result is not None
    assert result.progress_percentage == 30.0
    assert result.aired_progress_percentage == 60.0
    assert result.caught_up is False


def test_get_season_progress_handles_empty_season(
    progress_service: EpisodeProgressService,
    season_repository: Mock,
    episode_repository: Mock,
    progress_repository: Mock,
) -> None:
    """Return zero progress for a season without episodes."""

    user_id = uuid4()
    season_id = uuid4()

    season_repository.get_by_id.return_value = SimpleNamespace(
        id=season_id,
    )

    episode_repository.count_by_season_id.return_value = 0
    progress_repository.count_watched_for_season.return_value = 0

    episode_repository.count_aired_by_season_id.return_value = 0
    progress_repository.count_watched_aired_for_season.return_value = 0

    result = progress_service.get_season_progress(
        user_id=user_id,
        season_id=season_id,
    )

    assert result is not None

    assert result.watched_episodes == 0
    assert result.total_episodes == 0
    assert result.progress_percentage == 0.0

    assert result.aired_episodes == 0
    assert result.watched_aired_episodes == 0
    assert result.aired_progress_percentage == 0.0

    assert result.caught_up is False


def test_get_show_progress_calculates_progress(
    progress_service: EpisodeProgressService,
    show_repository: Mock,
    episode_repository: Mock,
    progress_repository: Mock,
) -> None:
    """Calculate overall and aired progress for a TV series."""

    user_id = uuid4()
    show_id = uuid4()

    show_repository.get_by_id.return_value = SimpleNamespace(
        id=show_id,
    )

    episode_repository.count_regular_by_show_id.return_value = 10
    progress_repository.count_watched_for_show.return_value = 5

    episode_repository.count_aired_by_show_id.return_value = 5
    progress_repository.count_watched_aired_for_show.return_value = 5

    result = progress_service.get_show_progress(
        user_id=user_id,
        show_id=show_id,
    )

    assert result is not None

    assert result.show_id == show_id

    assert result.watched_episodes == 5
    assert result.total_episodes == 10
    assert result.progress_percentage == 50.0

    assert result.aired_episodes == 5
    assert result.watched_aired_episodes == 5
    assert result.aired_progress_percentage == 100.0

    assert result.caught_up is True


def test_get_show_progress_is_not_caught_up_when_aired_episode_is_unwatched(
    progress_service: EpisodeProgressService,
    show_repository: Mock,
    episode_repository: Mock,
    progress_repository: Mock,
) -> None:
    """Return false when not every aired regular episode was watched."""

    user_id = uuid4()
    show_id = uuid4()

    show_repository.get_by_id.return_value = SimpleNamespace(
        id=show_id,
    )

    episode_repository.count_regular_by_show_id.return_value = 10
    progress_repository.count_watched_for_show.return_value = 3

    episode_repository.count_aired_by_show_id.return_value = 5
    progress_repository.count_watched_aired_for_show.return_value = 3

    result = progress_service.get_show_progress(
        user_id=user_id,
        show_id=show_id,
    )

    assert result is not None
    assert result.progress_percentage == 30.0
    assert result.aired_progress_percentage == 60.0
    assert result.caught_up is False


def test_get_show_progress_handles_show_without_episodes(
    progress_service: EpisodeProgressService,
    show_repository: Mock,
    episode_repository: Mock,
    progress_repository: Mock,
) -> None:
    """Return zero progress when no regular episodes exist."""

    user_id = uuid4()
    show_id = uuid4()

    show_repository.get_by_id.return_value = SimpleNamespace(
        id=show_id,
    )

    episode_repository.count_regular_by_show_id.return_value = 0
    progress_repository.count_watched_for_show.return_value = 0

    episode_repository.count_aired_by_show_id.return_value = 0
    progress_repository.count_watched_aired_for_show.return_value = 0

    result = progress_service.get_show_progress(
        user_id=user_id,
        show_id=show_id,
    )

    assert result is not None
    assert result.watched_episodes == 0
    assert result.total_episodes == 0
    assert result.progress_percentage == 0.0

    assert result.aired_episodes == 0
    assert result.watched_aired_episodes == 0
    assert result.aired_progress_percentage == 0.0

    assert result.caught_up is False


def test_get_next_upcoming_episode_returns_none_when_show_does_not_exist(
    progress_service: EpisodeProgressService,
    show_repository: Mock,
    progress_repository: Mock,
) -> None:
    """Return None when requesting upcoming episode for a missing show."""

    show_id = uuid4()

    show_repository.get_by_id.return_value = None

    result = progress_service.get_next_upcoming_episode(
        show_id=show_id,
    )

    assert result is None

    progress_repository.get_next_upcoming_for_show.assert_not_called()


def test_get_next_upcoming_episode_returns_future_episode(
    progress_service: EpisodeProgressService,
    show_repository: Mock,
    progress_repository: Mock,
) -> None:
    """Return the next future regular episode."""

    show_id = uuid4()
    episode_id = uuid4()
    season_id = uuid4()

    show_repository.get_by_id.return_value = SimpleNamespace(
        id=show_id,
    )

    episode = SimpleNamespace(
        id=episode_id,
        season_id=season_id,
        tmdb_id=2106,
        episode_number=6,
        title="Episode 6",
        overview=None,
        air_date=date(2026, 8, 2),
        runtime=55,
        vote_average=0.0,
        vote_count=0,
        tmdb_still_path=None,
        local_still_path=None,
    )

    progress_repository.get_next_upcoming_for_show.return_value = episode

    result = progress_service.get_next_upcoming_episode(
        show_id=show_id,
    )

    assert result is not None
    assert result.show_id == show_id
    assert result.next_episode is not None
    assert result.next_episode.id == episode_id

    progress_repository.get_next_upcoming_for_show.assert_called_once_with(
        show_id=show_id,
        after=date(2026, 8, 15),
    )


def test_get_next_upcoming_episode_returns_null_when_none_is_known(
    progress_service: EpisodeProgressService,
    show_repository: Mock,
    progress_repository: Mock,
) -> None:
    """Return a null episode when no future regular episode is known."""

    show_id = uuid4()

    show_repository.get_by_id.return_value = SimpleNamespace(
        id=show_id,
    )

    progress_repository.get_next_upcoming_for_show.return_value = None

    result = progress_service.get_next_upcoming_episode(
        show_id=show_id,
    )

    assert result is not None
    assert result.show_id == show_id
    assert result.next_episode is None


def test_get_season_progress_calculates_percentage(
    progress_service: EpisodeProgressService,
    season_repository: Mock,
    episode_repository: Mock,
    progress_repository: Mock,
) -> None:
    """Calculate overall and aired progress for a season."""

    user_id = uuid4()
    season_id = uuid4()

    season_repository.get_by_id.return_value = SimpleNamespace(
        id=season_id,
    )

    episode_repository.count_by_season_id.return_value = 10
    progress_repository.count_watched_for_season.return_value = 5

    episode_repository.count_aired_by_season_id.return_value = 5
    progress_repository.count_watched_aired_for_season.return_value = 5

    result = progress_service.get_season_progress(
        user_id=user_id,
        season_id=season_id,
    )

    assert result is not None

    assert result.season_id == season_id

    assert result.watched_episodes == 5
    assert result.total_episodes == 10
    assert result.progress_percentage == 50.0

    assert result.aired_episodes == 5
    assert result.watched_aired_episodes == 5
    assert result.aired_progress_percentage == 100.0

    assert result.caught_up is True


def test_get_show_progress_calculates_percentage(
    progress_service: EpisodeProgressService,
    show_repository: Mock,
    episode_repository: Mock,
    progress_repository: Mock,
) -> None:
    """Calculate overall and aired progress for a TV series."""

    user_id = uuid4()
    show_id = uuid4()

    show_repository.get_by_id.return_value = SimpleNamespace(
        id=show_id,
    )

    episode_repository.count_regular_by_show_id.return_value = 10
    progress_repository.count_watched_for_show.return_value = 5

    episode_repository.count_aired_by_show_id.return_value = 5
    progress_repository.count_watched_aired_for_show.return_value = 5

    result = progress_service.get_show_progress(
        user_id=user_id,
        show_id=show_id,
    )

    assert result is not None

    assert result.show_id == show_id

    assert result.watched_episodes == 5
    assert result.total_episodes == 10
    assert result.progress_percentage == 50.0

    assert result.aired_episodes == 5
    assert result.watched_aired_episodes == 5
    assert result.aired_progress_percentage == 100.0

    assert result.caught_up is True


def make_service(
    *,
    session: Mock,
    progress_repository: Mock,
    episode_repository: Mock,
    season_repository: Mock,
    show_repository: Mock,
    watch_event_repository: Mock | None = None,
    show_status_synchronizer: Mock | None = None,
) -> EpisodeProgressService:
    """Build an EpisodeProgressService with mocked repositories."""

    return EpisodeProgressService(
        session=session,
        progress_repository=progress_repository,
        episode_repository=episode_repository,
        season_repository=season_repository,
        show_repository=show_repository,
        watch_event_repository=(watch_event_repository or Mock(spec=EpisodeWatchEventRepository)),
        show_status_synchronizer=(
            show_status_synchronizer or Mock(spec=ShowLibraryStatusSynchronizer)
        ),
    )


def test_get_show_seasons_progress_returns_none_when_show_does_not_exist() -> None:
    """Return None when the requested TV series does not exist."""

    session = Mock(spec=Session)
    progress_repository = Mock(spec=EpisodeProgressRepository)
    episode_repository = Mock(spec=EpisodeRepository)
    season_repository = Mock(spec=SeasonRepository)
    show_repository = Mock(spec=ShowRepository)

    show_repository.get_by_id.return_value = None

    service = make_service(
        session=session,
        progress_repository=progress_repository,
        episode_repository=episode_repository,
        season_repository=season_repository,
        show_repository=show_repository,
    )

    result = service.get_show_seasons_progress(
        user_id=uuid4(),
        show_id=uuid4(),
    )

    assert result is None

    season_repository.list_by_show_id.assert_not_called()
    episode_repository.get_counts_by_show_id.assert_not_called()
    progress_repository.get_watched_counts_by_show_id.assert_not_called()


def test_get_show_seasons_progress_returns_empty_list_without_seasons() -> None:
    """Return an empty result when the TV series has no local Seasons."""

    session = Mock(spec=Session)
    progress_repository = Mock(spec=EpisodeProgressRepository)
    episode_repository = Mock(spec=EpisodeRepository)
    season_repository = Mock(spec=SeasonRepository)
    show_repository = Mock(spec=ShowRepository)

    show_id = uuid4()

    show_repository.get_by_id.return_value = SimpleNamespace(
        id=show_id,
    )

    season_repository.list_by_show_id.return_value = []

    service = make_service(
        session=session,
        progress_repository=progress_repository,
        episode_repository=episode_repository,
        season_repository=season_repository,
        show_repository=show_repository,
    )

    result = service.get_show_seasons_progress(
        user_id=uuid4(),
        show_id=show_id,
    )

    assert result == []

    episode_repository.get_counts_by_show_id.assert_not_called()
    progress_repository.get_watched_counts_by_show_id.assert_not_called()


def test_get_show_seasons_progress_calculates_all_seasons() -> None:
    """Calculate progress for every locally stored Season in one batch."""

    session = Mock(spec=Session)
    progress_repository = Mock(spec=EpisodeProgressRepository)
    episode_repository = Mock(spec=EpisodeRepository)
    season_repository = Mock(spec=SeasonRepository)
    show_repository = Mock(spec=ShowRepository)

    user_id = uuid4()
    show_id = uuid4()

    first_season_id = uuid4()
    second_season_id = uuid4()
    third_season_id = uuid4()

    show_repository.get_by_id.return_value = SimpleNamespace(
        id=show_id,
    )

    season_repository.list_by_show_id.return_value = [
        SimpleNamespace(
            id=first_season_id,
            season_number=1,
        ),
        SimpleNamespace(
            id=second_season_id,
            season_number=2,
        ),
        SimpleNamespace(
            id=third_season_id,
            season_number=3,
        ),
    ]

    episode_repository.get_counts_by_show_id.return_value = {
        first_season_id: (10, 10),
        second_season_id: (8, 4),
    }

    progress_repository.get_watched_counts_by_show_id.return_value = {
        first_season_id: (10, 10),
        second_season_id: (2, 2),
    }

    service = make_service(
        session=session,
        progress_repository=progress_repository,
        episode_repository=episode_repository,
        season_repository=season_repository,
        show_repository=show_repository,
    )

    result = service.get_show_seasons_progress(
        user_id=user_id,
        show_id=show_id,
    )

    assert result is not None
    assert len(result) == 3

    first = result[0]

    assert first.season_id == first_season_id
    assert first.watched_episodes == 10
    assert first.total_episodes == 10
    assert first.progress_percentage == 100.0
    assert first.aired_episodes == 10
    assert first.watched_aired_episodes == 10
    assert first.aired_progress_percentage == 100.0
    assert first.caught_up is True

    second = result[1]

    assert second.season_id == second_season_id
    assert second.watched_episodes == 2
    assert second.total_episodes == 8
    assert second.progress_percentage == 25.0
    assert second.aired_episodes == 4
    assert second.watched_aired_episodes == 2
    assert second.aired_progress_percentage == 50.0
    assert second.caught_up is False

    third = result[2]

    assert third.season_id == third_season_id
    assert third.watched_episodes == 0
    assert third.total_episodes == 0
    assert third.progress_percentage == 0.0
    assert third.aired_episodes == 0
    assert third.watched_aired_episodes == 0
    assert third.aired_progress_percentage == 0.0
    assert third.caught_up is False

    episode_repository.get_counts_by_show_id.assert_called_once()

    progress_repository.get_watched_counts_by_show_id.assert_called_once()


def test_get_episode_progress_for_season_returns_entries(
    db_session: Session,
    progress_repository: Mock,
    episode_repository: Mock,
    season_repository: Mock,
    show_repository: Mock,
    watch_event_repository: Mock,
    show_status_synchronizer: Mock,
) -> None:
    """Return progress enriched with historical watch counts."""

    user_id = uuid4()
    season_id = uuid4()

    first_episode_id = uuid4()
    second_episode_id = uuid4()

    first_progress = EpisodeProgress(
        user_id=user_id,
        episode_id=first_episode_id,
        is_watched=True,
        watched_at=datetime(
            2026,
            8,
            10,
            20,
            30,
            tzinfo=UTC,
        ),
    )

    second_progress = EpisodeProgress(
        user_id=user_id,
        episode_id=second_episode_id,
        is_watched=False,
        watched_at=None,
    )

    # These objects do not need to be persisted.
    # The repository is mocked and returns them directly.
    first_progress.id = uuid4()
    second_progress.id = uuid4()

    season_repository.get_by_id.return_value = SimpleNamespace(
        id=season_id,
    )

    progress_repository.list_by_user_and_season.return_value = [
        first_progress,
        second_progress,
    ]

    watch_event_repository.get_counts_by_user_and_episode_ids.return_value = {
        first_episode_id: 3,
        second_episode_id: 1,
    }

    service = EpisodeProgressService(
        session=db_session,
        progress_repository=progress_repository,
        episode_repository=episode_repository,
        season_repository=season_repository,
        show_repository=show_repository,
        watch_event_repository=watch_event_repository,
        show_status_synchronizer=show_status_synchronizer,
    )

    result = service.get_episode_progress_for_season(
        user_id=user_id,
        season_id=season_id,
    )

    assert result is not None
    assert len(result) == 2

    assert result[0].id == first_progress.id
    assert result[0].episode_id == first_episode_id
    assert result[0].is_watched is True
    assert result[0].watched_at == first_progress.watched_at
    assert result[0].watch_count == 3

    assert result[1].id == second_progress.id
    assert result[1].episode_id == second_episode_id
    assert result[1].is_watched is False
    assert result[1].watched_at is None
    assert result[1].watch_count == 1

    watch_event_repository.get_counts_by_user_and_episode_ids.assert_called_once_with(
        user_id=user_id,
        episode_ids=[
            first_episode_id,
            second_episode_id,
        ],
    )


def test_get_episode_progress_for_season_skips_watch_count_query_when_empty(
    db_session: Session,
    progress_repository: Mock,
    episode_repository: Mock,
    season_repository: Mock,
    show_repository: Mock,
    watch_event_repository: Mock,
    show_status_synchronizer: Mock,
) -> None:
    """Do not query historical counts when the Season has no progress."""

    user_id = uuid4()
    season_id = uuid4()

    season_repository.get_by_id.return_value = SimpleNamespace(
        id=season_id,
    )

    progress_repository.list_by_user_and_season.return_value = []

    service = EpisodeProgressService(
        session=db_session,
        progress_repository=progress_repository,
        episode_repository=episode_repository,
        season_repository=season_repository,
        show_repository=show_repository,
        watch_event_repository=watch_event_repository,
        show_status_synchronizer=show_status_synchronizer,
    )

    result = service.get_episode_progress_for_season(
        user_id=user_id,
        season_id=season_id,
    )

    assert result == []

    watch_event_repository.get_counts_by_user_and_episode_ids.assert_not_called()


def test_get_episode_progress_for_season_returns_none_when_season_missing(
    db_session: Session,
    progress_repository: Mock,
    episode_repository: Mock,
    season_repository: Mock,
    show_repository: Mock,
    show_status_synchronizer: Mock,
) -> None:
    """Return None when the requested season does not exist."""

    user_id = uuid4()
    season_id = uuid4()

    season_repository.get_by_id.return_value = None

    watch_event_repository = Mock(spec=EpisodeWatchEventRepository)
    service = EpisodeProgressService(
        session=db_session,
        progress_repository=progress_repository,
        episode_repository=episode_repository,
        season_repository=season_repository,
        show_repository=show_repository,
        watch_event_repository=watch_event_repository,
        show_status_synchronizer=show_status_synchronizer,
    )

    result = service.get_episode_progress_for_season(
        user_id=user_id,
        season_id=season_id,
    )

    assert result is None

    season_repository.get_by_id.assert_called_once_with(
        season_id,
    )

    progress_repository.list_by_user_and_season.assert_not_called()


def test_mark_watched_records_every_watch_event_for_rewatch(
    db_session: Session,
    progress_service: EpisodeProgressService,
    progress_repository: Mock,
    episode_repository: Mock,
    watch_event_repository: Mock,
) -> None:
    """Preserve every viewing event while keeping current progress up to date."""

    user = persist_user(db_session)

    show = persist_show(db_session)

    season = persist_season(
        db_session,
        show=show,
    )

    episode = persist_episode(
        db_session,
        season=season,
    )

    episode.air_date = date(2026, 8, 1)
    db_session.flush()

    episode_repository.get_by_id.return_value = episode
    progress_repository.get_by_user_and_episode.return_value = None

    created_progress: EpisodeProgress | None = None

    def add_progress(
        progress: EpisodeProgress,
    ) -> EpisodeProgress:
        nonlocal created_progress

        created_progress = progress
        db_session.add(progress)

        return progress

    def add_watch_event(
        event: EpisodeWatchEvent,
    ) -> EpisodeWatchEvent:
        db_session.add(event)

        return event

    progress_repository.add.side_effect = add_progress
    watch_event_repository.add.side_effect = add_watch_event
    watch_event_repository.count_by_user_and_episode.side_effect = [
        1,
        2,
    ]

    first_watched_at = datetime(
        2026,
        7,
        20,
        21,
        30,
        tzinfo=UTC,
    )

    first_result = progress_service.mark_watched(
        user_id=user.id,
        episode_id=episode.id,
        watched_at=first_watched_at,
    )

    assert first_result is not None
    assert first_result.watch_count == 1
    assert created_progress is not None

    progress_repository.get_by_user_and_episode.return_value = created_progress

    # From now on the same EpisodeProgress represents the episode's
    # current watched state.

    second_watched_at = datetime(
        2026,
        8,
        11,
        20,
        15,
        tzinfo=UTC,
    )

    result = progress_service.mark_watched(
        user_id=user.id,
        episode_id=episode.id,
        watched_at=second_watched_at,
    )

    assert result is not None
    assert result.id == created_progress.id
    assert result.episode_id == episode.id
    assert result.is_watched is True
    assert result.watched_at is not None
    assert result.watch_count == 2
    assert as_utc(result.watched_at) == second_watched_at

    # EpisodeProgress represents the latest/current viewing state.
    assert as_utc(result.watched_at) == second_watched_at

    # Rewatch must not create another EpisodeProgress.
    progress_repository.add.assert_called_once()

    # Every watch must create its own historical event.
    assert watch_event_repository.add.call_count == 2

    events = list(
        db_session.scalars(
            select(EpisodeWatchEvent)
            .where(
                EpisodeWatchEvent.user_id == user.id,
                EpisodeWatchEvent.episode_id == episode.id,
            )
            .order_by(
                EpisodeWatchEvent.watched_at.asc(),
            )
        ).all()
    )

    assert len(events) == 2

    assert events[0].user_id == user.id
    assert events[0].episode_id == episode.id
    assert as_utc(events[0].watched_at) == first_watched_at

    assert events[1].user_id == user.id
    assert events[1].episode_id == episode.id
    assert as_utc(events[1].watched_at) == second_watched_at


def test_mark_watched_rejects_future_episode(
    db_session: Session,
    progress_service: EpisodeProgressService,
    progress_repository: Mock,
    episode_repository: Mock,
    watch_event_repository: Mock,
) -> None:
    """Do not allow an Episode to be watched before its air date."""

    show = persist_show(db_session)

    season = persist_season(
        db_session,
        show=show,
    )

    episode = persist_episode(
        db_session,
        season=season,
    )

    episode.air_date = date(2026, 8, 16)

    episode_repository.get_by_id.return_value = episode

    with pytest.raises(
        EpisodeNotWatchableError,
        match="Episode has not aired yet",
    ):
        progress_service.mark_watched(
            user_id=uuid4(),
            episode_id=episode.id,
        )

    progress_repository.get_by_user_and_episode.assert_not_called()
    progress_repository.add.assert_not_called()
    watch_event_repository.add.assert_not_called()


def test_mark_watched_rejects_episode_without_air_date(
    db_session: Session,
    progress_service: EpisodeProgressService,
    progress_repository: Mock,
    episode_repository: Mock,
    watch_event_repository: Mock,
) -> None:
    """Do not infer that an Episode has aired when its air date is unknown."""

    show = persist_show(db_session)

    season = persist_season(
        db_session,
        show=show,
    )

    episode = persist_episode(
        db_session,
        season=season,
    )

    episode.air_date = None

    episode_repository.get_by_id.return_value = episode

    with pytest.raises(
        EpisodeNotWatchableError,
        match="Episode has not aired yet",
    ):
        progress_service.mark_watched(
            user_id=uuid4(),
            episode_id=episode.id,
        )

    progress_repository.get_by_user_and_episode.assert_not_called()
    progress_repository.add.assert_not_called()
    watch_event_repository.add.assert_not_called()


def test_mark_watched_allows_episode_airing_today(
    db_session: Session,
    progress_service: EpisodeProgressService,
    progress_repository: Mock,
    episode_repository: Mock,
    watch_event_repository: Mock,
) -> None:
    """Allow an Episode dated Today because no air time is known."""

    user = persist_user(db_session)

    show = persist_show(db_session)

    season = persist_season(
        db_session,
        show=show,
    )

    episode = persist_episode(
        db_session,
        season=season,
    )

    episode.air_date = date(2026, 8, 15)

    episode_repository.get_by_id.return_value = episode
    progress_repository.get_by_user_and_episode.return_value = None

    def add_progress(progress: EpisodeProgress) -> EpisodeProgress:
        db_session.add(progress)

        return progress

    def add_watch_event(
        event: EpisodeWatchEvent,
    ) -> EpisodeWatchEvent:
        db_session.add(event)

        return event

    progress_repository.add.side_effect = add_progress
    watch_event_repository.add.side_effect = add_watch_event

    result = progress_service.mark_watched(
        user_id=user.id,
        episode_id=episode.id,
    )

    assert result is not None
    assert result.is_watched is True

    progress_repository.add.assert_called_once()
    watch_event_repository.add.assert_called_once()


def test_mark_season_watched_returns_none_when_season_does_not_exist(
    progress_service: EpisodeProgressService,
    season_repository: Mock,
    episode_repository: Mock,
    progress_repository: Mock,
    watch_event_repository: Mock,
) -> None:
    """Return None when the requested Season does not exist."""

    user_id = uuid4()
    season_id = uuid4()

    season_repository.get_by_id.return_value = None

    result = progress_service.mark_season_watched(
        user_id=user_id,
        season_id=season_id,
    )

    assert result is None

    season_repository.get_by_id.assert_called_once_with(
        season_id,
    )

    episode_repository.list_by_season_id.assert_not_called()
    progress_repository.list_by_user_and_season.assert_not_called()
    watch_event_repository.add.assert_not_called()


def test_mark_season_watched_marks_only_aired_unwatched_episodes(
    progress_service: EpisodeProgressService,
    season_repository: Mock,
    episode_repository: Mock,
    progress_repository: Mock,
    watch_event_repository: Mock,
) -> None:
    """Mark only aired Episodes that are not already watched."""

    user_id = uuid4()
    season_id = uuid4()
    show_id = uuid4()

    season_repository.get_by_id.return_value = SimpleNamespace(
        id=season_id,
        show_id=show_id,
    )

    already_watched_episode = SimpleNamespace(
        id=uuid4(),
        air_date=date(2026, 8, 10),
    )

    unwatched_episode = SimpleNamespace(
        id=uuid4(),
        air_date=date(2026, 8, 11),
    )

    future_episode = SimpleNamespace(
        id=uuid4(),
        air_date=date(2026, 8, 20),
    )

    unknown_air_date_episode = SimpleNamespace(
        id=uuid4(),
        air_date=None,
    )

    episode_repository.list_by_season_id.return_value = [
        already_watched_episode,
        unwatched_episode,
        future_episode,
        unknown_air_date_episode,
    ]

    already_watched_progress = SimpleNamespace(
        episode_id=already_watched_episode.id,
        is_watched=True,
        watched_at=datetime(
            2026,
            8,
            10,
            20,
            tzinfo=UTC,
        ),
    )

    progress_repository.list_by_user_and_season.return_value = [
        already_watched_progress,
    ]

    expected_progress = SimpleNamespace(
        season_id=season_id,
    )

    progress_service.get_season_progress = Mock(
        return_value=expected_progress,
    )

    result = progress_service.mark_season_watched(
        user_id=user_id,
        season_id=season_id,
    )

    assert result is expected_progress

    progress_repository.add.assert_called_once()

    created_progress = progress_repository.add.call_args.args[0]

    assert isinstance(
        created_progress,
        EpisodeProgress,
    )

    assert created_progress.user_id == user_id
    assert created_progress.episode_id == unwatched_episode.id
    assert created_progress.is_watched is True
    assert created_progress.watched_at is not None

    watch_event_repository.add.assert_called_once()

    created_event = watch_event_repository.add.call_args.args[0]

    assert isinstance(
        created_event,
        EpisodeWatchEvent,
    )

    assert created_event.user_id == user_id
    assert created_event.episode_id == unwatched_episode.id
    assert created_event.watched_at == created_progress.watched_at

    progress_service.get_season_progress.assert_called_once_with(
        user_id=user_id,
        season_id=season_id,
    )


def test_mark_season_watched_reuses_existing_unwatched_progress(
    progress_service: EpisodeProgressService,
    season_repository: Mock,
    episode_repository: Mock,
    progress_repository: Mock,
    watch_event_repository: Mock,
) -> None:
    """Reuse an existing unwatched progress row."""

    user_id = uuid4()
    season_id = uuid4()
    show_id = uuid4()
    episode_id = uuid4()

    season_repository.get_by_id.return_value = SimpleNamespace(
        id=season_id,
        show_id=show_id,
    )

    episode_repository.list_by_season_id.return_value = [
        SimpleNamespace(
            id=episode_id,
            air_date=date(2026, 8, 10),
        ),
    ]

    existing_progress = SimpleNamespace(
        episode_id=episode_id,
        is_watched=False,
        watched_at=None,
    )

    progress_repository.list_by_user_and_season.return_value = [
        existing_progress,
    ]

    expected_progress = SimpleNamespace(
        season_id=season_id,
    )

    progress_service.get_season_progress = Mock(
        return_value=expected_progress,
    )

    result = progress_service.mark_season_watched(
        user_id=user_id,
        season_id=season_id,
    )

    assert result is expected_progress

    assert existing_progress.is_watched is True
    assert existing_progress.watched_at is not None

    progress_repository.add.assert_not_called()

    watch_event_repository.add.assert_called_once()

    created_event = watch_event_repository.add.call_args.args[0]

    assert isinstance(
        created_event,
        EpisodeWatchEvent,
    )

    assert created_event.user_id == user_id
    assert created_event.episode_id == episode_id
    assert created_event.watched_at == existing_progress.watched_at


def test_mark_season_watched_does_not_create_rewatch_for_watched_episode(
    progress_service: EpisodeProgressService,
    season_repository: Mock,
    episode_repository: Mock,
    progress_repository: Mock,
    watch_event_repository: Mock,
) -> None:
    """Do not record another viewing for Episodes already watched."""

    user_id = uuid4()
    season_id = uuid4()
    show_id = uuid4()
    episode_id = uuid4()

    season_repository.get_by_id.return_value = SimpleNamespace(
        id=season_id,
        show_id=show_id,
    )

    original_watched_at = datetime(
        2026,
        8,
        10,
        21,
        tzinfo=UTC,
    )

    episode_repository.list_by_season_id.return_value = [
        SimpleNamespace(
            id=episode_id,
            air_date=date(2026, 8, 10),
        ),
    ]

    existing_progress = SimpleNamespace(
        episode_id=episode_id,
        is_watched=True,
        watched_at=original_watched_at,
    )

    progress_repository.list_by_user_and_season.return_value = [
        existing_progress,
    ]

    expected_progress = SimpleNamespace(
        season_id=season_id,
    )

    progress_service.get_season_progress = Mock(
        return_value=expected_progress,
    )

    result = progress_service.mark_season_watched(
        user_id=user_id,
        season_id=season_id,
    )

    assert result is expected_progress

    assert existing_progress.is_watched is True
    assert existing_progress.watched_at == original_watched_at

    progress_repository.add.assert_not_called()
    watch_event_repository.add.assert_not_called()


def test_mark_show_watched_returns_none_when_show_does_not_exist(
    progress_service: EpisodeProgressService,
    show_repository: Mock,
    episode_repository: Mock,
    progress_repository: Mock,
    watch_event_repository: Mock,
) -> None:
    """Return None when the requested Show does not exist."""

    user_id = uuid4()
    show_id = uuid4()

    show_repository.get_by_id.return_value = None

    result = progress_service.mark_show_watched(
        user_id=user_id,
        show_id=show_id,
    )

    assert result is None

    show_repository.get_by_id.assert_called_once_with(
        show_id,
    )

    episode_repository.list_regular_by_show_id.assert_not_called()
    progress_repository.list_by_user_and_show.assert_not_called()
    watch_event_repository.add.assert_not_called()


def test_mark_show_watched_marks_only_aired_unwatched_regular_episodes(
    progress_service: EpisodeProgressService,
    show_repository: Mock,
    episode_repository: Mock,
    progress_repository: Mock,
    watch_event_repository: Mock,
) -> None:
    """Mark only aired regular Episodes that are not already watched."""

    user_id = uuid4()
    show_id = uuid4()

    show_repository.get_by_id.return_value = SimpleNamespace(
        id=show_id,
    )

    already_watched_episode = SimpleNamespace(
        id=uuid4(),
        air_date=date(2026, 8, 10),
    )

    unwatched_episode = SimpleNamespace(
        id=uuid4(),
        air_date=date(2026, 8, 11),
    )

    future_episode = SimpleNamespace(
        id=uuid4(),
        air_date=date(2026, 8, 20),
    )

    unknown_air_date_episode = SimpleNamespace(
        id=uuid4(),
        air_date=None,
    )

    episode_repository.list_regular_by_show_id.return_value = [
        already_watched_episode,
        unwatched_episode,
        future_episode,
        unknown_air_date_episode,
    ]

    original_watched_at = datetime(
        2026,
        8,
        10,
        20,
        tzinfo=UTC,
    )

    already_watched_progress = SimpleNamespace(
        episode_id=already_watched_episode.id,
        is_watched=True,
        watched_at=original_watched_at,
    )

    progress_repository.list_by_user_and_show.return_value = [
        already_watched_progress,
    ]

    expected_progress = SimpleNamespace(
        show_id=show_id,
    )

    progress_service.get_show_progress = Mock(
        return_value=expected_progress,
    )

    result = progress_service.mark_show_watched(
        user_id=user_id,
        show_id=show_id,
    )

    assert result is expected_progress

    progress_repository.add.assert_called_once()

    created_progress = progress_repository.add.call_args.args[0]

    assert isinstance(
        created_progress,
        EpisodeProgress,
    )

    assert created_progress.user_id == user_id
    assert created_progress.episode_id == unwatched_episode.id
    assert created_progress.is_watched is True
    assert created_progress.watched_at is not None

    watch_event_repository.add.assert_called_once()

    created_event = watch_event_repository.add.call_args.args[0]

    assert isinstance(
        created_event,
        EpisodeWatchEvent,
    )

    assert created_event.user_id == user_id
    assert created_event.episode_id == unwatched_episode.id
    assert created_event.watched_at == created_progress.watched_at

    assert already_watched_progress.watched_at == original_watched_at

    progress_service.get_show_progress.assert_called_once_with(
        user_id=user_id,
        show_id=show_id,
    )


def test_mark_show_watched_reuses_existing_unwatched_progress(
    progress_service: EpisodeProgressService,
    show_repository: Mock,
    episode_repository: Mock,
    progress_repository: Mock,
    watch_event_repository: Mock,
) -> None:
    """Reuse an existing unwatched progress row."""

    user_id = uuid4()
    show_id = uuid4()
    episode_id = uuid4()

    show_repository.get_by_id.return_value = SimpleNamespace(
        id=show_id,
    )

    episode_repository.list_regular_by_show_id.return_value = [
        SimpleNamespace(
            id=episode_id,
            air_date=date(2026, 8, 10),
        ),
    ]

    existing_progress = SimpleNamespace(
        episode_id=episode_id,
        is_watched=False,
        watched_at=None,
    )

    progress_repository.list_by_user_and_show.return_value = [
        existing_progress,
    ]

    expected_progress = SimpleNamespace(
        show_id=show_id,
    )

    progress_service.get_show_progress = Mock(
        return_value=expected_progress,
    )

    result = progress_service.mark_show_watched(
        user_id=user_id,
        show_id=show_id,
    )

    assert result is expected_progress

    assert existing_progress.is_watched is True
    assert existing_progress.watched_at is not None

    progress_repository.add.assert_not_called()

    watch_event_repository.add.assert_called_once()

    created_event = watch_event_repository.add.call_args.args[0]

    assert isinstance(
        created_event,
        EpisodeWatchEvent,
    )

    assert created_event.user_id == user_id
    assert created_event.episode_id == episode_id
    assert created_event.watched_at == existing_progress.watched_at


def test_get_previous_unwatched_episodes_counts_eligible_previous_episodes(
    progress_service: EpisodeProgressService,
    progress_repository: Mock,
    episode_repository: Mock,
    season_repository: Mock,
) -> None:
    """Count eligible previous unwatched regular Episodes."""

    user_id = uuid4()
    episode_id = uuid4()
    season_id = uuid4()
    show_id = uuid4()

    episode_repository.get_by_id.return_value = SimpleNamespace(
        id=episode_id,
        season_id=season_id,
        episode_number=3,
        air_date=date(2026, 8, 15),
    )

    season_repository.get_by_id.return_value = SimpleNamespace(
        id=season_id,
        show_id=show_id,
        season_number=2,
    )

    previous_episodes = [
        SimpleNamespace(id=uuid4()),
        SimpleNamespace(id=uuid4()),
        SimpleNamespace(id=uuid4()),
    ]

    progress_repository.list_previous_unwatched_aired_episodes.return_value = previous_episodes

    result = progress_service.get_previous_unwatched_episodes(
        user_id=user_id,
        episode_id=episode_id,
    )

    assert result is not None
    assert result.episode_id == episode_id
    assert result.previous_unwatched_count == 3
    assert result.has_previous_unwatched is True

    progress_repository.list_previous_unwatched_aired_episodes.assert_called_once_with(
        user_id=user_id,
        show_id=show_id,
        target_season_number=2,
        target_episode_number=3,
        as_of=FIXED_TODAY,
    )


def test_get_previous_unwatched_episodes_returns_zero_when_none_exist(
    progress_service: EpisodeProgressService,
    progress_repository: Mock,
    episode_repository: Mock,
    season_repository: Mock,
) -> None:
    """Return zero when no eligible earlier Episodes remain unwatched."""

    user_id = uuid4()
    episode_id = uuid4()
    season_id = uuid4()
    show_id = uuid4()

    episode_repository.get_by_id.return_value = SimpleNamespace(
        id=episode_id,
        season_id=season_id,
        episode_number=1,
        air_date=date(2026, 8, 15),
    )

    season_repository.get_by_id.return_value = SimpleNamespace(
        id=season_id,
        show_id=show_id,
        season_number=1,
    )

    progress_repository.list_previous_unwatched_aired_episodes.return_value = []

    result = progress_service.get_previous_unwatched_episodes(
        user_id=user_id,
        episode_id=episode_id,
    )

    assert result is not None
    assert result.previous_unwatched_count == 0
    assert result.has_previous_unwatched is False


def test_get_previous_unwatched_episodes_returns_none_when_episode_missing(
    progress_service: EpisodeProgressService,
    progress_repository: Mock,
    episode_repository: Mock,
    season_repository: Mock,
) -> None:
    """Return None when checking a missing Episode."""

    episode_repository.get_by_id.return_value = None

    result = progress_service.get_previous_unwatched_episodes(
        user_id=uuid4(),
        episode_id=uuid4(),
    )

    assert result is None

    season_repository.get_by_id.assert_not_called()
    progress_repository.list_previous_unwatched_aired_episodes.assert_not_called()


def test_get_previous_unwatched_episodes_rejects_future_episode(
    progress_service: EpisodeProgressService,
    progress_repository: Mock,
    episode_repository: Mock,
    season_repository: Mock,
) -> None:
    """Do not inspect previous Episodes when the target has not aired."""

    episode_repository.get_by_id.return_value = SimpleNamespace(
        id=uuid4(),
        season_id=uuid4(),
        episode_number=4,
        air_date=date(2026, 8, 16),
    )

    with pytest.raises(EpisodeNotWatchableError):
        progress_service.get_previous_unwatched_episodes(
            user_id=uuid4(),
            episode_id=uuid4(),
        )

    season_repository.get_by_id.assert_not_called()
    progress_repository.list_previous_unwatched_aired_episodes.assert_not_called()


def test_mark_watched_with_previous_marks_previous_and_target_once(
    db_session: Session,
    progress_service: EpisodeProgressService,
    progress_repository: Mock,
    episode_repository: Mock,
    season_repository: Mock,
    watch_event_repository: Mock,
) -> None:
    """Mark eligible previous Episodes and target without creating Rewatches."""

    user = persist_user(db_session)

    show = persist_show(db_session)

    season = persist_season(
        db_session,
        show=show,
    )

    already_watched_episode = Episode(
        season_id=season.id,
        tmdb_id=999101,
        episode_number=1,
        title="Episode 1",
        air_date=date(2026, 8, 10),
    )

    new_previous_episode = Episode(
        season_id=season.id,
        tmdb_id=999102,
        episode_number=2,
        title="Episode 2",
        air_date=date(2026, 8, 11),
    )

    target_episode = Episode(
        season_id=season.id,
        tmdb_id=999103,
        episode_number=3,
        title="Episode 3",
        air_date=date(2026, 8, 15),
    )

    db_session.add_all(
        [
            already_watched_episode,
            new_previous_episode,
            target_episode,
        ]
    )
    db_session.flush()

    episode_repository.get_by_id.return_value = target_episode
    season_repository.get_by_id.return_value = season

    progress_repository.list_previous_unwatched_aired_episodes.return_value = [
        already_watched_episode,
        new_previous_episode,
    ]

    original_watched_at = datetime(
        2026,
        8,
        10,
        20,
        tzinfo=UTC,
    )

    already_watched_progress = EpisodeProgress(
        user_id=user.id,
        episode_id=already_watched_episode.id,
        is_watched=True,
        watched_at=original_watched_at,
    )

    db_session.add(already_watched_progress)
    db_session.flush()

    progress_repository.list_by_user_and_episode_ids.return_value = [
        already_watched_progress,
    ]

    progress_repository.get_by_user_and_episode.return_value = None

    added_progress: list[EpisodeProgress] = []

    def add_progress(progress: EpisodeProgress) -> EpisodeProgress:
        db_session.add(progress)
        added_progress.append(progress)

        return progress

    progress_repository.add.side_effect = add_progress

    added_events: list[EpisodeWatchEvent] = []

    def add_watch_event(event: EpisodeWatchEvent) -> EpisodeWatchEvent:
        db_session.add(event)
        added_events.append(event)

        return event

    watch_event_repository.add.side_effect = add_watch_event

    result = progress_service.mark_watched_with_previous(
        user_id=user.id,
        episode_id=target_episode.id,
    )

    assert result is not None

    assert result.previous_marked_count == 1

    assert result.progress.episode_id == target_episode.id
    assert result.progress.is_watched is True

    assert {progress.episode_id for progress in added_progress} == {
        new_previous_episode.id,
        target_episode.id,
    }

    assert {event.episode_id for event in added_events} == {
        new_previous_episode.id,
        target_episode.id,
    }

    assert already_watched_episode.id not in {event.episode_id for event in added_events}

    assert already_watched_progress.watched_at is not None

    assert (
        as_utc(
            already_watched_progress.watched_at,
        )
        == original_watched_at
    )


def test_mark_watched_with_previous_does_not_rewatch_watched_target(
    db_session: Session,
    progress_service: EpisodeProgressService,
    progress_repository: Mock,
    episode_repository: Mock,
    season_repository: Mock,
    watch_event_repository: Mock,
) -> None:
    """Catch-up must not create another event for an already watched target."""

    user = persist_user(db_session)

    show = persist_show(db_session)

    season = persist_season(
        db_session,
        show=show,
    )

    target_episode = Episode(
        season_id=season.id,
        tmdb_id=999201,
        episode_number=3,
        title="Episode 3",
        air_date=date(2026, 8, 15),
    )

    db_session.add(target_episode)
    db_session.flush()

    episode_repository.get_by_id.return_value = target_episode
    season_repository.get_by_id.return_value = season

    progress_repository.list_previous_unwatched_aired_episodes.return_value = []
    progress_repository.list_by_user_and_episode_ids.return_value = []

    original_watched_at = datetime(
        2026,
        8,
        10,
        20,
        tzinfo=UTC,
    )

    progress = EpisodeProgress(
        user_id=user.id,
        episode_id=target_episode.id,
        is_watched=True,
        watched_at=original_watched_at,
    )

    db_session.add(progress)
    db_session.flush()

    progress_repository.get_by_user_and_episode.return_value = progress

    result = progress_service.mark_watched_with_previous(
        user_id=user.id,
        episode_id=target_episode.id,
    )

    assert result is not None

    assert result.previous_marked_count == 0

    assert result.progress.episode_id == target_episode.id
    assert result.progress.is_watched is True

    assert progress.watched_at is not None

    assert (
        as_utc(
            progress.watched_at,
        )
        == original_watched_at
    )

    progress_repository.add.assert_not_called()
    watch_event_repository.add.assert_not_called()


def test_mark_watched_moves_planning_show_to_watching(
    db_session: Session,
) -> None:
    """Start a Planning Show when its first Episode is watched."""

    user = persist_user(db_session)
    show = persist_show(db_session)
    season = persist_season(
        db_session,
        show=show,
    )
    episode = persist_episode(
        db_session,
        season=season,
    )
    episode.air_date = FIXED_TODAY

    entry = persist_library_entry(
        db_session,
        user=user,
        show=show,
        status=LibraryStatus.PLANNING,
    )

    service = EpisodeProgressService(
        session=db_session,
        progress_repository=EpisodeProgressRepository(db_session),
        episode_repository=EpisodeRepository(db_session),
        season_repository=SeasonRepository(db_session),
        show_repository=ShowRepository(db_session),
        watch_event_repository=EpisodeWatchEventRepository(db_session),
        show_status_synchronizer=make_real_show_status_synchronizer(
            db_session,
        ),
        today=lambda: FIXED_TODAY,
    )

    watched_at = datetime(
        2026,
        8,
        15,
        20,
        30,
        tzinfo=UTC,
    )

    result = service.mark_watched(
        user_id=user.id,
        episode_id=episode.id,
        watched_at=watched_at,
    )

    assert result is not None

    db_session.refresh(entry)

    assert entry.status == LibraryStatus.WATCHING
    assert as_utc(entry.started_at) == watched_at
    assert entry.completed_at is None


@pytest.mark.parametrize(
    "initial_status",
    [
        LibraryStatus.PAUSED,
        LibraryStatus.DROPPED,
    ],
)
def test_mark_watched_resumes_manually_inactive_show(
    db_session: Session,
    initial_status: LibraryStatus,
) -> None:
    """Resume a Paused or Dropped Show when viewing activity returns."""

    user = persist_user(db_session)
    show = persist_show(db_session)
    season = persist_season(
        db_session,
        show=show,
    )
    episode = persist_episode(
        db_session,
        season=season,
    )
    episode.air_date = FIXED_TODAY

    original_started_at = datetime(
        2026,
        8,
        1,
        20,
        tzinfo=UTC,
    )

    entry = persist_library_entry(
        db_session,
        user=user,
        show=show,
        status=initial_status,
        started_at=original_started_at,
    )

    service = EpisodeProgressService(
        session=db_session,
        progress_repository=EpisodeProgressRepository(db_session),
        episode_repository=EpisodeRepository(db_session),
        season_repository=SeasonRepository(db_session),
        show_repository=ShowRepository(db_session),
        watch_event_repository=EpisodeWatchEventRepository(db_session),
        show_status_synchronizer=make_real_show_status_synchronizer(
            db_session,
        ),
        today=lambda: FIXED_TODAY,
    )

    service.mark_watched(
        user_id=user.id,
        episode_id=episode.id,
    )

    db_session.refresh(entry)

    assert entry.status == LibraryStatus.WATCHING
    assert as_utc(entry.started_at) == original_started_at
    assert entry.completed_at is None


def test_mark_watched_keeps_caught_up_ongoing_show_watching(
    db_session: Session,
) -> None:
    """Keep an ongoing Show Watching even when every known Episode is watched."""

    user = persist_user(db_session)

    show = persist_show(db_session)
    show.status = "Returning Series"
    show.in_production = True

    season = persist_season(
        db_session,
        show=show,
    )
    episode = persist_episode(
        db_session,
        season=season,
    )
    episode.air_date = FIXED_TODAY

    entry = persist_library_entry(
        db_session,
        user=user,
        show=show,
        status=LibraryStatus.PLANNING,
    )

    service = EpisodeProgressService(
        session=db_session,
        progress_repository=EpisodeProgressRepository(db_session),
        episode_repository=EpisodeRepository(db_session),
        season_repository=SeasonRepository(db_session),
        show_repository=ShowRepository(db_session),
        watch_event_repository=EpisodeWatchEventRepository(db_session),
        show_status_synchronizer=make_real_show_status_synchronizer(
            db_session,
        ),
        today=lambda: FIXED_TODAY,
    )

    service.mark_watched(
        user_id=user.id,
        episode_id=episode.id,
    )

    db_session.refresh(entry)

    assert entry.status == LibraryStatus.WATCHING
    assert entry.completed_at is None

    progress = service.get_show_progress(
        user_id=user.id,
        show_id=show.id,
    )

    assert progress is not None
    assert progress.caught_up is True


def test_mark_watched_completes_ended_show_when_all_regular_episodes_are_watched(
    db_session: Session,
) -> None:
    """Complete a terminal Show only after every regular Episode is watched."""

    user = persist_user(db_session)

    show = persist_show(db_session)
    show.status = "Ended"
    show.in_production = False

    season = persist_season(
        db_session,
        show=show,
    )
    episode = persist_episode(
        db_session,
        season=season,
    )
    episode.air_date = FIXED_TODAY

    entry = persist_library_entry(
        db_session,
        user=user,
        show=show,
        status=LibraryStatus.PLANNING,
    )

    service = EpisodeProgressService(
        session=db_session,
        progress_repository=EpisodeProgressRepository(db_session),
        episode_repository=EpisodeRepository(db_session),
        season_repository=SeasonRepository(db_session),
        show_repository=ShowRepository(db_session),
        watch_event_repository=EpisodeWatchEventRepository(db_session),
        show_status_synchronizer=make_real_show_status_synchronizer(
            db_session,
        ),
        today=lambda: FIXED_TODAY,
    )

    watched_at = datetime(
        2026,
        8,
        15,
        21,
        tzinfo=UTC,
    )

    service.mark_watched(
        user_id=user.id,
        episode_id=episode.id,
        watched_at=watched_at,
    )

    db_session.refresh(entry)

    assert entry.status == LibraryStatus.COMPLETED
    assert as_utc(entry.started_at) == watched_at
    assert as_utc(entry.completed_at) == watched_at


def test_mark_watched_keeps_partially_watched_ended_show_watching(
    db_session: Session,
) -> None:
    """Do not complete an ended Show while regular Episodes remain unwatched."""

    user = persist_user(db_session)

    show = persist_show(db_session)
    show.status = "Ended"
    show.in_production = False

    season = persist_season(
        db_session,
        show=show,
    )

    first_episode = persist_episode(
        db_session,
        season=season,
    )
    first_episode.air_date = FIXED_TODAY

    second_episode = Episode(
        season_id=season.id,
        tmdb_id=999004,
        episode_number=2,
        title="Episode 2",
        air_date=FIXED_TODAY,
    )
    db_session.add(second_episode)
    db_session.flush()

    entry = persist_library_entry(
        db_session,
        user=user,
        show=show,
        status=LibraryStatus.PLANNING,
    )

    service = EpisodeProgressService(
        session=db_session,
        progress_repository=EpisodeProgressRepository(db_session),
        episode_repository=EpisodeRepository(db_session),
        season_repository=SeasonRepository(db_session),
        show_repository=ShowRepository(db_session),
        watch_event_repository=EpisodeWatchEventRepository(db_session),
        show_status_synchronizer=make_real_show_status_synchronizer(
            db_session,
        ),
        today=lambda: FIXED_TODAY,
    )

    service.mark_watched(
        user_id=user.id,
        episode_id=first_episode.id,
    )

    db_session.refresh(entry)

    assert entry.status == LibraryStatus.WATCHING
    assert entry.completed_at is None


def test_mark_watched_rewatch_preserves_completed_show_completion_date(
    db_session: Session,
) -> None:
    """Preserve the original completion date when rewatching a Completed Show."""

    user = persist_user(db_session)

    show = persist_show(db_session)
    show.status = "Ended"
    show.in_production = False

    season = persist_season(
        db_session,
        show=show,
    )
    episode = persist_episode(
        db_session,
        season=season,
    )
    episode.air_date = FIXED_TODAY

    original_started_at = datetime(
        2026,
        7,
        1,
        20,
        tzinfo=UTC,
    )
    original_completed_at = datetime(
        2026,
        7,
        10,
        22,
        tzinfo=UTC,
    )

    entry = persist_library_entry(
        db_session,
        user=user,
        show=show,
        status=LibraryStatus.COMPLETED,
        started_at=original_started_at,
        completed_at=original_completed_at,
    )

    progress = EpisodeProgress(
        user_id=user.id,
        episode_id=episode.id,
        is_watched=True,
        watched_at=original_completed_at,
    )
    db_session.add(progress)
    db_session.flush()

    service = EpisodeProgressService(
        session=db_session,
        progress_repository=EpisodeProgressRepository(db_session),
        episode_repository=EpisodeRepository(db_session),
        season_repository=SeasonRepository(db_session),
        show_repository=ShowRepository(db_session),
        watch_event_repository=EpisodeWatchEventRepository(db_session),
        show_status_synchronizer=make_real_show_status_synchronizer(
            db_session,
        ),
        today=lambda: FIXED_TODAY,
    )

    service.mark_watched(
        user_id=user.id,
        episode_id=episode.id,
        watched_at=datetime(
            2026,
            8,
            15,
            22,
            tzinfo=UTC,
        ),
    )

    db_session.refresh(entry)

    assert entry.status == LibraryStatus.COMPLETED
    assert as_utc(entry.started_at) == original_started_at
    assert as_utc(entry.completed_at) == original_completed_at


def test_mark_unwatched_moves_completed_show_back_to_watching(
    db_session: Session,
) -> None:
    """Move a Completed Show back to Watching when progress is removed."""

    user = persist_user(db_session)

    show = persist_show(db_session)
    show.status = "Ended"
    show.in_production = False

    season = persist_season(
        db_session,
        show=show,
    )
    episode = persist_episode(
        db_session,
        season=season,
    )
    episode.air_date = FIXED_TODAY

    started_at = datetime(
        2026,
        7,
        1,
        20,
        tzinfo=UTC,
    )

    entry = persist_library_entry(
        db_session,
        user=user,
        show=show,
        status=LibraryStatus.COMPLETED,
        started_at=started_at,
        completed_at=datetime(
            2026,
            7,
            10,
            22,
            tzinfo=UTC,
        ),
    )

    db_session.add(
        EpisodeProgress(
            user_id=user.id,
            episode_id=episode.id,
            is_watched=True,
            watched_at=datetime(
                2026,
                7,
                10,
                22,
                tzinfo=UTC,
            ),
        )
    )
    db_session.flush()

    service = EpisodeProgressService(
        session=db_session,
        progress_repository=EpisodeProgressRepository(db_session),
        episode_repository=EpisodeRepository(db_session),
        season_repository=SeasonRepository(db_session),
        show_repository=ShowRepository(db_session),
        watch_event_repository=EpisodeWatchEventRepository(db_session),
        show_status_synchronizer=make_real_show_status_synchronizer(
            db_session,
        ),
        today=lambda: FIXED_TODAY,
    )

    service.mark_unwatched(
        user_id=user.id,
        episode_id=episode.id,
    )

    db_session.refresh(entry)

    assert entry.status == LibraryStatus.WATCHING
    assert as_utc(entry.started_at) == started_at
    assert entry.completed_at is None


@pytest.mark.parametrize(
    "status",
    [
        LibraryStatus.PAUSED,
        LibraryStatus.DROPPED,
    ],
)
def test_mark_unwatched_preserves_manual_show_status(
    db_session: Session,
    status: LibraryStatus,
) -> None:
    """Preserve Paused and Dropped when current Episode progress is removed."""

    user = persist_user(db_session)
    show = persist_show(db_session)
    season = persist_season(
        db_session,
        show=show,
    )
    episode = persist_episode(
        db_session,
        season=season,
    )
    episode.air_date = FIXED_TODAY

    started_at = datetime(
        2026,
        8,
        1,
        20,
        tzinfo=UTC,
    )

    entry = persist_library_entry(
        db_session,
        user=user,
        show=show,
        status=status,
        started_at=started_at,
    )

    db_session.add(
        EpisodeProgress(
            user_id=user.id,
            episode_id=episode.id,
            is_watched=True,
            watched_at=started_at,
        )
    )
    db_session.flush()

    service = EpisodeProgressService(
        session=db_session,
        progress_repository=EpisodeProgressRepository(db_session),
        episode_repository=EpisodeRepository(db_session),
        season_repository=SeasonRepository(db_session),
        show_repository=ShowRepository(db_session),
        watch_event_repository=EpisodeWatchEventRepository(db_session),
        show_status_synchronizer=make_real_show_status_synchronizer(
            db_session,
        ),
        today=lambda: FIXED_TODAY,
    )

    service.mark_unwatched(
        user_id=user.id,
        episode_id=episode.id,
    )

    db_session.refresh(entry)

    assert entry.status == status
    assert as_utc(entry.started_at) == started_at
