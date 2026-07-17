from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.dependencies import get_db_session
from app.models import Genre

router = APIRouter(
    prefix="/genres",
    tags=["genres"],
)

DatabaseSession = Annotated[Session, Depends(get_db_session)]


@router.get("/")
def list_genres(session: DatabaseSession) -> list[dict[str, int | str]]:
    """Return all genres ordered by name."""

    statement = select(Genre).order_by(Genre.name)
    genres = session.scalars(statement).all()

    return [
        {
            "id": genre.id,
            "name": genre.name,
            "slug": genre.slug,
        }
        for genre in genres
    ]