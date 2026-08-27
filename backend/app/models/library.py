from datetime import datetime
from typing import TYPE_CHECKING
from uuid import UUID, uuid4

from sqlalchemy import (
    CheckConstraint,
    DateTime,
    Enum,
    Float,
    ForeignKey,
    UniqueConstraint,
    Uuid,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.db.mixins import TimestampMixin
from app.models.enums import LibraryStatus

if TYPE_CHECKING:
    from app.models.movie import Movie
    from app.models.show import Show
    from app.models.user import User


class LibraryEntry(TimestampMixin, Base):
    """Media item stored in a user's personal library."""

    __tablename__ = "library_entries"

    __table_args__ = (
        UniqueConstraint(
            "user_id",
            "show_id",
            name="uq_library_entries_user_id_show_id",
        ),
        UniqueConstraint(
            "user_id",
            "movie_id",
            name="uq_library_entries_user_id_movie_id",
        ),
        CheckConstraint(
            """
            (
                show_id IS NOT NULL
                AND movie_id IS NULL
            )
            OR
            (
                show_id IS NULL
                AND movie_id IS NOT NULL
            )
            """,
            name="ck_library_entries_single_media_target",
        ),
        CheckConstraint(
            "rating IS NULL OR (rating >= 0 AND rating <= 10)",
            name="ck_library_entries_rating_range",
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

    show_id: Mapped[UUID | None] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey(
            "shows.id",
            ondelete="CASCADE",
        ),
        nullable=True,
        index=True,
    )

    movie_id: Mapped[UUID | None] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey(
            "movies.id",
            ondelete="CASCADE",
        ),
        nullable=True,
        index=True,
    )

    status: Mapped[LibraryStatus] = mapped_column(
        Enum(
            LibraryStatus,
            name="library_status",
            native_enum=False,
            values_callable=lambda enum: [member.value for member in enum],
        ),
        nullable=False,
        default=LibraryStatus.PLANNING,
        index=True,
    )

    rating: Mapped[float | None] = mapped_column(
        Float,
        nullable=True,
    )

    started_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )

    completed_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )

    user: Mapped["User"] = relationship(
        back_populates="library_entries",
    )

    show: Mapped["Show | None"] = relationship(
        back_populates="library_entries",
    )

    movie: Mapped["Movie | None"] = relationship(
        back_populates="library_entries",
    )

    def __repr__(self) -> str:
        return (
            "LibraryEntry("
            f"id={self.id!r}, "
            f"user_id={self.user_id!r}, "
            f"show_id={self.show_id!r}, "
            f"movie_id={self.movie_id!r}, "
            f"status={self.status!r}"
            ")"
        )
