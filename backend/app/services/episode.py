from uuid import UUID

from app.models.episode import Episode
from app.repositories.episode import EpisodeRepository
from app.repositories.season import SeasonRepository


class EpisodeService:
    """Business logic for locally stored TV episodes."""

    def __init__(
        self,
        *,
        episode_repository: EpisodeRepository,
        season_repository: SeasonRepository,
    ) -> None:
        self._episode_repository = episode_repository
        self._season_repository = season_repository

    def get_by_id(
        self,
        episode_id: UUID,
    ) -> Episode | None:
        """Return a locally stored episode by its identifier."""

        return self._episode_repository.get_by_id(
            episode_id,
        )

    def list_for_season(
        self,
        season_id: UUID,
    ) -> list[Episode] | None:
        """Return the episodes of a locally stored TV season.

        Returns None when the TV season does not exist.
        """

        season = self._season_repository.get_by_id(
            season_id,
        )

        if season is None:
            return None

        return self._episode_repository.list_by_season_id(
            season_id,
        )

    def get_by_number(
        self,
        *,
        season_id: UUID,
        episode_number: int,
    ) -> Episode | None:
        """Return an episode by its season and episode number."""

        return self._episode_repository.get_by_number(
            season_id=season_id,
            episode_number=episode_number,
        )
