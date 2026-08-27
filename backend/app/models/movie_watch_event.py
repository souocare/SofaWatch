from datetime import datetime
from typing import TYPE_CHECKING
from uuid import UUID, uuid4

from sqlalchemy import DateTime, ForeignKey, Index, Uuid
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.db.mixins import TimestampMixin

if TYPE_CHECKING:
    from app.models.movie import Movie
    from app.models.user import User


class MovieWatchEvent(TimestampMixin, Base):
    """Historical record of a user watching a Movie."""

    __tablename__ = "movie_watch_events"

    __table_args__ = (
        Index(
            "ix_movie_watch_events_user_id_watched_at",
            "user_id",
            "watched_at",
        ),
        Index(
            "ix_movie_watch_events_user_id_movie_id",
            "user_id",
            "movie_id",
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

    movie_id: Mapped[UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey(
            "movies.id",
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

    movie: Mapped["Movie"] = relationship()

    def __repr__(self) -> str:
        return (
            "MovieWatchEvent("
            f"id={self.id!r}, "
            f"user_id={self.user_id!r}, "
            f"movie_id={self.movie_id!r}, "
            f"watched_at={self.watched_at!r}"
            ")"
        )
