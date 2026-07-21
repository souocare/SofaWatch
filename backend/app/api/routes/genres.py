from fastapi import APIRouter, HTTPException, status

from app.api.dependencies import GenreServiceDependency
from app.schemas import GenreCreate, GenreResponse
from app.services.genre import GenreAlreadyExistsError

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

    return [GenreResponse.model_validate(genre) for genre in genres]


@router.post(
    "/",
    response_model=GenreResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_genre(
    genre_data: GenreCreate,
    service: GenreServiceDependency,
) -> GenreResponse:
    """Create a genre."""

    try:
        genre = service.create_genre(genre_data)
    except GenreAlreadyExistsError as error:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="A genre with this name or slug already exists.",
        ) from error

    return GenreResponse.model_validate(genre)
