from uuid import UUID

from app.models.season import Season
from app.repositories.season import SeasonRepository
from app.repositories.show import ShowRepository


class SeasonService:
    """Business logic for locally stored TV seasons."""

    def __init__(
        self,
        *,
        season_repository: SeasonRepository,
        show_repository: ShowRepository,
    ) -> None:
        self._season_repository = season_repository
        self._show_repository = show_repository

    def list_for_show(
        self,
        show_id: UUID,
    ) -> list[Season] | None:
        """Return the seasons of a locally stored TV series.

        Returns None when the TV series does not exist.
        """

        show = self._show_repository.get_by_id(show_id)

        if show is None:
            return None

        return self._season_repository.list_by_show_id(show_id)

    def get_by_number(
        self,
        *,
        show_id: UUID,
        season_number: int,
    ) -> Season | None:
        """Return a season by its series and season number."""

        return self._season_repository.get_by_number(
            show_id=show_id,
            season_number=season_number,
        )