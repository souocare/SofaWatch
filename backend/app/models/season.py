from datetime import date
from typing import TYPE_CHECKING
from uuid import UUID, uuid4

from sqlalchemy import (
    CheckConstraint,
    Date,
    Float,
    ForeignKey,
    Integer,
    String,
    Text,
    UniqueConstraint,
    Uuid,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.db.mixins import TimestampMixin

if TYPE_CHECKING:
    from app.models.show import Show


class Season(TimestampMixin, Base):
    """TV series season stored locally by SofaWatch."""

    __tablename__ = "seasons"

    __table_args__ = (
        UniqueConstraint(
            "show_id",
            "season_number",
            name="uq_seasons_show_id_season_number",
        ),
        CheckConstraint(
            "season_number >= 0",
            name="ck_seasons_season_number_non_negative",
        ),
        CheckConstraint(
            "episode_count >= 0",
            name="ck_seasons_episode_count_non_negative",
        ),
        CheckConstraint(
            "vote_average >= 0 AND vote_average <= 10",
            name="ck_seasons_vote_average_range",
        ),
    )

    id: Mapped[UUID] = mapped_column(
        Uuid(as_uuid=True),
        primary_key=True,
        default=uuid4,
    )

    show_id: Mapped[UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey(
            "shows.id",
            ondelete="CASCADE",
        ),
        nullable=False,
        index=True,
    )

    tmdb_id: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
        unique=True,
        index=True,
    )

    season_number: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
    )

    title: Mapped[str] = mapped_column(
        String(255),
        nullable=False,
    )

    overview: Mapped[str | None] = mapped_column(
        Text,
        nullable=True,
    )

    air_date: Mapped[date | None] = mapped_column(
        Date,
        nullable=True,
    )

    episode_count: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
        default=0,
    )

    vote_average: Mapped[float] = mapped_column(
        Float,
        nullable=False,
        default=0.0,
    )

    tmdb_poster_path: Mapped[str | None] = mapped_column(
        String(500),
        nullable=True,
    )

    local_poster_path: Mapped[str | None] = mapped_column(
        String(500),
        nullable=True,
    )

    show: Mapped["Show"] = relationship(
        back_populates="seasons",
    )

    def __repr__(self) -> str:
        return (
            "Season("
            f"id={self.id!r}, "
            f"show_id={self.show_id!r}, "
            f"season_number={self.season_number!r}, "
            f"title={self.title!r}"
            ")"
        )