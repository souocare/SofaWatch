from typing import TYPE_CHECKING
from uuid import UUID, uuid4

from sqlalchemy import Boolean, Index, String, Uuid
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.db.mixins import TimestampMixin

if TYPE_CHECKING:
    from app.models.auth_session import AuthSession
    from app.models.episode_progress import EpisodeProgress
    from app.models.library import LibraryEntry


class User(TimestampMixin, Base):
    """SofaWatch user."""

    __tablename__ = "users"

    __table_args__ = (
        Index(
            "ix_users_username_unique",
            "username",
            unique=True,
        ),
        Index(
            "ix_users_email_unique",
            "email",
            unique=True,
        ),
    )

    id: Mapped[UUID] = mapped_column(
        Uuid(as_uuid=True),
        primary_key=True,
        default=uuid4,
    )

    username: Mapped[str | None] = mapped_column(
        String(32),
        nullable=True,
    )

    email: Mapped[str | None] = mapped_column(
        String(320),
        nullable=True,
    )

    display_name: Mapped[str] = mapped_column(
        String(100),
        nullable=False,
    )

    password_hash: Mapped[str | None] = mapped_column(
        String(255),
        nullable=True,
    )

    is_active: Mapped[bool] = mapped_column(
        Boolean,
        nullable=False,
        default=True,
    )

    is_local: Mapped[bool] = mapped_column(
        Boolean,
        nullable=False,
        default=False,
    )

    is_admin: Mapped[bool] = mapped_column(
        Boolean,
        nullable=False,
        default=False,
    )

    library_entries: Mapped[list["LibraryEntry"]] = relationship(
        back_populates="user",
        cascade="all, delete-orphan",
    )

    episode_progress: Mapped[list["EpisodeProgress"]] = relationship(
        back_populates="user",
        cascade="all, delete-orphan",
    )

    auth_sessions: Mapped[list["AuthSession"]] = relationship(
        back_populates="user",
        cascade="all, delete-orphan",
    )

    def __repr__(self) -> str:
        return (
            "User("
            f"id={self.id!r}, "
            f"username={self.username!r}, "
            f"email={self.email!r}, "
            f"display_name={self.display_name!r}, "
            f"is_active={self.is_active!r}, "
            f"is_local={self.is_local!r}, "
            f"is_admin={self.is_admin!r}"
            ")"
        )