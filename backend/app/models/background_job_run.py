from datetime import datetime
from typing import TYPE_CHECKING
from uuid import UUID, uuid4

from sqlalchemy import (
    DateTime,
    Enum,
    ForeignKey,
    Integer,
    Text,
    Uuid,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.db.mixins import TimestampMixin
from app.models.enums import BackgroundJobStatus

if TYPE_CHECKING:
    from app.models.background_job import BackgroundJob


class BackgroundJobRun(TimestampMixin, Base):
    """Execution history for a background job."""

    __tablename__ = "background_job_runs"

    id: Mapped[UUID] = mapped_column(
        Uuid(as_uuid=True),
        primary_key=True,
        default=uuid4,
    )

    job_id: Mapped[UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey(
            "background_jobs.id",
            ondelete="CASCADE",
        ),
        nullable=False,
        index=True,
    )

    status: Mapped[BackgroundJobStatus] = mapped_column(
        Enum(
            BackgroundJobStatus,
            name="background_job_run_status",
            native_enum=False,
            values_callable=lambda enum: [
                member.value
                for member in enum
            ],
        ),
        nullable=False,
    )

    started_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
    )

    finished_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )

    duration_ms: Mapped[int | None] = mapped_column(
        Integer,
        nullable=True,
    )

    error: Mapped[str | None] = mapped_column(
        Text,
        nullable=True,
    )

    job: Mapped["BackgroundJob"] = relationship(
        back_populates="runs",
    )