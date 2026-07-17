from fastapi import APIRouter

from app.api.dependencies import GenreServiceDependency
from app.schemas import GenreResponse

router = APIRouter(
    prefix="/genres",
    tags=["genres"],
)


@router.get(
    "/",
    response_model=list[GenreResponse],
)
def list_genres(
    service: GenreServiceDependency,
) -> list[GenreResponse]:
    """Return all genres ordered by name."""

    genres = service.list_genres()

    return [
        GenreResponse.model_validate(genre)
        for genre in genres
    ]