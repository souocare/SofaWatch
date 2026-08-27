from typing import TYPE_CHECKING

from sqlalchemy import String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.associations import movie_genres, show_genres
from app.db.base import Base
from app.db.mixins import TimestampMixin

if TYPE_CHECKING:
    from app.models.genre_provider_mapping import (
        GenreProviderMapping,
    )
    from app.models.movie import Movie
    from app.models.show import Show


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

    shows: Mapped[list["Show"]] = relationship(
        secondary=show_genres,
        back_populates="genres",
    )

    movies: Mapped[list["Movie"]] = relationship(
        secondary=movie_genres,
        back_populates="genres",
    )

    provider_mappings: Mapped[list["GenreProviderMapping"]] = relationship(
        back_populates="genre",
        cascade="all, delete-orphan",
    )
