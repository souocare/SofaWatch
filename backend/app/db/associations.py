from sqlalchemy import Column, ForeignKey, Table

from app.db.base import Base

show_genres = Table(
    "show_genres",
    Base.metadata,
    Column(
        "show_id",
        ForeignKey("shows.id", ondelete="CASCADE"),
        primary_key=True,
    ),
    Column(
        "genre_id",
        ForeignKey("genres.id", ondelete="CASCADE"),
        primary_key=True,
    ),
)
