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
    from app.models.episode_progress import EpisodeProgress
    from app.models.season import Season


class Episode(TimestampMixin, Base):
    """TV series episode stored locally by SofaWatch."""

    __tablename__ = "episodes"

    __table_args__ = (
        UniqueConstraint(
            "season_id",
            "episode_number",
            name="uq_episodes_season_id_episode_number",
        ),
        CheckConstraint(
            "episode_number >= 0",
            name="ck_episodes_episode_number_non_negative",
        ),
        CheckConstraint(
            "runtime IS NULL OR runtime >= 0",
            name="ck_episodes_runtime_non_negative",
        ),
        CheckConstraint(
            "vote_average >= 0 AND vote_average <= 10",
            name="ck_episodes_vote_average_range",
        ),
        CheckConstraint(
            "vote_count >= 0",
            name="ck_episodes_vote_count_non_negative",
        ),
    )

    id: Mapped[UUID] = mapped_column(
        Uuid(as_uuid=True),
        primary_key=True,
        default=uuid4,
    )

    season_id: Mapped[UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey(
            "seasons.id",
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

    episode_number: Mapped[int] = mapped_column(
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

    runtime: Mapped[int | None] = mapped_column(
        Integer,
        nullable=True,
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

    tmdb_still_path: Mapped[str | None] = mapped_column(
        String(500),
        nullable=True,
    )

    local_still_path: Mapped[str | None] = mapped_column(
        String(500),
        nullable=True,
    )

    season: Mapped["Season"] = relationship(
        back_populates="episodes",
    )

    progress_entries: Mapped[list["EpisodeProgress"]] = relationship(
        back_populates="episode",
        cascade="all, delete-orphan",
    )

    @property
    def still_url(self) -> str | None:
        """Return the SofaWatch episode still endpoint when artwork is available."""

        if not self.local_still_path and not self.tmdb_still_path:
            return None

        return f"/api/v1/images/episodes/{self.id}/still"

    def __repr__(self) -> str:
        return (
            "Episode("
            f"id={self.id!r}, "
            f"season_id={self.season_id!r}, "
            f"episode_number={self.episode_number!r}, "
            f"title={self.title!r}"
            ")"
        )
