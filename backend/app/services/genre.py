from app.models import Genre
from app.repositories import GenreRepository
from app.schemas import GenreCreate
from app.services.exceptions import GenreAlreadyExistsError


class GenreService:
    """Application operations involving genres."""

    def __init__(self, repository: GenreRepository) -> None:
        self._repository = repository

    def list_genres(self) -> list[Genre]:
        """Return all available genres."""

        return self._repository.list_all()

    def create_genre(
        self,
        genre_data: GenreCreate,
    ) -> Genre:
        """Create a genre when its name and slug are unique."""

        existing_genre = self._repository.get_by_name_or_slug(
            name=genre_data.name,
            slug=genre_data.slug,
        )

        if existing_genre is not None:
            raise GenreAlreadyExistsError

        genre = Genre(
            name=genre_data.name,
            slug=genre_data.slug,
        )

        return self._repository.add(genre)
