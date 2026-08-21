from datetime import datetime
from enum import StrEnum
from typing import TYPE_CHECKING
from uuid import UUID, uuid4

from sqlalchemy import DateTime, Enum, ForeignKey, String, Uuid
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.db.mixins import TimestampMixin

if TYPE_CHECKING:
    from app.models.user import User


class AuthSessionType(StrEnum):
    """Supported SofaWatch authentication session origins."""

    WEB = "web"
    MOBILE = "mobile"


class AuthSession(TimestampMixin, Base):
    """Persistent authenticated SofaWatch session."""

    __tablename__ = "auth_sessions"

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
        index=True,
    )

    session_type: Mapped[AuthSessionType] = mapped_column(
        Enum(
            AuthSessionType,
            native_enum=False,
            length=16,
        ),
        nullable=False,
    )

    credential_hash: Mapped[str] = mapped_column(
        String(64),
        nullable=False,
        unique=True,
        index=True,
    )

    expires_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        index=True,
    )

    last_used_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )

    revoked_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
        index=True,
    )

    user: Mapped["User"] = relationship(
        back_populates="auth_sessions",
    )

    def __repr__(self) -> str:
        return (
            "AuthSession("
            f"id={self.id!r}, "
            f"user_id={self.user_id!r}, "
            f"session_type={self.session_type!r}, "
            f"expires_at={self.expires_at!r}, "
            f"revoked_at={self.revoked_at!r}"
            ")"
        )