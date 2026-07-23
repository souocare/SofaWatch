from datetime import date, datetime
from typing import TYPE_CHECKING
from uuid import UUID, uuid4

from sqlalchemy import (
    Boolean,
    Date,
    DateTime,
    Float,
    Integer,
    String,
    Text,
    Uuid,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.associations import show_genres
from app.db.base import Base
from app.db.mixins import TimestampMixin

if TYPE_CHECKING:
    from app.models.genre import Genre


class Show(TimestampMixin, Base):
    """TV series stored locally by SofaWatch."""

    __tablename__ = "shows"

    id: Mapped[UUID] = mapped_column(
        Uuid(as_uuid=True),
        primary_key=True,
        default=uuid4,
    )

    tmdb_id: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
        unique=True,
        index=True,
    )

    tvdb_id: Mapped[int | None] = mapped_column(
        Integer,
        nullable=True,
        unique=True,
        index=True,
    )

    imdb_id: Mapped[str | None] = mapped_column(
        String(20),
        nullable=True,
        unique=True,
        index=True,
    )

    title: Mapped[str] = mapped_column(
        String(255),
        nullable=False,
        index=True,
    )

    original_title: Mapped[str] = mapped_column(
        String(255),
        nullable=False,
    )

    overview: Mapped[str | None] = mapped_column(
        Text,
        nullable=True,
    )

    tagline: Mapped[str | None] = mapped_column(
        String(500),
        nullable=True,
    )

    first_air_date: Mapped[date | None] = mapped_column(
        Date,
        nullable=True,
    )

    last_air_date: Mapped[date | None] = mapped_column(
        Date,
        nullable=True,
    )

    tmdb_poster_path: Mapped[str | None] = mapped_column(
        String(500),
        nullable=True,
    )

    tmdb_backdrop_path: Mapped[str | None] = mapped_column(
        String(500),
        nullable=True,
    )

    local_poster_path: Mapped[str | None] = mapped_column(
        String(500),
        nullable=True,
    )

    local_backdrop_path: Mapped[str | None] = mapped_column(
        String(500),
        nullable=True,
    )

    homepage_url: Mapped[str | None] = mapped_column(
        String(2048),
        nullable=True,
    )

    original_language: Mapped[str] = mapped_column(
        String(10),
        nullable=False,
    )

    status: Mapped[str] = mapped_column(
        String(100),
        nullable=False,
        default="",
    )

    show_type: Mapped[str] = mapped_column(
        String(100),
        nullable=False,
        default="",
    )

    in_production: Mapped[bool] = mapped_column(
        Boolean,
        nullable=False,
        default=False,
    )

    number_of_seasons: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
        default=0,
    )

    number_of_episodes: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
        default=0,
    )

    episode_run_time: Mapped[int | None] = mapped_column(
        Integer,
        nullable=True,
    )

    popularity: Mapped[float] = mapped_column(
        Float,
        nullable=False,
        default=0.0,
    )

    vote_average: Mapped[float] = mapped_column(
        Float,
        nullable=False,
        default=0.0,
    )

    vote_count: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
        default=0,
    )

    metadata_language: Mapped[str] = mapped_column(
        String(20),
        nullable=False,
    )
    

    metadata_updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
    )

    genres: Mapped[list["Genre"]] = relationship(
        secondary=show_genres,
        back_populates="shows",
    )

    def __repr__(self) -> str:
        return f"Show(id={self.id!r}, tmdb_id={self.tmdb_id!r}, title={self.title!r})"
