from datetime import datetime
from uuid import UUID, uuid4

from sqlalchemy import (
    DateTime,
    Enum,
    Integer,
    String,
    Text,
    Uuid,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base
from app.db.mixins import TimestampMixin
from app.models.enums import BackgroundJobStatus
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from app.models.background_job_run import BackgroundJobRun


class BackgroundJob(TimestampMixin, Base):
    """Persisted state for a SofaWatch background job."""

    __tablename__ = "background_jobs"

    id: Mapped[UUID] = mapped_column(
        Uuid(as_uuid=True),
        primary_key=True,
        default=uuid4,
    )

    key: Mapped[str] = mapped_column(
        String(100),
        nullable=False,
        unique=True,
        index=True,
    )

    name: Mapped[str] = mapped_column(
        String(255),
        nullable=False,
    )

    schedule: Mapped[str] = mapped_column(
        String(255),
        nullable=False,
    )

    status: Mapped[BackgroundJobStatus] = mapped_column(
        Enum(
            BackgroundJobStatus,
            name="background_job_status",
            native_enum=False,
            values_callable=lambda enum: [
                member.value
                for member in enum
            ],
        ),
        nullable=False,
        default=BackgroundJobStatus.IDLE,
        index=True,
    )

    last_started_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )

    last_finished_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )

    last_duration_ms: Mapped[int | None] = mapped_column(
        Integer,
        nullable=True,
    )

    last_error: Mapped[str | None] = mapped_column(
        Text,
        nullable=True,
    )

    next_run_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )

    runs: Mapped[list["BackgroundJobRun"]] = relationship(
        back_populates="job",
        cascade="all, delete-orphan",
    )

    def __repr__(self) -> str:
        return (
            "BackgroundJob("
            f"id={self.id!r}, "
            f"key={self.key!r}, "
            f"name={self.name!r}, "
            f"status={self.status!r}"
            ")"
        )