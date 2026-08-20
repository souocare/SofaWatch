from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.background_job import BackgroundJob
from app.models.background_job_run import BackgroundJobRun


class BackgroundJobRepository:
    """Persistence operations for background jobs."""

    def __init__(
        self,
        session: Session,
    ) -> None:
        self._session = session

    def get_by_key(
        self,
        key: str,
    ) -> BackgroundJob | None:
        """Return a background job by its unique key."""

        return self._session.scalar(
            select(BackgroundJob).where(
                BackgroundJob.key == key,
            )
        )

    def list_all(
        self,
    ) -> list[BackgroundJob]:
        """Return all registered background jobs."""

        return list(
            self._session.scalars(
                select(BackgroundJob).order_by(
                    BackgroundJob.name.asc(),
                )
            ).all()
        )

    def add(
        self,
        job: BackgroundJob,
    ) -> BackgroundJob:
        """Add a background job to the current unit of work."""

        self._session.add(job)

        return job

    def add_run(
        self,
        run: BackgroundJobRun,
    ) -> BackgroundJobRun:
        """Add a background job execution to the current unit of work."""

        self._session.add(run)

        return run

    def get_latest_run(
        self,
        *,
        job_id: UUID,
    ) -> BackgroundJobRun | None:
        """Return the most recent execution for a background job."""

        return self._session.scalar(
            select(BackgroundJobRun)
            .where(
                BackgroundJobRun.job_id == job_id,
            )
            .order_by(
                BackgroundJobRun.started_at.desc(),
            )
            .limit(1)
        )

    def list_runs(
        self,
        *,
        job_id: UUID,
        limit: int = 20,
    ) -> list[BackgroundJobRun]:
        """Return recent executions for a background job."""

        return list(
            self._session.scalars(
                select(BackgroundJobRun)
                .where(
                    BackgroundJobRun.job_id == job_id,
                )
                .order_by(
                    BackgroundJobRun.started_at.desc(),
                )
                .limit(limit)
            ).all()
        )

    def commit(
        self,
    ) -> None:
        """Commit the current unit of work."""

        self._session.commit()

    def refresh(
        self,
        job: BackgroundJob,
    ) -> None:
        """Refresh a persisted background job."""

        self._session.refresh(job)
