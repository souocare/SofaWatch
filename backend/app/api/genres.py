from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.dependencies import get_db_session
from app.models import Genre
from app.schemas import GenreResponse

router = APIRouter(
    prefix="/genres",
    tags=["genres"],
)

DatabaseSession = Annotated[Session, Depends(get_db_session)]


@router.get(
    "/",
    response_model=list[GenreResponse],
)
def list_genres(
    session: DatabaseSession,
) -> list[GenreResponse]:
    """Return all genres ordered by name."""

    statement = select(Genre).order_by(Genre.name)

    genres = session.scalars(statement).all()

    return [
        GenreResponse.model_validate(genre)
        for genre in genres
    ]