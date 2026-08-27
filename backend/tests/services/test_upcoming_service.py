from datetime import date
from types import SimpleNamespace
from unittest.mock import Mock
from uuid import UUID, uuid4

from app.models.enums import LibraryStatus
from app.repositories.episode import (
    EpisodeRepository,
    TimelineEpisode,
)
from app.repositories.episode_progress import EpisodeProgressRepository
from app.repositories.library import LibraryRepository
from app.services.upcoming import UpcomingService


def create_show(
    *,
    show_id: UUID | None = None,
    tmdb_id: int = 95396,
    title: str = "Severance",
) -> SimpleNamespace:
    """Create Show-like data required by UpcomingService."""

    return SimpleNamespace(
        id=show_id or uuid4(),
        tmdb_id=tmdb_id,
        title=title,
        original_title=title,
        first_air_date=date(2022, 2, 18),
        tmdb_poster_path=None,
        local_poster_path=None,
        poster_url="https://example.com/poster.jpg",
        backdrop_url="https://example.com/backdrop.jpg",
        status="Returning Series",
        vote_average=8.4,
    )


def create_library_entry(
    *,
    show: SimpleNamespace,
    status: LibraryStatus = LibraryStatus.WATCHING,
) -> SimpleNamespace:
    """Create LibraryEntry-like data required by UpcomingService."""

    return SimpleNamespace(
        id=uuid4(),
        show_id=show.id,
        show=show,
        status=status,
    )


def create_episode(
    *,
    tmdb_id: int,
    episode_number: int,
    title: str,
    air_date: date,
) -> SimpleNamespace:
    """Create Episode-like data required by UpcomingService."""

    return SimpleNamespace(
        id=uuid4(),
        tmdb_id=tmdb_id,
        episode_number=episode_number,
        title=title,
        air_date=air_date,
        runtime=52,
        still_url="https://example.com/still.jpg",
    )


def create_service(
    *,
    library_repository: Mock,
    episode_repository: Mock,
    progress_repository: Mock | None = None,
) -> UpcomingService:
    if progress_repository is None:
        progress_repository = Mock(
            spec=EpisodeProgressRepository,
        )

        progress_repository.get_watched_episode_ids.return_value = set()

    return UpcomingService(
        library_repository=library_repository,
        episode_repository=episode_repository,
        progress_repository=progress_repository,
    )


def test_lists_upcoming_episodes_for_watching_and_planning_shows() -> None:
    """Watching and Planning Shows are both eligible for Upcoming."""

    library_repository = Mock(spec=LibraryRepository)
    episode_repository = Mock(spec=EpisodeRepository)

    watching_show = create_show(
        tmdb_id=95396,
        title="Severance",
    )

    planning_show = create_show(
        tmdb_id=100088,
        title="The Last of Us",
    )

    watching_entry = create_library_entry(
        show=watching_show,
        status=LibraryStatus.WATCHING,
    )

    planning_entry = create_library_entry(
        show=planning_show,
        status=LibraryStatus.PLANNING,
    )

    watching_episode = create_episode(
        tmdb_id=2001,
        episode_number=3,
        title="Severance Episode",
        air_date=date(2026, 8, 16),
    )

    planning_episode = create_episode(
        tmdb_id=3001,
        episode_number=1,
        title="The Last of Us Episode",
        air_date=date(2026, 8, 17),
    )

    library_repository.list_shows_by_user.return_value = [
        watching_entry,
        planning_entry,
    ]

    episode_repository.list_regular_for_shows_between.return_value = [
        TimelineEpisode(
            show_id=watching_show.id,
            episode=watching_episode,
            season_number=2,
        ),
        TimelineEpisode(
            show_id=planning_show.id,
            episode=planning_episode,
            season_number=3,
        ),
    ]

    service = create_service(
        library_repository=library_repository,
        episode_repository=episode_repository,
    )

    user_id = uuid4()

    result = service.list_for_user(
        user_id=user_id,
        from_date=date(2026, 8, 15),
    )

    assert len(result) == 2

    first = result[0]

    assert first.library_entry_id == watching_entry.id
    assert first.library_status == LibraryStatus.WATCHING
    assert first.show.id == watching_show.id
    assert first.show.title == "Severance"

    assert first.episode.id == watching_episode.id
    assert first.episode.season_number == 2
    assert first.episode.episode_number == 3
    assert first.episode.title == "Severance Episode"
    assert first.episode.air_date == date(2026, 8, 16)

    second = result[1]

    assert second.library_entry_id == planning_entry.id
    assert second.library_status == LibraryStatus.PLANNING
    assert second.show.id == planning_show.id
    assert second.episode.season_number == 3
    assert second.episode.episode_number == 1

    library_repository.list_shows_by_user.assert_called_once_with(
        user_id,
    )

    episode_repository.list_regular_for_shows_between.assert_called_once_with(
        show_ids=[
            watching_show.id,
            planning_show.id,
        ],
        from_date=date(2026, 8, 15),
        to_date=None,
        limit=None,
    )


def test_excludes_completed_dropped_and_paused_shows() -> None:
    """Only Watching and Planning Shows may appear in Upcoming."""

    library_repository = Mock(spec=LibraryRepository)
    episode_repository = Mock(spec=EpisodeRepository)

    statuses = [
        LibraryStatus.COMPLETED,
        LibraryStatus.DROPPED,
        LibraryStatus.PAUSED,
    ]

    entries = [
        create_library_entry(
            show=create_show(
                tmdb_id=100000 + index,
                title=f"Excluded {status.value}",
            ),
            status=status,
        )
        for index, status in enumerate(statuses)
    ]

    library_repository.list_shows_by_user.return_value = entries

    service = create_service(
        library_repository=library_repository,
        episode_repository=episode_repository,
    )

    result = service.list_for_user(
        user_id=uuid4(),
        from_date=date(2026, 8, 15),
    )

    assert result == []

    episode_repository.list_regular_for_shows_between.assert_not_called()


def test_returns_multiple_future_episodes_for_same_show() -> None:
    """Upcoming is a timeline, not only the next Episode per Show."""

    library_repository = Mock(spec=LibraryRepository)
    episode_repository = Mock(spec=EpisodeRepository)

    show = create_show()
    entry = create_library_entry(show=show)

    first_episode = create_episode(
        tmdb_id=2001,
        episode_number=1,
        title="Episode 1",
        air_date=date(2026, 8, 16),
    )

    second_episode = create_episode(
        tmdb_id=2002,
        episode_number=2,
        title="Episode 2",
        air_date=date(2026, 8, 23),
    )

    library_repository.list_shows_by_user.return_value = [entry]

    episode_repository.list_regular_for_shows_between.return_value = [
        TimelineEpisode(
            show_id=show.id,
            episode=first_episode,
            season_number=2,
        ),
        TimelineEpisode(
            show_id=show.id,
            episode=second_episode,
            season_number=2,
        ),
    ]

    service = create_service(
        library_repository=library_repository,
        episode_repository=episode_repository,
    )

    result = service.list_for_user(
        user_id=uuid4(),
        from_date=date(2026, 8, 15),
    )

    assert [item.episode.episode_number for item in result] == [
        1,
        2,
    ]


def test_orders_same_day_episodes_by_show_title_then_episode_position() -> None:
    """Use a stable human-friendly order when Episodes share an air date."""

    library_repository = Mock(spec=LibraryRepository)
    episode_repository = Mock(spec=EpisodeRepository)

    alpha_show = create_show(
        tmdb_id=100001,
        title="Alpha",
    )

    beta_show = create_show(
        tmdb_id=100002,
        title="Beta",
    )

    alpha_entry = create_library_entry(show=alpha_show)
    beta_entry = create_library_entry(show=beta_show)

    alpha_second = create_episode(
        tmdb_id=2002,
        episode_number=2,
        title="Alpha Two",
        air_date=date(2026, 8, 20),
    )

    alpha_first = create_episode(
        tmdb_id=2001,
        episode_number=1,
        title="Alpha One",
        air_date=date(2026, 8, 20),
    )

    beta_episode = create_episode(
        tmdb_id=3001,
        episode_number=1,
        title="Beta One",
        air_date=date(2026, 8, 20),
    )

    library_repository.list_shows_by_user.return_value = [
        beta_entry,
        alpha_entry,
    ]

    episode_repository.list_regular_for_shows_between.return_value = [
        TimelineEpisode(
            show_id=beta_show.id,
            episode=beta_episode,
            season_number=1,
        ),
        TimelineEpisode(
            show_id=alpha_show.id,
            episode=alpha_second,
            season_number=2,
        ),
        TimelineEpisode(
            show_id=alpha_show.id,
            episode=alpha_first,
            season_number=2,
        ),
    ]

    service = create_service(
        library_repository=library_repository,
        episode_repository=episode_repository,
    )

    result = service.list_for_user(
        user_id=uuid4(),
        from_date=date(2026, 8, 15),
    )

    assert [
        (
            item.show.title,
            item.episode.season_number,
            item.episode.episode_number,
        )
        for item in result
    ] == [
        ("Alpha", 2, 1),
        ("Alpha", 2, 2),
        ("Beta", 1, 1),
    ]


def test_forwards_explicit_date_range_to_episode_repository() -> None:
    """Forward caller-defined timeline boundaries unchanged."""

    library_repository = Mock(spec=LibraryRepository)
    episode_repository = Mock(spec=EpisodeRepository)

    show = create_show()
    entry = create_library_entry(show=show)

    library_repository.list_shows_by_user.return_value = [entry]
    episode_repository.list_regular_for_shows_between.return_value = []

    service = create_service(
        library_repository=library_repository,
        episode_repository=episode_repository,
    )

    service.list_for_user(
        user_id=uuid4(),
        from_date=date(2026, 8, 10),
        to_date=date(2026, 8, 20),
    )

    episode_repository.list_regular_for_shows_between.assert_called_once_with(
        show_ids=[show.id],
        from_date=date(2026, 8, 10),
        to_date=date(2026, 8, 20),
        limit=None,
    )


def test_returns_empty_when_no_eligible_library_shows_exist() -> None:
    """Avoid querying Episodes when the user has no eligible Shows."""

    library_repository = Mock(spec=LibraryRepository)
    episode_repository = Mock(spec=EpisodeRepository)

    library_repository.list_shows_by_user.return_value = []

    service = create_service(
        library_repository=library_repository,
        episode_repository=episode_repository,
    )

    result = service.list_for_user(
        user_id=uuid4(),
        from_date=date(2026, 8, 15),
    )

    assert result == []

    episode_repository.list_regular_for_shows_between.assert_not_called()


def test_returns_empty_when_no_timeline_episodes_are_known() -> None:
    """An eligible Show without dated Episodes produces no Upcoming item."""

    library_repository = Mock(spec=LibraryRepository)
    episode_repository = Mock(spec=EpisodeRepository)

    show = create_show()
    entry = create_library_entry(show=show)

    library_repository.list_shows_by_user.return_value = [entry]
    episode_repository.list_regular_for_shows_between.return_value = []

    service = create_service(
        library_repository=library_repository,
        episode_repository=episode_repository,
    )

    result = service.list_for_user(
        user_id=uuid4(),
        from_date=date(2026, 8, 15),
    )

    assert result == []


def test_marks_upcoming_episode_as_watched_when_user_has_watched_it() -> None:
    """Expose whether an Upcoming Episode has already been watched."""

    library_repository = Mock(spec=LibraryRepository)
    episode_repository = Mock(spec=EpisodeRepository)
    progress_repository = Mock(spec=EpisodeProgressRepository)

    show = create_show()

    entry = create_library_entry(
        show=show,
        status=LibraryStatus.WATCHING,
    )

    episode = create_episode(
        tmdb_id=2001,
        episode_number=3,
        title="Already Watched",
        air_date=date(2026, 8, 17),
    )

    library_repository.list_shows_by_user.return_value = [
        entry,
    ]

    episode_repository.list_regular_for_shows_between.return_value = [
        TimelineEpisode(
            show_id=show.id,
            episode=episode,
            season_number=2,
        ),
    ]

    progress_repository.get_watched_episode_ids.return_value = {
        episode.id,
    }

    service = create_service(
        library_repository=library_repository,
        episode_repository=episode_repository,
        progress_repository=progress_repository,
    )

    user_id = uuid4()

    result = service.list_for_user(
        user_id=user_id,
        from_date=date(2026, 8, 17),
        to_date=date(2026, 8, 17),
    )

    assert len(result) == 1

    assert result[0].episode.id == episode.id
    assert result[0].episode.is_watched is True

    progress_repository.get_watched_episode_ids.assert_called_once_with(
        user_id=user_id,
        episode_ids=[episode.id],
    )


def test_marks_upcoming_episode_as_unwatched_when_user_has_not_watched_it() -> None:
    """Expose an unwatched state when no watched progress exists."""

    library_repository = Mock(spec=LibraryRepository)
    episode_repository = Mock(spec=EpisodeRepository)
    progress_repository = Mock(spec=EpisodeProgressRepository)

    show = create_show()

    entry = create_library_entry(
        show=show,
        status=LibraryStatus.PLANNING,
    )

    episode = create_episode(
        tmdb_id=2001,
        episode_number=1,
        title="Not Watched Yet",
        air_date=date(2026, 8, 17),
    )

    library_repository.list_shows_by_user.return_value = [
        entry,
    ]

    episode_repository.list_regular_for_shows_between.return_value = [
        TimelineEpisode(
            show_id=show.id,
            episode=episode,
            season_number=1,
        ),
    ]

    progress_repository.get_watched_episode_ids.return_value = set()

    service = create_service(
        library_repository=library_repository,
        episode_repository=episode_repository,
        progress_repository=progress_repository,
    )

    user_id = uuid4()

    result = service.list_for_user(
        user_id=user_id,
        from_date=date(2026, 8, 17),
        to_date=date(2026, 8, 17),
    )

    assert len(result) == 1

    assert result[0].episode.id == episode.id
    assert result[0].episode.is_watched is False

    progress_repository.get_watched_episode_ids.assert_called_once_with(
        user_id=user_id,
        episode_ids=[episode.id],
    )


def test_forwards_explicit_limit_to_episode_repository() -> None:
    library_repository = Mock(spec=LibraryRepository)
    episode_repository = Mock(spec=EpisodeRepository)

    show = create_show()
    entry = create_library_entry(show=show)

    library_repository.list_shows_by_user.return_value = [entry]
    episode_repository.list_regular_for_shows_between.return_value = []

    service = create_service(
        library_repository=library_repository,
        episode_repository=episode_repository,
    )

    service.list_for_user(
        user_id=uuid4(),
        from_date=date(2026, 8, 18),
        to_date=date(2026, 8, 24),
        limit=6,
    )

    episode_repository.list_regular_for_shows_between.assert_called_once_with(
        show_ids=[show.id],
        from_date=date(2026, 8, 18),
        to_date=date(2026, 8, 24),
        limit=6,
    )
