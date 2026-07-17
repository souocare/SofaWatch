from sqlalchemy import String
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base
from app.db.mixins import TimestampMixin


class Genre(TimestampMixin, Base):
    __tablename__ = "genres"

    id: Mapped[int] = mapped_column(
        primary_key=True,
        autoincrement=True,
    )

    name: Mapped[str] = mapped_column(
        String(100),
        nullable=False,
        unique=True,
        index=True,
    )

    slug: Mapped[str] = mapped_column(
        String(100),
        nullable=False,
        unique=True,
        index=True,
    )

    def __repr__(self) -> str:
        return f"Genre(id={self.id!r}, name={self.name!r}, slug={self.slug!r})"