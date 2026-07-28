from datetime import datetime
from typing import TYPE_CHECKING
from uuid import UUID, uuid4

from sqlalchemy import (
    Boolean,
    DateTime,
    ForeignKey,
    UniqueConstraint,
    Uuid,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.db.mixins import TimestampMixin

if TYPE_CHECKING:
    from app.models.episode import Episode
    from app.models.user import User


class EpisodeProgress(TimestampMixin, Base):
    """Viewing progress for an episode belonging to a user."""

    __tablename__ = "episode_progress"

    __table_args__ = (
        UniqueConstraint(
            "user_id",
            "episode_id",
            name="uq_episode_progress_user_id_episode_id",
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
        index=True,
    )

    episode_id: Mapped[UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey(
            "episodes.id",
            ondelete="CASCADE",
        ),
        nullable=False,
        index=True,
    )

    is_watched: Mapped[bool] = mapped_column(
        Boolean,
        nullable=False,
        default=False,
        index=True,
    )

    watched_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )

    user: Mapped["User"] = relationship(
        back_populates="episode_progress",
    )

    episode: Mapped["Episode"] = relationship(
        back_populates="progress_entries",
    )

    def __repr__(self) -> str:
        return (
            "EpisodeProgress("
            f"id={self.id!r}, "
            f"user_id={self.user_id!r}, "
            f"episode_id={self.episode_id!r}, "
            f"is_watched={self.is_watched!r}"
            ")"
        )