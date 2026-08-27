from typing import TYPE_CHECKING

from sqlalchemy import (
    ForeignKey,
    Integer,
    String,
    UniqueConstraint,
)
from sqlalchemy.orm import (
    Mapped,
    mapped_column,
    relationship,
)

from app.db.base import Base
from app.db.mixins import TimestampMixin

if TYPE_CHECKING:
    from app.models.genre import Genre


class GenreProviderMapping(
    TimestampMixin,
    Base,
):
    """Map a local Genre to an external metadata provider."""

    __tablename__ = "genre_provider_mappings"

    __table_args__ = (
        UniqueConstraint(
            "provider",
            "media_type",
            "provider_genre_id",
            name="uq_genre_provider_mapping",
        ),
    )

    id: Mapped[int] = mapped_column(
        primary_key=True,
        autoincrement=True,
    )

    genre_id: Mapped[int] = mapped_column(
        ForeignKey(
            "genres.id",
            ondelete="CASCADE",
        ),
        nullable=False,
        index=True,
    )

    provider: Mapped[str] = mapped_column(
        String(50),
        nullable=False,
        index=True,
    )

    media_type: Mapped[str] = mapped_column(
        String(20),
        nullable=False,
        index=True,
    )

    provider_genre_id: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
    )

    genre: Mapped["Genre"] = relationship(
        back_populates="provider_mappings",
    )
