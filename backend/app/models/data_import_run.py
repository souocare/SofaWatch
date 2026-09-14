from datetime import datetime
from typing import TYPE_CHECKING
from uuid import UUID, uuid4

from sqlalchemy import (
    JSON,
    DateTime,
    Enum,
    ForeignKey,
    Index,
    Integer,
    String,
    Uuid,
    text,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.db.mixins import TimestampMixin
from app.models.enums import DataImportPhase, DataImportRunStatus

if TYPE_CHECKING:
    from app.models.user import User


class DataImportRun(TimestampMixin, Base):
    """Persistent execution state for a user data import."""

    __tablename__ = "data_import_runs"

    __table_args__ = (
        Index(
            "ix_data_import_runs_user_status",
            "user_id",
            "status",
        ),
        Index(
            "uq_data_import_runs_user_active",
            "user_id",
            unique=True,
            sqlite_where=text(
                "status IN ('queued', 'running')",
            ),
        ),
    )

    id: Mapped[UUID] = mapped_column(
        Uuid(as_uuid=True),
        primary_key=True,
        default=uuid4,
    )

    user_id: Mapped[UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey(
            "users.id",
            ondelete="CASCADE",
        ),
        nullable=False,
    )

    status: Mapped[DataImportRunStatus] = mapped_column(
        Enum(
            DataImportRunStatus,
            name="data_import_run_status",
            native_enum=False,
            values_callable=lambda enum: [member.value for member in enum],
        ),
        nullable=False,
        default=DataImportRunStatus.QUEUED,
    )

    phase: Mapped[DataImportPhase] = mapped_column(
        Enum(
            DataImportPhase,
            name="data_import_phase",
            native_enum=False,
            values_callable=lambda enum: [member.value for member in enum],
        ),
        nullable=False,
        default=DataImportPhase.QUEUED,
    )

    progress_current: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
        default=0,
    )

    progress_total: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
        default=0,
    )

    payload: Mapped[dict[str, object] | None] = mapped_column(
        JSON,
        nullable=True,
    )

    result: Mapped[dict[str, object] | None] = mapped_column(
        JSON,
        nullable=True,
    )

    error_code: Mapped[str | None] = mapped_column(
        String(100),
        nullable=True,
    )

    error_message: Mapped[str | None] = mapped_column(
        String(500),
        nullable=True,
    )

    started_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )

    heartbeat_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )

    finished_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )

    user: Mapped["User"] = relationship()

    def __repr__(self) -> str:
        return (
            "DataImportRun("
            f"id={self.id!r}, "
            f"user_id={self.user_id!r}, "
            f"status={self.status!r}, "
            f"phase={self.phase!r}"
            ")"
        )
