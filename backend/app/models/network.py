from typing import TYPE_CHECKING
from uuid import UUID, uuid4

from sqlalchemy import String, Uuid
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.db.mixins import TimestampMixin

if TYPE_CHECKING:
    from app.models.show import Show


class Network(TimestampMixin, Base):
    """Television network stored locally by SofaWatch."""

    __tablename__ = "networks"

    id: Mapped[UUID] = mapped_column(
        Uuid(as_uuid=True),
        primary_key=True,
        default=uuid4,
    )

    tmdb_id: Mapped[int] = mapped_column(
        nullable=False,
        unique=True,
        index=True,
    )

    name: Mapped[str] = mapped_column(
        String(255),
        nullable=False,
    )

    tmdb_logo_path: Mapped[str | None] = mapped_column(
        String(500),
        nullable=True,
    )

    origin_country: Mapped[str | None] = mapped_column(
        String(10),
        nullable=True,
    )

    shows: Mapped[list["Show"]] = relationship(
        secondary="show_networks",
        back_populates="networks",
    )

    def __repr__(self) -> str:
        return f"Network(id={self.id!r}, tmdb_id={self.tmdb_id!r}, name={self.name!r})"
