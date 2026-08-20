from datetime import UTC, datetime
from types import SimpleNamespace
from unittest.mock import Mock
from uuid import uuid4

from app.models.enums import LibraryStatus
from app.models.library import LibraryEntry
from app.models.movie_watch_event import MovieWatchEvent
from app.schemas.data_export import (
    ExportEpisodeWatchEventResponse,
    ExportLibraryMovieResponse,
    ExportLibraryResponse,
    ExportLibraryShowResponse,
    ExportMovieWatchEventResponse,
    ExportUserResponse,
    ExportWatchHistoryResponse,
    SofaWatchExportResponse,
)
from app.services.data_import import DataImportService
from app.models.episode_watch_event import EpisodeWatchEvent
from app.models.episode_progress import EpisodeProgress


def create_service(
    *,
    library_repository: Mock | None = None,
    show_repository: Mock | None = None,
    movie_repository: Mock | None = None,
    show_import_service: Mock | None = None,
    movie_import_service: Mock | None = None,
    movie_watch_event_repository: Mock | None = None,
    season_repository: Mock | None = None,
    episode_repository: Mock | None = None,
    episode_watch_event_repository: Mock | None = None,
    episode_progress_repository: Mock | None = None,
    season_episode_sync_service: Mock | None = None,
) -> tuple[
    DataImportService,
    Mock,
    Mock,
    Mock,
    Mock,
    Mock,
    Mock,
    Mock,
    Mock,
    Mock,
    Mock,
    Mock,
    Mock,
]:
    """Create a Data Import service with mocked dependencies."""

    session = Mock()

    library_repository = library_repository or Mock()
    show_repository = show_repository or Mock()
    movie_repository = movie_repository or Mock()

    show_import_service = show_import_service or Mock()
    movie_import_service = movie_import_service or Mock()

    movie_watch_event_repository = (
        movie_watch_event_repository
        or Mock()
    )

    season_repository = season_repository or Mock()
    episode_repository = episode_repository or Mock()

    episode_watch_event_repository = (
        episode_watch_event_repository
        or Mock()
    )

    if episode_progress_repository is None:
        episode_progress_repository = Mock()
        episode_progress_repository.get_by_user_and_episode.return_value = None

    season_episode_sync_service = (
        season_episode_sync_service
        or Mock()
    )

    service = DataImportService(
        session=session,
        library_repository=library_repository,
        show_repository=show_repository,
        movie_repository=movie_repository,
        show_import_service=show_import_service,
        movie_import_service=movie_import_service,
        movie_watch_event_repository=movie_watch_event_repository,
        season_repository=season_repository,
        episode_repository=episode_repository,
        episode_watch_event_repository=episode_watch_event_repository,
        episode_progress_repository=episode_progress_repository,
        season_episode_sync_service=season_episode_sync_service,
    )

    return (
        service,
        session,
        library_repository,
        show_repository,
        movie_repository,
        show_import_service,
        movie_import_service,
        movie_watch_event_repository,
        season_repository,
        episode_repository,
        episode_watch_event_repository,
        episode_progress_repository,
        season_episode_sync_service,
    )


def _create_export(
    *,
    shows: list[ExportLibraryShowResponse] | None = None,
    movies: list[ExportLibraryMovieResponse] | None = None,
) -> SofaWatchExportResponse:
    return SofaWatchExportResponse(
        exported_at=datetime(
            2026,
            8,
            20,
            15,
            30,
            tzinfo=UTC,
        ),
        user=ExportUserResponse(
            display_name="Gonçalo",
        ),
        library=ExportLibraryResponse(
            shows=shows or [],
            movies=movies or [],
        ),
        history=ExportWatchHistoryResponse(
            episodes=[],
            movies=[],
        ),
    )


def test_preview_returns_import_summary() -> None:
    """Summarize a validated SofaWatch import without modifying data."""

    service, *_ = create_service()

    export = SofaWatchExportResponse(
        exported_at=datetime(
            2026,
            8,
            20,
            15,
            30,
            tzinfo=UTC,
        ),
        user=ExportUserResponse(
            display_name="Gonçalo",
        ),
        library=ExportLibraryResponse(
            shows=[
                ExportLibraryShowResponse(
                    tmdb_id=95396,
                    status=LibraryStatus.WATCHING,
                ),
                ExportLibraryShowResponse(
                    tmdb_id=1396,
                    status=LibraryStatus.COMPLETED,
                ),
            ],
            movies=[
                ExportLibraryMovieResponse(
                    tmdb_id=438631,
                    status=LibraryStatus.COMPLETED,
                ),
            ],
        ),
        history=ExportWatchHistoryResponse(
            episodes=[
                ExportEpisodeWatchEventResponse(
                    show_tmdb_id=95396,
                    season_number=1,
                    episode_number=1,
                    episode_tmdb_id=2101,
                    watched_at=datetime(
                        2026,
                        8,
                        1,
                        20,
                        0,
                        tzinfo=UTC,
                    ),
                ),
                ExportEpisodeWatchEventResponse(
                    show_tmdb_id=95396,
                    season_number=1,
                    episode_number=1,
                    episode_tmdb_id=2101,
                    watched_at=datetime(
                        2026,
                        8,
                        10,
                        20,
                        0,
                        tzinfo=UTC,
                    ),
                ),
            ],
            movies=[
                ExportMovieWatchEventResponse(
                    movie_tmdb_id=438631,
                    watched_at=datetime(
                        2026,
                        8,
                        1,
                        22,
                        0,
                        tzinfo=UTC,
                    ),
                ),
            ],
        ),
    )

    result = service.preview(
        export=export,
    )

    assert result.format == "sofawatch-export"
    assert result.version == 1
    assert result.user_display_name == "Gonçalo"

    assert result.summary.library_shows == 2
    assert result.summary.library_movies == 1
    assert result.summary.episode_watch_events == 2
    assert result.summary.movie_watch_events == 1


def test_preview_supports_empty_export() -> None:
    """Preview a valid SofaWatch export containing no personal media data."""

    service, *_ = create_service()

    export = SofaWatchExportResponse(
        exported_at=datetime(
            2026,
            8,
            20,
            15,
            30,
            tzinfo=UTC,
        ),
        user=ExportUserResponse(
            display_name="Gonçalo",
        ),
        library=ExportLibraryResponse(
            shows=[],
            movies=[],
        ),
        history=ExportWatchHistoryResponse(
            episodes=[],
            movies=[],
        ),
    )

    result = service.preview(
        export=export,
    )

    assert result.summary.library_shows == 0
    assert result.summary.library_movies == 0
    assert result.summary.episode_watch_events == 0
    assert result.summary.movie_watch_events == 0


def test_import_library_creates_missing_show_entry() -> None:
    """Import a Show into the current user's Library."""

    show_id = uuid4()
    user_id = uuid4()

    show_repository = Mock()
    show_repository.get_by_tmdb_id.return_value = None

    show_import_service = Mock()
    show_import_service.import_show.return_value = SimpleNamespace(
        id=show_id,
        tmdb_id=95396,
    )

    library_repository = Mock()
    library_repository.get_by_user_and_show.return_value = None

    service, session, *_ = create_service(
        library_repository=library_repository,
        show_repository=show_repository,
        show_import_service=show_import_service,
    )

    export = _create_export(
        shows=[
            ExportLibraryShowResponse(
                tmdb_id=95396,
                status=LibraryStatus.WATCHING,
                started_at=datetime(
                    2026,
                    7,
                    1,
                    20,
                    0,
                    tzinfo=UTC,
                ),
            ),
        ],
    )

    result = service.import_library(
        user_id=user_id,
        export=export,
    )

    assert result.shows.created == 1
    assert result.shows.updated == 0
    assert result.shows.unchanged == 0

    show_import_service.import_show.assert_called_once_with(
        tmdb_id=95396,
    )

    library_repository.add.assert_called_once()

    created_entry = library_repository.add.call_args.args[0]

    assert created_entry.user_id == user_id
    assert created_entry.show_id == show_id
    assert created_entry.movie_id is None
    assert created_entry.status == LibraryStatus.WATCHING

    session.commit.assert_called_once()


def test_import_library_reuses_existing_local_show() -> None:
    """Reuse locally stored Show metadata during Library import."""

    show_id = uuid4()
    user_id = uuid4()

    show_repository = Mock()
    show_repository.get_by_tmdb_id.return_value = SimpleNamespace(
        id=show_id,
        tmdb_id=95396,
    )

    library_repository = Mock()
    library_repository.get_by_user_and_show.return_value = None

    show_import_service = Mock()

    service, *_ = create_service(
        library_repository=library_repository,
        show_repository=show_repository,
        show_import_service=show_import_service,
    )

    service.import_library(
        user_id=user_id,
        export=_create_export(
            shows=[
                ExportLibraryShowResponse(
                    tmdb_id=95396,
                    status=LibraryStatus.PLANNING,
                ),
            ],
        ),
    )

    show_import_service.import_show.assert_not_called()


def test_import_library_merges_existing_show_entry() -> None:
    """Merge imported Show tracking state into an existing Library entry."""

    show_id = uuid4()
    user_id = uuid4()

    local_started_at = datetime(
        2026,
        5,
        1,
        20,
        0,
        tzinfo=UTC,
    )

    entry = LibraryEntry(
        user_id=user_id,
        show_id=show_id,
        status=LibraryStatus.WATCHING,
        started_at=local_started_at,
        completed_at=None,
    )

    show_repository = Mock()
    show_repository.get_by_tmdb_id.return_value = SimpleNamespace(
        id=show_id,
        tmdb_id=95396,
    )

    library_repository = Mock()
    library_repository.get_by_user_and_show.return_value = entry

    service, session, *_ = create_service(
        library_repository=library_repository,
        show_repository=show_repository,
    )

    imported_completed_at = datetime(
        2026,
        8,
        10,
        22,
        0,
        tzinfo=UTC,
    )

    result = service.import_library(
        user_id=user_id,
        export=_create_export(
            shows=[
                ExportLibraryShowResponse(
                    tmdb_id=95396,
                    status=LibraryStatus.COMPLETED,
                    started_at=None,
                    completed_at=imported_completed_at,
                ),
            ],
        ),
    )

    assert result.shows.created == 0
    assert result.shows.updated == 1
    assert result.shows.unchanged == 0

    assert entry.status == LibraryStatus.COMPLETED

    # Missing imported value does not destroy useful local history.
    assert entry.started_at == local_started_at
    assert entry.completed_at == imported_completed_at

    session.commit.assert_called_once()


def test_import_library_keeps_matching_show_unchanged() -> None:
    """Treat an already matching Library entry as an idempotent import."""

    show_id = uuid4()
    user_id = uuid4()

    started_at = datetime(
        2026,
        7,
        1,
        20,
        0,
        tzinfo=UTC,
    )

    entry = LibraryEntry(
        user_id=user_id,
        show_id=show_id,
        status=LibraryStatus.WATCHING,
        started_at=started_at,
        completed_at=None,
    )

    show_repository = Mock()
    show_repository.get_by_tmdb_id.return_value = SimpleNamespace(
        id=show_id,
        tmdb_id=95396,
    )

    library_repository = Mock()
    library_repository.get_by_user_and_show.return_value = entry

    service, session, *_ = create_service(
        library_repository=library_repository,
        show_repository=show_repository,
    )

    result = service.import_library(
        user_id=user_id,
        export=_create_export(
            shows=[
                ExportLibraryShowResponse(
                    tmdb_id=95396,
                    status=LibraryStatus.WATCHING,
                    started_at=started_at,
                ),
            ],
        ),
    )

    assert result.shows.unchanged == 1

    session.commit.assert_not_called()


def test_import_library_creates_missing_movie_entry() -> None:
    """Import a Movie into the current user's Library."""

    movie_id = uuid4()
    user_id = uuid4()

    movie_repository = Mock()
    movie_repository.get_by_tmdb_id.return_value = None

    movie_import_service = Mock()
    movie_import_service.import_movie.return_value = SimpleNamespace(
        id=movie_id,
        tmdb_id=438631,
    )

    library_repository = Mock()
    library_repository.get_by_user_and_movie.return_value = None

    service, *_ = create_service(
        library_repository=library_repository,
        movie_repository=movie_repository,
        movie_import_service=movie_import_service,
    )

    result = service.import_library(
        user_id=user_id,
        export=_create_export(
            movies=[
                ExportLibraryMovieResponse(
                    tmdb_id=438631,
                    status=LibraryStatus.COMPLETED,
                    completed_at=datetime(
                        2026,
                        8,
                        1,
                        22,
                        35,
                        tzinfo=UTC,
                    ),
                ),
            ],
        ),
    )

    assert result.movies.created == 1

    movie_import_service.import_movie.assert_called_once_with(
        tmdb_id=438631,
    )

    created_entry = library_repository.add.call_args.args[0]

    assert created_entry.movie_id == movie_id
    assert created_entry.show_id is None
    assert created_entry.status == LibraryStatus.COMPLETED


def test_import_history_creates_missing_movie_watch_event() -> None:
    """Restore a missing historical Movie viewing."""

    user_id = uuid4()
    movie_id = uuid4()

    movie_repository = Mock()
    movie_repository.get_by_tmdb_id.return_value = SimpleNamespace(
        id=movie_id,
        tmdb_id=438631,
    )

    movie_watch_event_repository = Mock()
    movie_watch_event_repository.exists_at.return_value = False

    service, session, *_ = create_service(
        movie_repository=movie_repository,
        movie_watch_event_repository=movie_watch_event_repository,
    )

    watched_at = datetime(
        2026,
        8,
        1,
        22,
        0,
        tzinfo=UTC,
    )

    export = SofaWatchExportResponse(
        exported_at=datetime(
            2026,
            8,
            20,
            15,
            30,
            tzinfo=UTC,
        ),
        user=ExportUserResponse(
            display_name="Gonçalo",
        ),
        library=ExportLibraryResponse(
            shows=[],
            movies=[],
        ),
        history=ExportWatchHistoryResponse(
            episodes=[],
            movies=[
                ExportMovieWatchEventResponse(
                    movie_tmdb_id=438631,
                    watched_at=watched_at,
                ),
            ],
        ),
    )

    result = service.import_history(
        user_id=user_id,
        export=export,
    )

    assert result.movies.created == 1
    assert result.movies.skipped == 0

    assert result.episodes.created == 0
    assert result.episodes.skipped == 0

    movie_watch_event_repository.exists_at.assert_called_once_with(
        user_id=user_id,
        movie_id=movie_id,
        watched_at=watched_at,
    )

    movie_watch_event_repository.add.assert_called_once()

    event = movie_watch_event_repository.add.call_args.args[0]

    assert isinstance(
        event,
        MovieWatchEvent,
    )

    assert event.user_id == user_id
    assert event.movie_id == movie_id
    assert event.watched_at == watched_at

    session.commit.assert_called_once()


def test_import_history_skips_existing_movie_watch_event() -> None:
    """Keep Movie History import idempotent."""

    user_id = uuid4()
    movie_id = uuid4()

    watched_at = datetime(
        2026,
        8,
        1,
        22,
        0,
        tzinfo=UTC,
    )

    movie_repository = Mock()
    movie_repository.get_by_tmdb_id.return_value = SimpleNamespace(
        id=movie_id,
        tmdb_id=438631,
    )

    movie_watch_event_repository = Mock()
    movie_watch_event_repository.exists_at.return_value = True

    service, session, *_ = create_service(
        movie_repository=movie_repository,
        movie_watch_event_repository=movie_watch_event_repository,
    )

    result = service.import_history(
        user_id=user_id,
        export=SofaWatchExportResponse(
            exported_at=datetime(
                2026,
                8,
                20,
                15,
                30,
                tzinfo=UTC,
            ),
            user=ExportUserResponse(
                display_name="Gonçalo",
            ),
            library=ExportLibraryResponse(
                shows=[],
                movies=[],
            ),
            history=ExportWatchHistoryResponse(
                episodes=[],
                movies=[
                    ExportMovieWatchEventResponse(
                        movie_tmdb_id=438631,
                        watched_at=watched_at,
                    ),
                ],
            ),
        ),
    )

    assert result.movies.created == 0
    assert result.movies.skipped == 1

    movie_watch_event_repository.add.assert_not_called()

    session.commit.assert_not_called()


def test_import_history_imports_missing_movie_metadata() -> None:
    """Materialize a missing Movie before restoring its History."""

    user_id = uuid4()
    movie_id = uuid4()

    movie_repository = Mock()
    movie_repository.get_by_tmdb_id.return_value = None

    movie_import_service = Mock()
    movie_import_service.import_movie.return_value = SimpleNamespace(
        id=movie_id,
        tmdb_id=438631,
    )

    movie_watch_event_repository = Mock()
    movie_watch_event_repository.exists_at.return_value = False

    service, *_ = create_service(
        movie_repository=movie_repository,
        movie_import_service=movie_import_service,
        movie_watch_event_repository=movie_watch_event_repository,
    )

    export = SofaWatchExportResponse(
        exported_at=datetime(
            2026,
            8,
            20,
            15,
            30,
            tzinfo=UTC,
        ),
        user=ExportUserResponse(
            display_name="Gonçalo",
        ),
        library=ExportLibraryResponse(
            shows=[],
            movies=[],
        ),
        history=ExportWatchHistoryResponse(
            episodes=[],
            movies=[
                ExportMovieWatchEventResponse(
                    movie_tmdb_id=438631,
                    watched_at=datetime(
                        2026,
                        8,
                        1,
                        22,
                        0,
                        tzinfo=UTC,
                    ),
                ),
            ],
        ),
    )

    service.import_history(
        user_id=user_id,
        export=export,
    )

    movie_import_service.import_movie.assert_called_once_with(
        tmdb_id=438631,
    )


def test_import_history_preserves_movie_rewatches() -> None:
    """Restore different Movie viewing timestamps as independent events."""

    user_id = uuid4()
    movie_id = uuid4()

    movie_repository = Mock()
    movie_repository.get_by_tmdb_id.return_value = SimpleNamespace(
        id=movie_id,
        tmdb_id=438631,
    )

    movie_watch_event_repository = Mock()
    movie_watch_event_repository.exists_at.return_value = False

    service, session, *_ = create_service(
        movie_repository=movie_repository,
        movie_watch_event_repository=movie_watch_event_repository,
    )

    first_watched_at = datetime(
        2026,
        8,
        1,
        20,
        0,
        tzinfo=UTC,
    )

    second_watched_at = datetime(
        2026,
        8,
        14,
        21,
        30,
        tzinfo=UTC,
    )

    export = SofaWatchExportResponse(
        exported_at=datetime(
            2026,
            8,
            20,
            15,
            30,
            tzinfo=UTC,
        ),
        user=ExportUserResponse(
            display_name="Gonçalo",
        ),
        library=ExportLibraryResponse(
            shows=[],
            movies=[],
        ),
        history=ExportWatchHistoryResponse(
            episodes=[],
            movies=[
                ExportMovieWatchEventResponse(
                    movie_tmdb_id=438631,
                    watched_at=first_watched_at,
                ),
                ExportMovieWatchEventResponse(
                    movie_tmdb_id=438631,
                    watched_at=second_watched_at,
                ),
            ],
        ),
    )

    result = service.import_history(
        user_id=user_id,
        export=export,
    )

    assert result.movies.created == 2
    assert result.movies.skipped == 0

    assert movie_watch_event_repository.add.call_count == 2
    assert session.commit.call_count == 2

    created_events = [
        call.args[0]
        for call in movie_watch_event_repository.add.call_args_list
    ]

    assert [
        event.watched_at
        for event in created_events
    ] == [
        first_watched_at,
        second_watched_at,
    ]

def test_import_history_creates_missing_episode_watch_event() -> None:
    """Restore a missing historical Episode viewing."""

    user_id = uuid4()
    show_id = uuid4()
    season_id = uuid4()
    episode_id = uuid4()

    watched_at = datetime(
        2026,
        8,
        1,
        20,
        0,
        tzinfo=UTC,
    )

    show_repository = Mock()
    show_repository.get_by_tmdb_id.return_value = SimpleNamespace(
        id=show_id,
        tmdb_id=95396,
    )

    season_repository = Mock()
    season_repository.get_by_number.return_value = SimpleNamespace(
        id=season_id,
        show_id=show_id,
        season_number=1,
    )

    episode_repository = Mock()
    episode_repository.get_by_tmdb_id.return_value = SimpleNamespace(
        id=episode_id,
        season_id=season_id,
        tmdb_id=2101,
        episode_number=1,
    )

    episode_watch_event_repository = Mock()
    episode_watch_event_repository.exists_at.return_value = False

    service, session, *_ = create_service(
        show_repository=show_repository,
        season_repository=season_repository,
        episode_repository=episode_repository,
        episode_watch_event_repository=episode_watch_event_repository,
    )

    export = SofaWatchExportResponse(
        exported_at=datetime(
            2026,
            8,
            20,
            15,
            30,
            tzinfo=UTC,
        ),
        user=ExportUserResponse(
            display_name="Gonçalo",
        ),
        library=ExportLibraryResponse(
            shows=[],
            movies=[],
        ),
        history=ExportWatchHistoryResponse(
            episodes=[
                ExportEpisodeWatchEventResponse(
                    show_tmdb_id=95396,
                    season_number=1,
                    episode_number=1,
                    episode_tmdb_id=2101,
                    watched_at=watched_at,
                ),
            ],
            movies=[],
        ),
    )

    result = service.import_history(
        user_id=user_id,
        export=export,
    )

    assert result.episodes.created == 1
    assert result.episodes.skipped == 0

    assert result.movies.created == 0
    assert result.movies.skipped == 0

    show_repository.get_by_tmdb_id.assert_called_once_with(
        95396,
    )

    season_repository.get_by_number.assert_called_once_with(
        show_id=show_id,
        season_number=1,
    )

    episode_repository.get_by_tmdb_id.assert_called_once_with(
        2101,
    )

    episode_watch_event_repository.exists_at.assert_called_once_with(
        user_id=user_id,
        episode_id=episode_id,
        watched_at=watched_at,
    )

    episode_watch_event_repository.add.assert_called_once()

    event = episode_watch_event_repository.add.call_args.args[0]

    assert isinstance(
        event,
        EpisodeWatchEvent,
    )

    assert event.user_id == user_id
    assert event.episode_id == episode_id
    assert event.watched_at == watched_at

    session.commit.assert_called_once()


def test_import_history_skips_existing_episode_watch_event() -> None:
    """Keep Episode History import idempotent."""

    user_id = uuid4()
    show_id = uuid4()
    season_id = uuid4()
    episode_id = uuid4()

    watched_at = datetime(
        2026,
        8,
        1,
        20,
        0,
        tzinfo=UTC,
    )

    show_repository = Mock()
    show_repository.get_by_tmdb_id.return_value = SimpleNamespace(
        id=show_id,
        tmdb_id=95396,
    )

    season_repository = Mock()
    season_repository.get_by_number.return_value = SimpleNamespace(
        id=season_id,
        show_id=show_id,
        season_number=1,
    )

    episode_repository = Mock()
    episode_repository.get_by_tmdb_id.return_value = SimpleNamespace(
        id=episode_id,
        season_id=season_id,
        tmdb_id=2101,
        episode_number=1,
    )

    episode_watch_event_repository = Mock()
    episode_watch_event_repository.exists_at.return_value = True

    service, session, *_ = create_service(
        show_repository=show_repository,
        season_repository=season_repository,
        episode_repository=episode_repository,
        episode_watch_event_repository=episode_watch_event_repository,
    )

    export = SofaWatchExportResponse(
        exported_at=datetime(
            2026,
            8,
            20,
            15,
            30,
            tzinfo=UTC,
        ),
        user=ExportUserResponse(
            display_name="Gonçalo",
        ),
        library=ExportLibraryResponse(
            shows=[],
            movies=[],
        ),
        history=ExportWatchHistoryResponse(
            episodes=[
                ExportEpisodeWatchEventResponse(
                    show_tmdb_id=95396,
                    season_number=1,
                    episode_number=1,
                    episode_tmdb_id=2101,
                    watched_at=watched_at,
                ),
            ],
            movies=[],
        ),
    )

    result = service.import_history(
        user_id=user_id,
        export=export,
    )

    assert result.episodes.created == 0
    assert result.episodes.skipped == 1

    assert result.movies.created == 0
    assert result.movies.skipped == 0

    episode_watch_event_repository.exists_at.assert_called_once_with(
        user_id=user_id,
        episode_id=episode_id,
        watched_at=watched_at,
    )

    episode_watch_event_repository.add.assert_not_called()

    session.commit.assert_not_called()

def test_import_history_imports_missing_show_for_episode() -> None:
    """Materialize a missing Show before restoring Episode History."""

    user_id = uuid4()
    show_id = uuid4()
    season_id = uuid4()
    episode_id = uuid4()

    watched_at = datetime(
        2026,
        8,
        1,
        20,
        0,
        tzinfo=UTC,
    )

    show_repository = Mock()
    show_repository.get_by_tmdb_id.return_value = None

    show_import_service = Mock()
    show_import_service.import_show.return_value = SimpleNamespace(
        id=show_id,
        tmdb_id=95396,
    )

    season_repository = Mock()
    season_repository.get_by_number.return_value = SimpleNamespace(
        id=season_id,
        show_id=show_id,
        season_number=1,
    )

    episode_repository = Mock()
    episode_repository.get_by_tmdb_id.return_value = SimpleNamespace(
        id=episode_id,
        season_id=season_id,
        tmdb_id=2101,
        episode_number=1,
    )

    episode_watch_event_repository = Mock()
    episode_watch_event_repository.exists_at.return_value = False

    service, session, *_ = create_service(
        show_repository=show_repository,
        show_import_service=show_import_service,
        season_repository=season_repository,
        episode_repository=episode_repository,
        episode_watch_event_repository=episode_watch_event_repository,
    )

    export = SofaWatchExportResponse(
        exported_at=datetime(
            2026,
            8,
            20,
            15,
            30,
            tzinfo=UTC,
        ),
        user=ExportUserResponse(
            display_name="Gonçalo",
        ),
        library=ExportLibraryResponse(
            shows=[],
            movies=[],
        ),
        history=ExportWatchHistoryResponse(
            episodes=[
                ExportEpisodeWatchEventResponse(
                    show_tmdb_id=95396,
                    season_number=1,
                    episode_number=1,
                    episode_tmdb_id=2101,
                    watched_at=watched_at,
                ),
            ],
            movies=[],
        ),
    )

    result = service.import_history(
        user_id=user_id,
        export=export,
    )

    assert result.episodes.created == 1
    assert result.episodes.skipped == 0

    show_import_service.import_show.assert_called_once_with(
        tmdb_id=95396,
    )

    season_repository.get_by_number.assert_called_once_with(
        show_id=show_id,
        season_number=1,
    )

    episode_watch_event_repository.add.assert_called_once()

    session.commit.assert_called_once()


def test_import_history_syncs_missing_episode_metadata() -> None:
    """Synchronize a Season when the historical Episode is not stored locally."""

    user_id = uuid4()
    show_id = uuid4()
    season_id = uuid4()
    episode_id = uuid4()

    watched_at = datetime(
        2026,
        8,
        1,
        20,
        0,
        tzinfo=UTC,
    )

    show_repository = Mock()
    show_repository.get_by_tmdb_id.return_value = SimpleNamespace(
        id=show_id,
        tmdb_id=95396,
    )

    season_repository = Mock()
    season_repository.get_by_number.return_value = SimpleNamespace(
        id=season_id,
        show_id=show_id,
        season_number=1,
    )

    episode = SimpleNamespace(
        id=episode_id,
        season_id=season_id,
        tmdb_id=2101,
        episode_number=1,
    )

    episode_repository = Mock()
    episode_repository.get_by_tmdb_id.side_effect = [
        None,
        episode,
    ]

    season_episode_sync_service = Mock()

    episode_watch_event_repository = Mock()
    episode_watch_event_repository.exists_at.return_value = False

    service, *_ = create_service(
        show_repository=show_repository,
        season_repository=season_repository,
        episode_repository=episode_repository,
        episode_watch_event_repository=episode_watch_event_repository,
        season_episode_sync_service=season_episode_sync_service,
    )

    export = SofaWatchExportResponse(
        exported_at=datetime(
            2026,
            8,
            20,
            15,
            30,
            tzinfo=UTC,
        ),
        user=ExportUserResponse(
            display_name="Gonçalo",
        ),
        library=ExportLibraryResponse(
            shows=[],
            movies=[],
        ),
        history=ExportWatchHistoryResponse(
            episodes=[
                ExportEpisodeWatchEventResponse(
                    show_tmdb_id=95396,
                    season_number=1,
                    episode_number=1,
                    episode_tmdb_id=2101,
                    watched_at=watched_at,
                ),
            ],
            movies=[],
        ),
    )

    result = service.import_history(
        user_id=user_id,
        export=export,
    )

    assert result.episodes.created == 1
    assert result.episodes.skipped == 0

    season_episode_sync_service.sync.assert_called_once_with(
        season_id=season_id,
    )

    assert episode_repository.get_by_tmdb_id.call_count == 2

    episode_watch_event_repository.exists_at.assert_called_once_with(
        user_id=user_id,
        episode_id=episode_id,
        watched_at=watched_at,
    )

    episode_watch_event_repository.add.assert_called_once()

def test_import_history_skips_episode_missing_after_season_sync() -> None:
    """Skip a historical Episode that cannot be resolved after metadata sync."""

    user_id = uuid4()
    show_id = uuid4()
    season_id = uuid4()

    show_repository = Mock()
    show_repository.get_by_tmdb_id.return_value = SimpleNamespace(
        id=show_id,
        tmdb_id=95396,
    )

    season_repository = Mock()
    season_repository.get_by_number.return_value = SimpleNamespace(
        id=season_id,
        show_id=show_id,
        season_number=1,
    )

    episode_repository = Mock()
    episode_repository.get_by_tmdb_id.return_value = None

    season_episode_sync_service = Mock()
    episode_watch_event_repository = Mock()

    service, session, *_ = create_service(
        show_repository=show_repository,
        season_repository=season_repository,
        episode_repository=episode_repository,
        episode_watch_event_repository=episode_watch_event_repository,
        season_episode_sync_service=season_episode_sync_service,
    )

    watched_at = datetime(
        2026,
        8,
        1,
        20,
        0,
        tzinfo=UTC,
    )

    export = SofaWatchExportResponse(
        exported_at=datetime(
            2026,
            8,
            20,
            15,
            30,
            tzinfo=UTC,
        ),
        user=ExportUserResponse(
            display_name="Gonçalo",
        ),
        library=ExportLibraryResponse(
            shows=[],
            movies=[],
        ),
        history=ExportWatchHistoryResponse(
            episodes=[
                ExportEpisodeWatchEventResponse(
                    show_tmdb_id=95396,
                    season_number=1,
                    episode_number=1,
                    episode_tmdb_id=2101,
                    watched_at=watched_at,
                ),
            ],
            movies=[],
        ),
    )

    result = service.import_history(
        user_id=user_id,
        export=export,
    )

    assert result.episodes.created == 0
    assert result.episodes.skipped == 1

    season_episode_sync_service.sync.assert_called_once_with(
        season_id=season_id,
    )

    assert episode_repository.get_by_tmdb_id.call_count == 2

    episode_watch_event_repository.exists_at.assert_not_called()
    episode_watch_event_repository.add.assert_not_called()

    session.commit.assert_not_called()



def test_import_history_creates_episode_progress() -> None:
    """Create Episode progress when restoring the first historical viewing."""

    user_id = uuid4()
    show_id = uuid4()
    season_id = uuid4()
    episode_id = uuid4()

    watched_at = datetime(
        2026,
        8,
        1,
        20,
        0,
        tzinfo=UTC,
    )

    show_repository = Mock()
    show_repository.get_by_tmdb_id.return_value = SimpleNamespace(
        id=show_id,
        tmdb_id=95396,
    )

    season_repository = Mock()
    season_repository.get_by_number.return_value = SimpleNamespace(
        id=season_id,
        show_id=show_id,
        season_number=1,
    )

    episode_repository = Mock()
    episode_repository.get_by_tmdb_id.return_value = SimpleNamespace(
        id=episode_id,
        season_id=season_id,
        tmdb_id=2101,
        episode_number=1,
    )

    episode_watch_event_repository = Mock()
    episode_watch_event_repository.exists_at.return_value = False

    episode_progress_repository = Mock()
    episode_progress_repository.get_by_user_and_episode.return_value = None

    service, session, *_ = create_service(
        show_repository=show_repository,
        season_repository=season_repository,
        episode_repository=episode_repository,
        episode_watch_event_repository=episode_watch_event_repository,
        episode_progress_repository=episode_progress_repository,
    )

    export = SofaWatchExportResponse(
        exported_at=datetime(
            2026,
            8,
            20,
            15,
            30,
            tzinfo=UTC,
        ),
        user=ExportUserResponse(
            display_name="Gonçalo",
        ),
        library=ExportLibraryResponse(
            shows=[],
            movies=[],
        ),
        history=ExportWatchHistoryResponse(
            episodes=[
                ExportEpisodeWatchEventResponse(
                    show_tmdb_id=95396,
                    season_number=1,
                    episode_number=1,
                    episode_tmdb_id=2101,
                    watched_at=watched_at,
                ),
            ],
            movies=[],
        ),
    )

    result = service.import_history(
        user_id=user_id,
        export=export,
    )

    assert result.episodes.created == 1
    assert result.episodes.skipped == 0

    episode_progress_repository.get_by_user_and_episode.assert_called_once_with(
        user_id=user_id,
        episode_id=episode_id,
    )

    episode_progress_repository.add.assert_called_once()

    progress = episode_progress_repository.add.call_args.args[0]

    assert progress.user_id == user_id
    assert progress.episode_id == episode_id
    assert progress.is_watched is True
    assert progress.watched_at == watched_at

    session.commit.assert_called_once()

def test_import_history_updates_episode_progress_with_newer_viewing() -> None:
    """Move Episode progress forward when importing a newer viewing."""

    user_id = uuid4()
    show_id = uuid4()
    season_id = uuid4()
    episode_id = uuid4()

    previous_watched_at = datetime(
        2026,
        8,
        1,
        20,
        0,
        tzinfo=UTC,
    )

    imported_watched_at = datetime(
        2026,
        8,
        14,
        21,
        30,
        tzinfo=UTC,
    )

    show_repository = Mock()
    show_repository.get_by_tmdb_id.return_value = SimpleNamespace(
        id=show_id,
        tmdb_id=95396,
    )

    season_repository = Mock()
    season_repository.get_by_number.return_value = SimpleNamespace(
        id=season_id,
        show_id=show_id,
        season_number=1,
    )

    episode_repository = Mock()
    episode_repository.get_by_tmdb_id.return_value = SimpleNamespace(
        id=episode_id,
        season_id=season_id,
        tmdb_id=2101,
        episode_number=1,
    )

    episode_watch_event_repository = Mock()
    episode_watch_event_repository.exists_at.return_value = False

    progress = EpisodeProgress(
        user_id=user_id,
        episode_id=episode_id,
        is_watched=True,
        watched_at=previous_watched_at,
    )

    episode_progress_repository = Mock()
    episode_progress_repository.get_by_user_and_episode.return_value = progress

    service, session, *_ = create_service(
        show_repository=show_repository,
        season_repository=season_repository,
        episode_repository=episode_repository,
        episode_watch_event_repository=episode_watch_event_repository,
        episode_progress_repository=episode_progress_repository,
    )

    export = SofaWatchExportResponse(
        exported_at=datetime(
            2026,
            8,
            20,
            15,
            30,
            tzinfo=UTC,
        ),
        user=ExportUserResponse(
            display_name="Gonçalo",
        ),
        library=ExportLibraryResponse(
            shows=[],
            movies=[],
        ),
        history=ExportWatchHistoryResponse(
            episodes=[
                ExportEpisodeWatchEventResponse(
                    show_tmdb_id=95396,
                    season_number=1,
                    episode_number=1,
                    episode_tmdb_id=2101,
                    watched_at=imported_watched_at,
                ),
            ],
            movies=[],
        ),
    )

    result = service.import_history(
        user_id=user_id,
        export=export,
    )

    assert result.episodes.created == 1
    assert result.episodes.skipped == 0

    assert progress.is_watched is True
    assert progress.watched_at == imported_watched_at

    episode_progress_repository.add.assert_not_called()

    session.commit.assert_called_once()

def test_import_history_keeps_newer_episode_progress_when_importing_older_viewing() -> None:
    """Keep newer Episode progress when importing an older historical viewing."""

    user_id = uuid4()
    show_id = uuid4()
    season_id = uuid4()
    episode_id = uuid4()

    imported_watched_at = datetime(
        2026,
        8,
        1,
        20,
        0,
        tzinfo=UTC,
    )

    current_watched_at = datetime(
        2026,
        8,
        14,
        21,
        30,
        tzinfo=UTC,
    )

    show_repository = Mock()
    show_repository.get_by_tmdb_id.return_value = SimpleNamespace(
        id=show_id,
        tmdb_id=95396,
    )

    season_repository = Mock()
    season_repository.get_by_number.return_value = SimpleNamespace(
        id=season_id,
        show_id=show_id,
        season_number=1,
    )

    episode_repository = Mock()
    episode_repository.get_by_tmdb_id.return_value = SimpleNamespace(
        id=episode_id,
        season_id=season_id,
        tmdb_id=2101,
        episode_number=1,
    )

    episode_watch_event_repository = Mock()
    episode_watch_event_repository.exists_at.return_value = False

    progress = EpisodeProgress(
        user_id=user_id,
        episode_id=episode_id,
        is_watched=True,
        watched_at=current_watched_at,
    )

    episode_progress_repository = Mock()
    episode_progress_repository.get_by_user_and_episode.return_value = progress

    service, session, *_ = create_service(
        show_repository=show_repository,
        season_repository=season_repository,
        episode_repository=episode_repository,
        episode_watch_event_repository=episode_watch_event_repository,
        episode_progress_repository=episode_progress_repository,
    )

    export = SofaWatchExportResponse(
        exported_at=datetime(
            2026,
            8,
            20,
            15,
            30,
            tzinfo=UTC,
        ),
        user=ExportUserResponse(
            display_name="Gonçalo",
        ),
        library=ExportLibraryResponse(
            shows=[],
            movies=[],
        ),
        history=ExportWatchHistoryResponse(
            episodes=[
                ExportEpisodeWatchEventResponse(
                    show_tmdb_id=95396,
                    season_number=1,
                    episode_number=1,
                    episode_tmdb_id=2101,
                    watched_at=imported_watched_at,
                ),
            ],
            movies=[],
        ),
    )

    result = service.import_history(
        user_id=user_id,
        export=export,
    )

    assert result.episodes.created == 1
    assert result.episodes.skipped == 0

    episode_watch_event_repository.add.assert_called_once()

    event = episode_watch_event_repository.add.call_args.args[0]

    assert event.watched_at == imported_watched_at

    assert progress.is_watched is True
    assert progress.watched_at == current_watched_at

    episode_progress_repository.add.assert_not_called()

    session.commit.assert_called_once()


def test_import_history_episode_progress_uses_latest_viewing_regardless_of_event_order() -> None:
    """Keep the latest Episode viewing as progress regardless of import order."""

    user_id = uuid4()
    show_id = uuid4()
    season_id = uuid4()
    episode_id = uuid4()

    first_watched_at = datetime(
        2026,
        8,
        1,
        20,
        0,
        tzinfo=UTC,
    )

    latest_watched_at = datetime(
        2026,
        8,
        14,
        21,
        30,
        tzinfo=UTC,
    )

    middle_watched_at = datetime(
        2026,
        8,
        7,
        19,
        15,
        tzinfo=UTC,
    )

    show_repository = Mock()
    show_repository.get_by_tmdb_id.return_value = SimpleNamespace(
        id=show_id,
        tmdb_id=95396,
    )

    season_repository = Mock()
    season_repository.get_by_number.return_value = SimpleNamespace(
        id=season_id,
        show_id=show_id,
        season_number=1,
    )

    episode_repository = Mock()
    episode_repository.get_by_tmdb_id.return_value = SimpleNamespace(
        id=episode_id,
        season_id=season_id,
        tmdb_id=2101,
        episode_number=1,
    )

    episode_watch_event_repository = Mock()
    episode_watch_event_repository.exists_at.return_value = False

    progress = EpisodeProgress(
        user_id=user_id,
        episode_id=episode_id,
        is_watched=True,
        watched_at=first_watched_at,
    )

    episode_progress_repository = Mock()
    episode_progress_repository.get_by_user_and_episode.return_value = progress

    service, session, *_ = create_service(
        show_repository=show_repository,
        season_repository=season_repository,
        episode_repository=episode_repository,
        episode_watch_event_repository=episode_watch_event_repository,
        episode_progress_repository=episode_progress_repository,
    )

    export = SofaWatchExportResponse(
        exported_at=datetime(
            2026,
            8,
            20,
            15,
            30,
            tzinfo=UTC,
        ),
        user=ExportUserResponse(
            display_name="Gonçalo",
        ),
        library=ExportLibraryResponse(
            shows=[],
            movies=[],
        ),
        history=ExportWatchHistoryResponse(
            episodes=[
                ExportEpisodeWatchEventResponse(
                    show_tmdb_id=95396,
                    season_number=1,
                    episode_number=1,
                    episode_tmdb_id=2101,
                    watched_at=first_watched_at,
                ),
                ExportEpisodeWatchEventResponse(
                    show_tmdb_id=95396,
                    season_number=1,
                    episode_number=1,
                    episode_tmdb_id=2101,
                    watched_at=latest_watched_at,
                ),
                ExportEpisodeWatchEventResponse(
                    show_tmdb_id=95396,
                    season_number=1,
                    episode_number=1,
                    episode_tmdb_id=2101,
                    watched_at=middle_watched_at,
                ),
            ],
            movies=[],
        ),
    )

    result = service.import_history(
        user_id=user_id,
        export=export,
    )

    assert result.episodes.created == 3
    assert result.episodes.skipped == 0

    assert episode_watch_event_repository.add.call_count == 3

    created_events = [
        call.args[0]
        for call in episode_watch_event_repository.add.call_args_list
    ]

    assert [
        event.watched_at
        for event in created_events
    ] == [
        first_watched_at,
        latest_watched_at,
        middle_watched_at,
    ]

    assert progress.is_watched is True
    assert progress.watched_at == latest_watched_at

    episode_progress_repository.add.assert_not_called()

    assert session.commit.call_count == 3

def test_import_user_data_imports_library_and_history() -> None:
    """Import all supported portable user data and return one final result."""

    service, *_ = create_service()

    export = _create_export()

    result = service.import_user_data(
        user_id=uuid4(),
        export=export,
    )

    assert result.library.shows.created == 0
    assert result.library.shows.updated == 0
    assert result.library.shows.unchanged == 0

    assert result.library.movies.created == 0
    assert result.library.movies.updated == 0
    assert result.library.movies.unchanged == 0

    assert result.history.episodes.created == 0
    assert result.history.episodes.skipped == 0

    assert result.history.movies.created == 0
    assert result.history.movies.skipped == 0

def test_import_user_data_restores_library_before_history() -> None:
    """Restore Library state before processing viewing History."""

    service, *_ = create_service()

    export = _create_export()
    user_id = uuid4()

    calls: list[str] = []

    original_import_library = service.import_library
    original_import_history = service.import_history

    def import_library(**kwargs):
        calls.append("library")

        return original_import_library(
            **kwargs,
        )

    def import_history(**kwargs):
        calls.append("history")

        return original_import_history(
            **kwargs,
        )

    service.import_library = import_library
    service.import_history = import_history

    service.import_user_data(
        user_id=user_id,
        export=export,
    )

    assert calls == [
        "library",
        "history",
    ]