from datetime import datetime, timezone
from types import SimpleNamespace
from unittest.mock import Mock
from uuid import uuid4

import pytest
from sqlalchemy.orm import Session

from app.models.episode_progress import EpisodeProgress
from app.repositories.episode import EpisodeRepository
from app.repositories.episode_progress import EpisodeProgressRepository
from app.repositories.season import SeasonRepository
from app.repositories.show import ShowRepository
from app.services.episode_progress import EpisodeProgressService

def as_utc(
    value: datetime,
) -> datetime:
    """Interpret timezone-naive database datetimes as UTC."""

    if value.tzinfo is None:
        return value.replace(
            tzinfo=timezone.utc,
        )

    return value.astimezone(
        timezone.utc,
    )


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
def progress_service(
    db_session: Session,
    progress_repository: Mock,
    episode_repository: Mock,
    season_repository: Mock,
    show_repository: Mock,
) -> EpisodeProgressService:
    """Provide an episode progress service using mocked repositories."""

    return EpisodeProgressService(
        session=db_session,
        progress_repository=progress_repository,
        episode_repository=episode_repository,
        season_repository=season_repository,
        show_repository=show_repository,
    )


def test_mark_watched_returns_none_when_episode_does_not_exist(
    progress_service: EpisodeProgressService,
    progress_repository: Mock,
    episode_repository: Mock,
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


def test_mark_watched_creates_progress(
    db_session: Session,
    progress_service: EpisodeProgressService,
    progress_repository: Mock,
    episode_repository: Mock,
) -> None:
    """Create progress when an episode is marked watched for the first time."""

    user_id = uuid4()
    episode_id = uuid4()

    episode_repository.get_by_id.return_value = SimpleNamespace(
        id=episode_id,
    )
    progress_repository.get_by_user_and_episode.return_value = None

    def add_progress(
        progress: EpisodeProgress,
    ) -> EpisodeProgress:
        db_session.add(progress)
        return progress

    progress_repository.add.side_effect = add_progress

    result = progress_service.mark_watched(
        user_id=user_id,
        episode_id=episode_id,
    )

    assert result is not None
    assert result.user_id == user_id
    assert result.episode_id == episode_id
    assert result.is_watched is True
    assert result.watched_at is not None

    progress_repository.add.assert_called_once_with(
        result,
    )


def test_mark_watched_uses_explicit_watched_at(
    db_session: Session,
    progress_service: EpisodeProgressService,
    progress_repository: Mock,
    episode_repository: Mock,
) -> None:
    """Store the explicitly supplied viewing date."""

    user_id = uuid4()
    episode_id = uuid4()

    episode_repository.get_by_id.return_value = SimpleNamespace(
        id=episode_id,
    )
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
        tzinfo=timezone.utc,
    )

    result = progress_service.mark_watched(
        user_id=user_id,
        episode_id=episode_id,
        watched_at=watched_at,
    )

    assert result.watched_at is not None
    assert as_utc(result.watched_at) == watched_at


def test_mark_watched_normalizes_naive_watched_at_to_utc(
    db_session: Session,
    progress_service: EpisodeProgressService,
    progress_repository: Mock,
    episode_repository: Mock,
) -> None:
    """Interpret a timezone-naive viewing date as UTC."""

    user_id = uuid4()
    episode_id = uuid4()

    episode_repository.get_by_id.return_value = SimpleNamespace(
        id=episode_id,
    )
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
        user_id=user_id,
        episode_id=episode_id,
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
        tzinfo=timezone.utc,
    )


def test_mark_watched_updates_existing_unwatched_progress(
    db_session: Session,
    progress_service: EpisodeProgressService,
    progress_repository: Mock,
    episode_repository: Mock,
) -> None:
    """Mark an existing unwatched progress entry as watched."""

    user_id = uuid4()
    episode_id = uuid4()

    episode_repository.get_by_id.return_value = SimpleNamespace(
        id=episode_id,
    )

    progress = EpisodeProgress(
        user_id=user_id,
        episode_id=episode_id,
        is_watched=False,
        watched_at=None,
    )

    db_session.add(progress)
    db_session.flush()

    progress_repository.get_by_user_and_episode.return_value = progress

    result = progress_service.mark_watched(
        user_id=user_id,
        episode_id=episode_id,
    )

    assert result is progress
    assert result.is_watched is True
    assert result.watched_at is not None

    progress_repository.add.assert_not_called()


def test_mark_watched_preserves_existing_watched_at(
    db_session: Session,
    progress_service: EpisodeProgressService,
    progress_repository: Mock,
    episode_repository: Mock,
) -> None:
    """Preserve the viewing date when an already watched episode is marked again."""

    user_id = uuid4()
    episode_id = uuid4()

    episode_repository.get_by_id.return_value = SimpleNamespace(
        id=episode_id,
    )

    original_watched_at = datetime(
        2026,
        7,
        10,
        20,
        0,
        tzinfo=timezone.utc,
    )

    progress = EpisodeProgress(
        user_id=user_id,
        episode_id=episode_id,
        is_watched=True,
        watched_at=original_watched_at,
    )

    db_session.add(progress)
    db_session.flush()

    progress_repository.get_by_user_and_episode.return_value = progress

    result = progress_service.mark_watched(
        user_id=user_id,
        episode_id=episode_id,
    )

    assert result is progress
    # assert result.watched_at == original_watched_at
    assert result.watched_at is not None
    assert as_utc(result.watched_at) == original_watched_at


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

    user_id = uuid4()
    episode_id = uuid4()

    episode_repository.get_by_id.return_value = SimpleNamespace(
        id=episode_id,
    )
    progress_repository.get_by_user_and_episode.return_value = None

    def add_progress(
        progress: EpisodeProgress,
    ) -> EpisodeProgress:
        db_session.add(progress)
        return progress

    progress_repository.add.side_effect = add_progress

    result = progress_service.mark_unwatched(
        user_id=user_id,
        episode_id=episode_id,
    )

    assert result is not None
    assert result.is_watched is False
    assert result.watched_at is None

    progress_repository.add.assert_called_once_with(
        result,
    )


def test_mark_unwatched_clears_existing_progress(
    db_session: Session,
    progress_service: EpisodeProgressService,
    progress_repository: Mock,
    episode_repository: Mock,
) -> None:
    """Clear watched state and viewing date from existing progress."""

    user_id = uuid4()
    episode_id = uuid4()

    episode_repository.get_by_id.return_value = SimpleNamespace(
        id=episode_id,
    )

    progress = EpisodeProgress(
        user_id=user_id,
        episode_id=episode_id,
        is_watched=True,
        watched_at=datetime.now(timezone.utc),
    )

    db_session.add(progress)
    db_session.flush()

    progress_repository.get_by_user_and_episode.return_value = progress

    result = progress_service.mark_unwatched(
        user_id=user_id,
        episode_id=episode_id,
    )

    assert result is progress
    assert result.is_watched is False
    assert result.watched_at is None


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
    progress_repository.count_watched_for_season.assert_not_called()


def test_get_season_progress_calculates_percentage(
    progress_service: EpisodeProgressService,
    season_repository: Mock,
    episode_repository: Mock,
    progress_repository: Mock,
) -> None:
    """Calculate watched episode count and percentage for a season."""

    user_id = uuid4()
    season_id = uuid4()

    season_repository.get_by_id.return_value = SimpleNamespace(
        id=season_id,
    )
    episode_repository.count_by_season_id.return_value = 10
    progress_repository.count_watched_for_season.return_value = 7

    result = progress_service.get_season_progress(
        user_id=user_id,
        season_id=season_id,
    )

    assert result is not None
    assert result.season_id == season_id
    assert result.watched_episodes == 7
    assert result.total_episodes == 10
    assert result.progress_percentage == 70.0


def test_get_season_progress_handles_empty_season(
    progress_service: EpisodeProgressService,
    season_repository: Mock,
    episode_repository: Mock,
    progress_repository: Mock,
) -> None:
    """Return zero percent for a season with no locally stored episodes."""

    user_id = uuid4()
    season_id = uuid4()

    season_repository.get_by_id.return_value = SimpleNamespace(
        id=season_id,
    )
    episode_repository.count_by_season_id.return_value = 0
    progress_repository.count_watched_for_season.return_value = 0

    result = progress_service.get_season_progress(
        user_id=user_id,
        season_id=season_id,
    )

    assert result is not None
    assert result.watched_episodes == 0
    assert result.total_episodes == 0
    assert result.progress_percentage == 0.0


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

    episode_repository.count_by_show_id.assert_not_called()
    progress_repository.count_watched_for_show.assert_not_called()


def test_get_show_progress_calculates_percentage(
    progress_service: EpisodeProgressService,
    show_repository: Mock,
    episode_repository: Mock,
    progress_repository: Mock,
) -> None:
    """Calculate watched episode count and percentage for a TV series."""

    user_id = uuid4()
    show_id = uuid4()

    show_repository.get_by_id.return_value = SimpleNamespace(
        id=show_id,
    )
    episode_repository.count_by_show_id.return_value = 19
    progress_repository.count_watched_for_show.return_value = 12

    result = progress_service.get_show_progress(
        user_id=user_id,
        show_id=show_id,
    )

    assert result is not None
    assert result.show_id == show_id
    assert result.watched_episodes == 12
    assert result.total_episodes == 19
    assert result.progress_percentage == pytest.approx(
        63.1578947368421,
    )


def test_get_show_progress_handles_show_without_episodes(
    progress_service: EpisodeProgressService,
    show_repository: Mock,
    episode_repository: Mock,
    progress_repository: Mock,
) -> None:
    """Return zero percent when no local episodes exist for a TV series."""

    user_id = uuid4()
    show_id = uuid4()

    show_repository.get_by_id.return_value = SimpleNamespace(
        id=show_id,
    )
    episode_repository.count_by_show_id.return_value = 0
    progress_repository.count_watched_for_show.return_value = 0

    result = progress_service.get_show_progress(
        user_id=user_id,
        show_id=show_id,
    )

    assert result is not None
    assert result.watched_episodes == 0
    assert result.total_episodes == 0
    assert result.progress_percentage == 0.0


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

    progress_repository.get_next_unwatched_for_show.return_value = (
        episode
    )

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