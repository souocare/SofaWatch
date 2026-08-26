from datetime import UTC, datetime
from types import SimpleNamespace
from unittest.mock import Mock
from uuid import uuid4

from app.models.enums import LibraryStatus
from app.models.user import User
from app.services.data_export import DataExportService


def create_service(
    *,
    library_repository: Mock | None = None,
    episode_watch_event_repository: Mock | None = None,
    movie_watch_event_repository: Mock | None = None,
) -> tuple[
    DataExportService,
    Mock,
    Mock,
    Mock,
]:
    """Create a Data Export service with mocked repositories."""

    if library_repository is None:
        library_repository = Mock()

    if isinstance(
        library_repository.list_shows_by_user.return_value,
        Mock,
    ):
        library_repository.list_shows_by_user.return_value = []

    if isinstance(
        library_repository.list_movies_by_user.return_value,
        Mock,
    ):
        library_repository.list_movies_by_user.return_value = []

    if episode_watch_event_repository is None:
        episode_watch_event_repository = Mock()

    if isinstance(
        episode_watch_event_repository.list_all_for_user.return_value,
        Mock,
    ):
        episode_watch_event_repository.list_all_for_user.return_value = []

    if movie_watch_event_repository is None:
        movie_watch_event_repository = Mock()

    if isinstance(
        movie_watch_event_repository.list_all_for_user.return_value,
        Mock,
    ):
        movie_watch_event_repository.list_all_for_user.return_value = []

    service = DataExportService(
        library_repository=library_repository,
        episode_watch_event_repository=episode_watch_event_repository,
        movie_watch_event_repository=movie_watch_event_repository,
    )

    return (
        service,
        library_repository,
        episode_watch_event_repository,
        movie_watch_event_repository,
    )


def create_user() -> User:
    """Create the current user without persistence."""

    return User(
        id=uuid4(),
        display_name="Gonçalo",
        is_admin=True,
    )


def test_export_user_data_builds_versioned_export() -> None:
    """Build a SofaWatch export with stable format metadata."""

    (
        service,
        library_repository,
        episode_repository,
        movie_repository,
    ) = create_service()

    user = create_user()

    before_export = datetime.now(UTC)

    result = service.export_user_data(
        user=user,
    )

    after_export = datetime.now(UTC)

    assert result.format == "sofawatch-export"
    assert result.version == 1

    assert before_export <= result.exported_at <= after_export

    assert result.user.display_name == "Gonçalo"

    assert result.library.shows == []
    assert result.library.movies == []

    assert result.history.episodes == []
    assert result.history.movies == []

    library_repository.list_shows_by_user.assert_called_once_with(
        user.id,
    )

    library_repository.list_movies_by_user.assert_called_once_with(
        user.id,
    )

    episode_repository.list_all_for_user.assert_called_once_with(
        user_id=user.id,
    )

    movie_repository.list_all_for_user.assert_called_once_with(
        user_id=user.id,
    )


def test_export_user_data_exports_show_library_entries() -> None:
    """Export portable TV series Library data using TMDB identifiers."""

    library_repository = Mock()

    library_repository.list_shows_by_user.return_value = [
        SimpleNamespace(
            show=SimpleNamespace(
                tmdb_id=95396,
            ),
            status=LibraryStatus.WATCHING,
            started_at=datetime(
                2026,
                7,
                1,
                20,
                0,
                tzinfo=UTC,
            ),
            completed_at=None,
        ),
        SimpleNamespace(
            show=SimpleNamespace(
                tmdb_id=1396,
            ),
            status=LibraryStatus.COMPLETED,
            started_at=datetime(
                2026,
                1,
                5,
                19,
                0,
                tzinfo=UTC,
            ),
            completed_at=datetime(
                2026,
                2,
                10,
                22,
                30,
                tzinfo=UTC,
            ),
        ),
    ]

    (
        service,
        _,
        _,
        _,
    ) = create_service(
        library_repository=library_repository,
    )

    result = service.export_user_data(
        user=create_user(),
    )

    assert len(result.library.shows) == 2

    first_show = result.library.shows[0]

    assert first_show.tmdb_id == 95396
    assert first_show.status == LibraryStatus.WATCHING

    assert first_show.started_at == datetime(
        2026,
        7,
        1,
        20,
        0,
        tzinfo=UTC,
    )

    assert first_show.completed_at is None

    second_show = result.library.shows[1]

    assert second_show.tmdb_id == 1396
    assert second_show.status == LibraryStatus.COMPLETED

    assert second_show.completed_at == datetime(
        2026,
        2,
        10,
        22,
        30,
        tzinfo=UTC,
    )


def test_export_user_data_exports_movie_library_entries() -> None:
    """Export portable Movie Library data using TMDB identifiers."""

    library_repository = Mock()

    library_repository.list_movies_by_user.return_value = [
        SimpleNamespace(
            movie=SimpleNamespace(
                tmdb_id=438631,
            ),
            status=LibraryStatus.COMPLETED,
            started_at=datetime(
                2026,
                8,
                1,
                20,
                0,
                tzinfo=UTC,
            ),
            completed_at=datetime(
                2026,
                8,
                1,
                22,
                35,
                tzinfo=UTC,
            ),
        ),
        SimpleNamespace(
            movie=SimpleNamespace(
                tmdb_id=603,
            ),
            status=LibraryStatus.PLANNING,
            started_at=None,
            completed_at=None,
        ),
    ]

    (
        service,
        _,
        _,
        _,
    ) = create_service(
        library_repository=library_repository,
    )

    result = service.export_user_data(
        user=create_user(),
    )

    assert len(result.library.movies) == 2

    first_movie = result.library.movies[0]

    assert first_movie.tmdb_id == 438631
    assert first_movie.status == LibraryStatus.COMPLETED

    assert first_movie.started_at == datetime(
        2026,
        8,
        1,
        20,
        0,
        tzinfo=UTC,
    )

    assert first_movie.completed_at == datetime(
        2026,
        8,
        1,
        22,
        35,
        tzinfo=UTC,
    )

    second_movie = result.library.movies[1]

    assert second_movie.tmdb_id == 603
    assert second_movie.status == LibraryStatus.PLANNING
    assert second_movie.started_at is None
    assert second_movie.completed_at is None


def test_export_user_data_exports_episode_watch_history() -> None:
    """Export Episode viewing history using portable media identifiers."""

    episode_repository = Mock()

    episode_repository.list_all_for_user.return_value = [
        SimpleNamespace(
            show=SimpleNamespace(
                tmdb_id=95396,
            ),
            season_number=1,
            episode=SimpleNamespace(
                tmdb_id=2101,
                episode_number=1,
            ),
            watched_at=datetime(
                2026,
                7,
                20,
                20,
                0,
                tzinfo=UTC,
            ),
        ),
        SimpleNamespace(
            show=SimpleNamespace(
                tmdb_id=95396,
            ),
            season_number=1,
            episode=SimpleNamespace(
                tmdb_id=2102,
                episode_number=2,
            ),
            watched_at=datetime(
                2026,
                7,
                20,
                21,
                0,
                tzinfo=UTC,
            ),
        ),
    ]

    (
        service,
        _,
        _,
        _,
    ) = create_service(
        episode_watch_event_repository=episode_repository,
    )

    result = service.export_user_data(
        user=create_user(),
    )

    assert len(result.history.episodes) == 2

    first_event = result.history.episodes[0]

    assert first_event.show_tmdb_id == 95396
    assert first_event.season_number == 1
    assert first_event.episode_number == 1
    assert first_event.episode_tmdb_id == 2101

    assert first_event.watched_at == datetime(
        2026,
        7,
        20,
        20,
        0,
        tzinfo=UTC,
    )

    second_event = result.history.episodes[1]

    assert second_event.show_tmdb_id == 95396
    assert second_event.season_number == 1
    assert second_event.episode_number == 2
    assert second_event.episode_tmdb_id == 2102


def test_export_user_data_exports_movie_watch_history() -> None:
    """Export Movie viewing history using portable TMDB identifiers."""

    movie_repository = Mock()

    movie_repository.list_all_for_user.return_value = [
        SimpleNamespace(
            movie=SimpleNamespace(
                tmdb_id=438631,
            ),
            watched_at=datetime(
                2026,
                8,
                1,
                20,
                0,
                tzinfo=UTC,
            ),
        ),
        SimpleNamespace(
            movie=SimpleNamespace(
                tmdb_id=603,
            ),
            watched_at=datetime(
                2026,
                8,
                5,
                21,
                30,
                tzinfo=UTC,
            ),
        ),
    ]

    (
        service,
        _,
        _,
        _,
    ) = create_service(
        movie_watch_event_repository=movie_repository,
    )

    result = service.export_user_data(
        user=create_user(),
    )

    assert len(result.history.movies) == 2

    first_event = result.history.movies[0]

    assert first_event.movie_tmdb_id == 438631

    assert first_event.watched_at == datetime(
        2026,
        8,
        1,
        20,
        0,
        tzinfo=UTC,
    )

    second_event = result.history.movies[1]

    assert second_event.movie_tmdb_id == 603

    assert second_event.watched_at == datetime(
        2026,
        8,
        5,
        21,
        30,
        tzinfo=UTC,
    )


def test_export_user_data_preserves_episode_rewatches() -> None:
    """Keep repeated Episode viewings as independent exported events."""

    episode_repository = Mock()

    episode_repository.list_all_for_user.return_value = [
        SimpleNamespace(
            show=SimpleNamespace(
                tmdb_id=95396,
            ),
            season_number=1,
            episode=SimpleNamespace(
                tmdb_id=2101,
                episode_number=1,
            ),
            watched_at=datetime(
                2026,
                7,
                20,
                20,
                0,
                tzinfo=UTC,
            ),
        ),
        SimpleNamespace(
            show=SimpleNamespace(
                tmdb_id=95396,
            ),
            season_number=1,
            episode=SimpleNamespace(
                tmdb_id=2101,
                episode_number=1,
            ),
            watched_at=datetime(
                2026,
                8,
                14,
                21,
                30,
                tzinfo=UTC,
            ),
        ),
    ]

    (
        service,
        _,
        _,
        _,
    ) = create_service(
        episode_watch_event_repository=episode_repository,
    )

    result = service.export_user_data(
        user=create_user(),
    )

    assert len(result.history.episodes) == 2

    assert [
        event.episode_tmdb_id
        for event in result.history.episodes
    ] == [
        2101,
        2101,
    ]

    assert [
        event.watched_at
        for event in result.history.episodes
    ] == [
        datetime(
            2026,
            7,
            20,
            20,
            0,
            tzinfo=UTC,
        ),
        datetime(
            2026,
            8,
            14,
            21,
            30,
            tzinfo=UTC,
        ),
    ]


def test_export_user_data_preserves_movie_rewatches() -> None:
    """Keep repeated Movie viewings as independent exported events."""

    movie_repository = Mock()

    movie_repository.list_all_for_user.return_value = [
        SimpleNamespace(
            movie=SimpleNamespace(
                tmdb_id=438631,
            ),
            watched_at=datetime(
                2026,
                8,
                1,
                20,
                0,
                tzinfo=UTC,
            ),
        ),
        SimpleNamespace(
            movie=SimpleNamespace(
                tmdb_id=438631,
            ),
            watched_at=datetime(
                2026,
                8,
                14,
                21,
                30,
                tzinfo=UTC,
            ),
        ),
    ]

    (
        service,
        _,
        _,
        _,
    ) = create_service(
        movie_watch_event_repository=movie_repository,
    )

    result = service.export_user_data(
        user=create_user(),
    )

    assert len(result.history.movies) == 2

    assert [
        event.movie_tmdb_id
        for event in result.history.movies
    ] == [
        438631,
        438631,
    ]

    assert [
        event.watched_at
        for event in result.history.movies
    ] == [
        datetime(
            2026,
            8,
            1,
            20,
            0,
            tzinfo=UTC,
        ),
        datetime(
            2026,
            8,
            14,
            21,
            30,
            tzinfo=UTC,
        ),
    ]


def test_export_user_data_keeps_special_episode_history() -> None:
    """Preserve Specials in a complete user data export."""

    episode_repository = Mock()

    episode_repository.list_all_for_user.return_value = [
        SimpleNamespace(
            show=SimpleNamespace(
                tmdb_id=95396,
            ),
            season_number=0,
            episode=SimpleNamespace(
                tmdb_id=999001,
                episode_number=1,
            ),
            watched_at=datetime(
                2026,
                6,
                1,
                20,
                0,
                tzinfo=UTC,
            ),
        ),
    ]

    (
        service,
        _,
        _,
        _,
    ) = create_service(
        episode_watch_event_repository=episode_repository,
    )

    result = service.export_user_data(
        user=create_user(),
    )

    assert len(result.history.episodes) == 1

    event = result.history.episodes[0]

    assert event.show_tmdb_id == 95396
    assert event.season_number == 0
    assert event.episode_number == 1
    assert event.episode_tmdb_id == 999001


def test_export_user_data_skips_invalid_unloaded_library_targets() -> None:
    """Ignore malformed Library entries without their referenced media."""

    library_repository = Mock()

    library_repository.list_shows_by_user.return_value = [
        SimpleNamespace(
            show=None,
            status=LibraryStatus.WATCHING,
            started_at=None,
            completed_at=None,
        ),
    ]

    library_repository.list_movies_by_user.return_value = [
        SimpleNamespace(
            movie=None,
            status=LibraryStatus.PLANNING,
            started_at=None,
            completed_at=None,
        ),
    ]

    (
        service,
        _,
        _,
        _,
    ) = create_service(
        library_repository=library_repository,
    )

    result = service.export_user_data(
        user=create_user(),
    )

    assert result.library.shows == []
    assert result.library.movies == []


def test_export_json_contains_only_portable_user_data() -> None:
    """Serialize the export without internal SofaWatch identifiers."""

    library_repository = Mock()

    library_repository.list_shows_by_user.return_value = [
        SimpleNamespace(
            show=SimpleNamespace(
                tmdb_id=95396,
            ),
            status=LibraryStatus.WATCHING,
            started_at=None,
            completed_at=None,
        ),
    ]

    (
        service,
        _,
        _,
        _,
    ) = create_service(
        library_repository=library_repository,
    )

    user = create_user()

    result = service.export_user_data(
        user=user,
    )

    payload = result.model_dump(
        mode="json",
    )

    assert payload["format"] == "sofawatch-export"
    assert payload["version"] == 1

    assert payload["user"] == {
        "display_name": "Gonçalo",
    }

    assert payload["library"]["shows"][0] == {
        "tmdb_id": 95396,
        "status": "watching",
        "started_at": None,
        "completed_at": None,
    }

    serialized = result.model_dump_json()

    assert str(user.id) not in serialized

    assert '"rating"' not in serialized