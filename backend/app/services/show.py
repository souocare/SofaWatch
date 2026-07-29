from uuid import UUID

from app.models.show import Show
from app.repositories.show import ShowRepository


class ShowNotFoundError(Exception):
    """Raised when a locally stored TV series cannot be found."""


class ShowService:
    """Business logic for locally stored TV series."""

    def __init__(self, repository: ShowRepository) -> None:
        self._repository = repository

    def get_by_id(self, show_id: UUID) -> Show:
        """Return a locally stored show by its internal UUID."""

        show = self._repository.get_by_id(show_id)

        if show is None:
            raise ShowNotFoundError(f"Show with ID '{show_id}' was not found.")

        return show

    def get_by_tmdb_id(self, tmdb_id: int) -> Show:
        """Return a locally stored show by its TMDB identifier."""

        show = self._repository.get_by_tmdb_id(tmdb_id)

        if show is None:
            raise ShowNotFoundError(f"Show with TMDB ID '{tmdb_id}' was not found.")

        return show

    def exists_by_tmdb_id(self, tmdb_id: int) -> bool:
        """Return whether a show is already stored locally."""

        return self._repository.exists_by_tmdb_id(tmdb_id)

    def list_shows(
        self,
        *,
        offset: int = 0,
        limit: int = 50,
    ) -> list[Show]:
        """Return locally stored shows."""

        if offset < 0:
            raise ValueError("Offset must be greater than or equal to zero.")

        if limit < 1 or limit > 100:
            raise ValueError("Limit must be between 1 and 100.")

        return self._repository.list(
            offset=offset,
            limit=limit,
        )
