from datetime import datetime
from typing import TYPE_CHECKING
from uuid import UUID, uuid4

from sqlalchemy import DateTime, ForeignKey, Index, Uuid
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.db.mixins import TimestampMixin

if TYPE_CHECKING:
    from app.models.episode import Episode
    from app.models.user import User


class EpisodeWatchEvent(TimestampMixin, Base):
    """Historical record of a user watching an episode."""

    __tablename__ = "episode_watch_events"

    __table_args__ = (
        Index(
            "ix_episode_watch_events_user_id_watched_at",
            "user_id",
            "watched_at",
        ),
        Index(
            "ix_episode_watch_events_user_id_episode_id",
            "user_id",
            "episode_id",
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

    episode_id: Mapped[UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey(
            "episodes.id",
            ondelete="CASCADE",
        ),
        nullable=False,
        index=True,
    )

    watched_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
    )

    user: Mapped["User"] = relationship()

    episode: Mapped["Episode"] = relationship()

    def __repr__(self) -> str:
        return (
            "EpisodeWatchEvent("
            f"id={self.id!r}, "
            f"user_id={self.user_id!r}, "
            f"episode_id={self.episode_id!r}, "
            f"watched_at={self.watched_at!r}"
            ")"
        )