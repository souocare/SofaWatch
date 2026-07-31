from fastapi import APIRouter, status
from app.core.exceptions import APIError

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
        raise APIError(
            status_code=status.HTTP_409_CONFLICT,
            code="genre_already_exists",
            message="A genre with this name or slug already exists.",
        ) from error

    return GenreResponse.model_validate(genre)
