from unittest.mock import Mock

from app.jobs.data_import_progress_tracker import (
    DataImportProgressTracker,
)
from app.models.data_import_run import DataImportRun
from app.models.enums import DataImportPhase


def test_tracker_persists_first_progress_update() -> None:
    repository = Mock()
    run = DataImportRun()

    tracker = DataImportProgressTracker(
        repository=repository,
        run=run,
        monotonic=Mock(
            return_value=10.0,
        ),
    )

    tracker(
        phase=DataImportPhase.LIBRARY_SHOWS,
        current=0,
        total=100,
    )

    repository.update_progress.assert_called_once()

    call = repository.update_progress.call_args

    assert call.kwargs["run"] is run
    assert call.kwargs["phase"] == DataImportPhase.LIBRARY_SHOWS
    assert call.kwargs["current"] == 0
    assert call.kwargs["total"] == 100


def test_tracker_throttles_updates_within_same_phase() -> None:
    repository = Mock()
    run = DataImportRun()

    monotonic = Mock(
        side_effect=[
            10.0,
            10.5,
            11.0,
        ]
    )

    tracker = DataImportProgressTracker(
        repository=repository,
        run=run,
        persist_interval_seconds=2.0,
        monotonic=monotonic,
    )

    tracker(
        phase=DataImportPhase.HISTORY_EPISODES,
        current=0,
        total=100,
    )

    tracker(
        phase=DataImportPhase.HISTORY_EPISODES,
        current=1,
        total=100,
    )

    tracker(
        phase=DataImportPhase.HISTORY_EPISODES,
        current=2,
        total=100,
    )

    assert repository.update_progress.call_count == 1


def test_tracker_persists_after_interval() -> None:
    repository = Mock()
    run = DataImportRun()

    monotonic = Mock(
        side_effect=[
            10.0,
            12.1,
        ]
    )

    tracker = DataImportProgressTracker(
        repository=repository,
        run=run,
        persist_interval_seconds=2.0,
        monotonic=monotonic,
    )

    tracker(
        phase=DataImportPhase.HISTORY_EPISODES,
        current=0,
        total=100,
    )

    tracker(
        phase=DataImportPhase.HISTORY_EPISODES,
        current=10,
        total=100,
    )

    assert repository.update_progress.call_count == 2


def test_tracker_always_persists_phase_change() -> None:
    repository = Mock()
    run = DataImportRun()

    monotonic = Mock(
        side_effect=[
            10.0,
            10.1,
        ]
    )

    tracker = DataImportProgressTracker(
        repository=repository,
        run=run,
        persist_interval_seconds=2.0,
        monotonic=monotonic,
    )

    tracker(
        phase=DataImportPhase.LIBRARY_SHOWS,
        current=0,
        total=100,
    )

    tracker(
        phase=DataImportPhase.LIBRARY_MOVIES,
        current=0,
        total=50,
    )

    assert repository.update_progress.call_count == 2


def test_tracker_always_persists_phase_completion() -> None:
    repository = Mock()
    run = DataImportRun()

    monotonic = Mock(
        side_effect=[
            10.0,
            10.1,
        ]
    )

    tracker = DataImportProgressTracker(
        repository=repository,
        run=run,
        persist_interval_seconds=2.0,
        monotonic=monotonic,
    )

    tracker(
        phase=DataImportPhase.HISTORY_EPISODES,
        current=0,
        total=100,
    )

    tracker(
        phase=DataImportPhase.HISTORY_EPISODES,
        current=100,
        total=100,
    )

    assert repository.update_progress.call_count == 2