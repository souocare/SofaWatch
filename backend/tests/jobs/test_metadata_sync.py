from types import SimpleNamespace
from unittest.mock import MagicMock, Mock, patch

import pytest

from app.jobs.metadata_sync import (
    MetadataSyncError,
    run_metadata_sync,
)
from app.services.show_import import (
    ShowSyncOutcome,
    ShowSyncResult,
)


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

    session_context = MagicMock()
    session_context.__enter__.return_value = MagicMock()
    session_context.__exit__.return_value = False

    tmdb_context = MagicMock()
    tmdb_context.__enter__.return_value = MagicMock()
    tmdb_context.__exit__.return_value = False

    show_repository = Mock()
    show_repository.list_all.return_value = [
        first_show,
        second_show,
    ]

    show_import_service = Mock()

    show_import_service.sync_show.side_effect = [
        ShowSyncResult(
            show=first_show,
            outcome=ShowSyncOutcome.REFRESHED,
        ),
        ShowSyncResult(
            show=second_show,
            outcome=ShowSyncOutcome.REFRESHED,
        ),
    ]

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
        result = run_metadata_sync()

    assert result == {
        "checked": 2,
        "refreshed": 2,
        "skipped": 0,
        "failed": 0,
    }

    assert show_import_service.sync_show.call_count == 2

    show_import_service.sync_show.assert_any_call(
        tmdb_id=1001,
        language="en-US",
    )
    show_import_service.sync_show.assert_any_call(
        tmdb_id=1002,
        language="pt-PT",
    )


def test_metadata_sync_counts_refreshed_and_skipped() -> None:
    """Distinguish refreshed shows from shows that did not require refresh."""

    first_show = SimpleNamespace(
        tmdb_id=1001,
        title="First Show",
        metadata_language="en-US",
    )
    second_show = SimpleNamespace(
        tmdb_id=1002,
        title="Second Show",
        metadata_language="en-US",
    )

    session_context = MagicMock()
    session_context.__enter__.return_value = MagicMock()
    session_context.__exit__.return_value = False

    tmdb_context = MagicMock()
    tmdb_context.__enter__.return_value = MagicMock()
    tmdb_context.__exit__.return_value = False

    show_repository = Mock()
    show_repository.list_all.return_value = [
        first_show,
        second_show,
    ]

    show_import_service = Mock()

    show_import_service.sync_show.side_effect = [
        ShowSyncResult(
            show=first_show,
            outcome=ShowSyncOutcome.REFRESHED,
        ),
        ShowSyncResult(
            show=second_show,
            outcome=ShowSyncOutcome.SKIPPED,
        ),
    ]

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
        result = run_metadata_sync()

    assert result == {
        "checked": 2,
        "refreshed": 1,
        "skipped": 1,
        "failed": 0,
    }


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

    session_context = MagicMock()
    session_context.__enter__.return_value = MagicMock()
    session_context.__exit__.return_value = False

    tmdb_context = MagicMock()
    tmdb_context.__enter__.return_value = MagicMock()
    tmdb_context.__exit__.return_value = False

    show_repository = Mock()
    show_repository.list_all.return_value = shows

    show_import_service = Mock()

    def sync_show(
        *,
        tmdb_id: int,
        language: str | None = None,
    ) -> ShowSyncResult:
        if tmdb_id == 1002:
            raise RuntimeError(
                "TMDB failed for this show.",
            )

        show = next(
            show
            for show in shows
            if show.tmdb_id == tmdb_id
        )

        return ShowSyncResult(
            show=show,
            outcome=ShowSyncOutcome.REFRESHED,
        )

    show_import_service.sync_show.side_effect = sync_show

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
            MetadataSyncError,
            match="1 failed TV series out of 3",
        ) as exc_info,
    ):
        run_metadata_sync()

    assert show_import_service.sync_show.call_count == 3

    show_import_service.sync_show.assert_any_call(
        tmdb_id=1003,
        language="pt-PT",
    )

    assert exc_info.value.result == {
        "checked": 3,
        "refreshed": 2,
        "skipped": 0,
        "failed": 1,
    }


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

    def sync_show(
        *,
        tmdb_id: int,
        language: str | None = None,
    ) -> ShowSyncResult:
        if tmdb_id in {
            1001,
            1003,
        }:
            raise RuntimeError(
                "Expected failure.",
            )

        return ShowSyncResult(
            show=shows[1],
            outcome=ShowSyncOutcome.REFRESHED,
        )

    show_import_service.sync_show.side_effect = sync_show

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
            MetadataSyncError,
            match="2 failed TV series out of 3",
        ) as exc_info,
    ):
        run_metadata_sync()

    assert show_import_service.sync_show.call_count == 3

    assert exc_info.value.result == {
        "checked": 3,
        "refreshed": 1,
        "skipped": 0,
        "failed": 2,
    }


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
        result = run_metadata_sync()

    assert result == {
        "checked": 0,
        "refreshed": 0,
        "skipped": 0,
        "failed": 0,
    }

    show_import_service.sync_show.assert_not_called()


def test_metadata_sync_preserves_each_show_metadata_language() -> None:
    """Synchronize each show using its stored metadata language."""

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

    show_import_service.sync_show.return_value = ShowSyncResult(
        show=show,
        outcome=ShowSyncOutcome.REFRESHED,
    )

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
        result = run_metadata_sync()

    assert result == {
        "checked": 1,
        "refreshed": 1,
        "skipped": 0,
        "failed": 0,
    }

    show_import_service.sync_show.assert_called_once_with(
        tmdb_id=95396,
        language="pt-PT",
    )