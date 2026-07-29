from types import SimpleNamespace
from unittest.mock import MagicMock, Mock, patch

import pytest

from app.jobs.metadata_sync import run_metadata_sync


def test_metadata_sync_refreshes_all_shows() -> None:
    """Refresh every locally stored TV series."""

    first_show = SimpleNamespace(
        tmdb_id=1001,
        title="First Show",
        metadata_language="en-US",
    )
    second_show = SimpleNamespace(
        tmdb_id=1002,
        title="Second Show",
        metadata_language="pt-PT",
    )

    session = MagicMock()

    session_context = MagicMock()
    session_context.__enter__.return_value = session
    session_context.__exit__.return_value = False

    tmdb_client = MagicMock()

    tmdb_context = MagicMock()
    tmdb_context.__enter__.return_value = tmdb_client
    tmdb_context.__exit__.return_value = False

    show_repository = Mock()
    show_repository.list_all.return_value = [
        first_show,
        second_show,
    ]

    show_import_service = Mock()

    with (
        patch(
            "app.jobs.metadata_sync.SessionLocal",
            return_value=session_context,
        ),
        patch(
            "app.jobs.metadata_sync.TMDBClient",
            return_value=tmdb_context,
        ),
        patch(
            "app.jobs.metadata_sync.ShowRepository",
            return_value=show_repository,
        ),
        patch(
            "app.jobs.metadata_sync.ShowImportService",
            return_value=show_import_service,
        ),
    ):
        run_metadata_sync()

    assert show_import_service.import_show.call_count == 2

    show_import_service.import_show.assert_any_call(
        tmdb_id=1001,
        language="en-US",
        force_refresh=False,
    )

    show_import_service.import_show.assert_any_call(
        tmdb_id=1002,
        language="pt-PT",
        force_refresh=False,
    )


def test_metadata_sync_continues_when_one_show_fails() -> None:
    """Continue synchronizing remaining shows after an individual failure."""

    shows = [
        SimpleNamespace(
            tmdb_id=1001,
            title="First Show",
            metadata_language="en-US",
        ),
        SimpleNamespace(
            tmdb_id=1002,
            title="Broken Show",
            metadata_language="en-US",
        ),
        SimpleNamespace(
            tmdb_id=1003,
            title="Third Show",
            metadata_language="pt-PT",
        ),
    ]

    session = MagicMock()

    session_context = MagicMock()
    session_context.__enter__.return_value = session
    session_context.__exit__.return_value = False

    tmdb_context = MagicMock()
    tmdb_context.__enter__.return_value = MagicMock()
    tmdb_context.__exit__.return_value = False

    show_repository = Mock()
    show_repository.list_all.return_value = shows

    show_import_service = Mock()

    def import_show(
        *,
        tmdb_id: int,
        language: str | None = None,
        force_refresh: bool = False,
    ) -> None:
        if tmdb_id == 1002:
            raise RuntimeError("TMDB failed for this show.")

    show_import_service.import_show.side_effect = import_show

    with (
        patch(
            "app.jobs.metadata_sync.SessionLocal",
            return_value=session_context,
        ),
        patch(
            "app.jobs.metadata_sync.TMDBClient",
            return_value=tmdb_context,
        ),
        patch(
            "app.jobs.metadata_sync.ShowRepository",
            return_value=show_repository,
        ),
        patch(
            "app.jobs.metadata_sync.ShowImportService",
            return_value=show_import_service,
        ),
        pytest.raises(
            RuntimeError,
            match="1 failed TV series out of 3",
        ),
    ):
        run_metadata_sync()

    assert show_import_service.import_show.call_count == 3

    show_import_service.import_show.assert_any_call(
        tmdb_id=1003,
        language="pt-PT",
        force_refresh=False,
    )


def test_metadata_sync_reports_all_failed_shows() -> None:
    """Report the total number of failed show refreshes."""

    shows = [
        SimpleNamespace(
            tmdb_id=1001,
            title="First Show",
            metadata_language="en-US",
        ),
        SimpleNamespace(
            tmdb_id=1002,
            title="Second Show",
            metadata_language="en-US",
        ),
        SimpleNamespace(
            tmdb_id=1003,
            title="Third Show",
            metadata_language="en-US",
        ),
    ]

    session_context = MagicMock()
    session_context.__enter__.return_value = MagicMock()
    session_context.__exit__.return_value = False

    tmdb_context = MagicMock()
    tmdb_context.__enter__.return_value = MagicMock()
    tmdb_context.__exit__.return_value = False

    show_repository = Mock()
    show_repository.list_all.return_value = shows

    show_import_service = Mock()

    def import_show(
        *,
        tmdb_id: int,
        language: str | None = None,
        force_refresh: bool = False,
    ) -> None:
        if tmdb_id in {
            1001,
            1003,
        }:
            raise RuntimeError("Expected failure.")

    show_import_service.import_show.side_effect = import_show

    with (
        patch(
            "app.jobs.metadata_sync.SessionLocal",
            return_value=session_context,
        ),
        patch(
            "app.jobs.metadata_sync.TMDBClient",
            return_value=tmdb_context,
        ),
        patch(
            "app.jobs.metadata_sync.ShowRepository",
            return_value=show_repository,
        ),
        patch(
            "app.jobs.metadata_sync.ShowImportService",
            return_value=show_import_service,
        ),
        pytest.raises(
            RuntimeError,
            match="2 failed TV series out of 3",
        ),
    ):
        run_metadata_sync()

    assert show_import_service.import_show.call_count == 3


def test_metadata_sync_succeeds_when_database_has_no_shows() -> None:
    """Complete successfully when no TV series exist locally."""

    session_context = MagicMock()
    session_context.__enter__.return_value = MagicMock()
    session_context.__exit__.return_value = False

    tmdb_context = MagicMock()
    tmdb_context.__enter__.return_value = MagicMock()
    tmdb_context.__exit__.return_value = False

    show_repository = Mock()
    show_repository.list_all.return_value = []

    show_import_service = Mock()

    with (
        patch(
            "app.jobs.metadata_sync.SessionLocal",
            return_value=session_context,
        ),
        patch(
            "app.jobs.metadata_sync.TMDBClient",
            return_value=tmdb_context,
        ),
        patch(
            "app.jobs.metadata_sync.ShowRepository",
            return_value=show_repository,
        ),
        patch(
            "app.jobs.metadata_sync.ShowImportService",
            return_value=show_import_service,
        ),
    ):
        run_metadata_sync()

    show_import_service.import_show.assert_not_called()


def test_metadata_sync_preserves_each_show_metadata_language() -> None:
    """Refresh each show using its stored metadata language."""

    show = SimpleNamespace(
        tmdb_id=95396,
        title="Severance",
        metadata_language="pt-PT",
    )

    session_context = MagicMock()
    session_context.__enter__.return_value = MagicMock()
    session_context.__exit__.return_value = False

    tmdb_context = MagicMock()
    tmdb_context.__enter__.return_value = MagicMock()
    tmdb_context.__exit__.return_value = False

    show_repository = Mock()
    show_repository.list_all.return_value = [
        show,
    ]

    show_import_service = Mock()

    with (
        patch(
            "app.jobs.metadata_sync.SessionLocal",
            return_value=session_context,
        ),
        patch(
            "app.jobs.metadata_sync.TMDBClient",
            return_value=tmdb_context,
        ),
        patch(
            "app.jobs.metadata_sync.ShowRepository",
            return_value=show_repository,
        ),
        patch(
            "app.jobs.metadata_sync.ShowImportService",
            return_value=show_import_service,
        ),
    ):
        run_metadata_sync()

    show_import_service.import_show.assert_called_once_with(
        tmdb_id=95396,
        language="pt-PT",
        force_refresh=False,
    )
