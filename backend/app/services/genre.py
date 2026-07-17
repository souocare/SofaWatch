from app.models import Genre
from app.repositories import GenreRepository


class GenreService:
    """Application operations involving genres."""

    def __init__(self, repository: GenreRepository) -> None:
        self._repository = repository

    def list_genres(self) -> list[Genre]:
        """Return all available genres."""

        return self._repository.list_all()