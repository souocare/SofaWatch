import time
from collections.abc import Callable
from datetime import UTC, datetime

from app.models.data_import_run import DataImportRun
from app.models.enums import DataImportPhase
from app.repositories.data_import_run import DataImportRunRepository

DEFAULT_PROGRESS_PERSIST_INTERVAL_SECONDS = 2.0


class DataImportProgressTracker:
    """Persist import progress without writing to SQLite for every item."""

    def __init__(
        self,
        *,
        repository: DataImportRunRepository,
        run: DataImportRun,
        persist_interval_seconds: float = (DEFAULT_PROGRESS_PERSIST_INTERVAL_SECONDS),
        monotonic: Callable[[], float] = time.monotonic,
    ) -> None:
        self._repository = repository
        self._run = run
        self._persist_interval_seconds = persist_interval_seconds
        self._monotonic = monotonic

        self._last_persisted_at: float | None = None
        self._last_phase: DataImportPhase | None = None

    def __call__(
        self,
        *,
        phase: DataImportPhase,
        current: int,
        total: int,
    ) -> None:
        """Persist significant or sufficiently aged progress updates."""

        now_monotonic = self._monotonic()

        phase_changed = phase != self._last_phase
        phase_completed = total > 0 and current >= total
        interval_elapsed = self._last_persisted_at is None or (
            now_monotonic - self._last_persisted_at >= self._persist_interval_seconds
        )

        if not (phase_changed or phase_completed or interval_elapsed):
            return

        self._repository.update_progress(
            run=self._run,
            phase=phase,
            current=current,
            total=total,
            heartbeat_at=datetime.now(UTC),
        )

        self._last_phase = phase
        self._last_persisted_at = now_monotonic
