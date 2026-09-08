from datetime import datetime
from uuid import UUID

from sqlalchemy import func, select, update
from sqlalchemy.orm import Session

from app.models.data_import_run import DataImportRun
from app.models.enums import (
    DataImportPhase,
    DataImportRunStatus,
)


class DataImportRunRepository:
    """Persistence operations for user data import executions."""

    _ACTIVE_STATUSES = (
        DataImportRunStatus.QUEUED,
        DataImportRunStatus.RUNNING,
    )

    def __init__(
        self,
        session: Session,
    ) -> None:
        self._session = session

    def add(
        self,
        run: DataImportRun,
    ) -> DataImportRun:
        """Add an import execution to the current unit of work."""

        self._session.add(run)

        return run

    def get_for_user(
        self,
        *,
        run_id: UUID,
        user_id: UUID,
    ) -> DataImportRun | None:
        """Return an import execution only when owned by the user."""

        return self._session.scalar(
            select(DataImportRun).where(
                DataImportRun.id == run_id,
                DataImportRun.user_id == user_id,
            )
        )

    def get_active_for_user(
        self,
        *,
        user_id: UUID,
    ) -> DataImportRun | None:
        """Return the user's current queued or running import."""

        return self._session.scalar(
            select(DataImportRun)
            .where(
                DataImportRun.user_id == user_id,
                DataImportRun.status.in_(self._ACTIVE_STATUSES),
            )
            .order_by(
                DataImportRun.created_at.desc(),
            )
            .limit(1)
        )

    def get_by_id(
        self,
        *,
        run_id: UUID,
    ) -> DataImportRun | None:
        """Return an import execution for internal worker operations."""

        return self._session.get(
            DataImportRun,
            run_id,
        )

    def claim_next_queued(
        self,
        *,
        now: datetime,
    ) -> DataImportRun | None:
        """Atomically claim the oldest queued import execution."""

        run_id = self._session.scalar(
            select(DataImportRun.id)
            .where(
                DataImportRun.status == DataImportRunStatus.QUEUED,
            )
            .order_by(
                DataImportRun.created_at.asc(),
                DataImportRun.id.asc(),
            )
            .limit(1)
        )

        if run_id is None:
            return None

        result = self._session.execute(
            update(DataImportRun)
            .where(
                DataImportRun.id == run_id,
                DataImportRun.status == DataImportRunStatus.QUEUED,
            )
            .values(
                status=DataImportRunStatus.RUNNING,
                started_at=now,
                heartbeat_at=now,
            )
        )

        self._session.commit()

        if result.rowcount != 1:
            return None

        return self.get_by_id(
            run_id=run_id,
        )

    def mark_completed(
        self,
        *,
        run: DataImportRun,
        result: dict[str, object],
        finished_at: datetime,
    ) -> None:
        """Complete an import and remove its temporary source payload."""

        run.status = DataImportRunStatus.COMPLETED
        run.phase = DataImportPhase.FINALIZING
        run.result = result
        run.payload = None
        run.error_code = None
        run.error_message = None
        run.heartbeat_at = finished_at
        run.finished_at = finished_at

        self._session.commit()

    def mark_failed(
        self,
        *,
        run: DataImportRun,
        error_code: str,
        error_message: str,
        finished_at: datetime,
    ) -> None:
        """Fail an import using only safe persisted error information."""

        run.status = DataImportRunStatus.FAILED
        run.payload = None
        run.error_code = error_code
        run.error_message = error_message
        run.heartbeat_at = finished_at
        run.finished_at = finished_at

        self._session.commit()

    def update_progress(
        self,
        *,
        run: DataImportRun,
        phase: DataImportPhase,
        current: int,
        total: int,
        heartbeat_at: datetime,
    ) -> None:
        """Persist observable progress for a running import."""

        run.phase = phase
        run.progress_current = current
        run.progress_total = total
        run.heartbeat_at = heartbeat_at

        self._session.commit()

    def fail_stale_running(
        self,
        *,
        stale_before: datetime,
        finished_at: datetime,
    ) -> int:
        """Mark abandoned running imports as interrupted.

        Interrupted imports are terminal and are never automatically retried.
        """

        result = self._session.execute(
            update(DataImportRun)
            .where(
                DataImportRun.status == DataImportRunStatus.RUNNING,
                func.coalesce(
                    DataImportRun.heartbeat_at,
                    DataImportRun.started_at,
                    DataImportRun.created_at,
                )
                < stale_before,
            )
            .values(
                status=DataImportRunStatus.FAILED,
                payload=None,
                error_code="data_import_interrupted",
                error_message=(
                    "The data import was interrupted before it could complete."
                ),
                heartbeat_at=finished_at,
                finished_at=finished_at,
            )
        )

        self._session.commit()

        return result.rowcount

    def commit(self) -> None:
        """Commit the current unit of work."""

        self._session.commit()

    def refresh(
        self,
        run: DataImportRun,
    ) -> None:
        """Refresh a persisted import execution."""

        self._session.refresh(run)


    def rollback(self) -> None:
        """Roll back the current unit of work."""

        self._session.rollback()