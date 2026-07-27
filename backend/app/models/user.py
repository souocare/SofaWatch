from typing import TYPE_CHECKING
from uuid import UUID, uuid4

from sqlalchemy import Boolean, String, Uuid
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.db.mixins import TimestampMixin

if TYPE_CHECKING:
    from app.models.library import LibraryEntry


class User(TimestampMixin, Base):
    """SofaWatch user."""

    __tablename__ = "users"

    id: Mapped[UUID] = mapped_column(
        Uuid(as_uuid=True),
        primary_key=True,
        default=uuid4,
    )

    display_name: Mapped[str] = mapped_column(
        String(100),
        nullable=False,
    )

    is_local: Mapped[bool] = mapped_column(
        Boolean,
        nullable=False,
        default=False,
    )

    library_entries: Mapped[list["LibraryEntry"]] = relationship(
        back_populates="user",
        cascade="all, delete-orphan",
    )

    def __repr__(self) -> str:
        return (
            "User("
            f"id={self.id!r}, "
            f"display_name={self.display_name!r}, "
            f"is_local={self.is_local!r}"
            ")"
        )