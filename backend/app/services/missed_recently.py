from datetime import UTC, date, datetime, timedelta
from uuid import UUID

from app.repositories.episode_progress import EpisodeProgressRepository
from app.schemas.upcoming import (
    UpcomingEpisodeResponse,
    UpcomingItemResponse,
)


class MissedRecentlyService:
    """Build the Home Missed Recently Episode collection."""

    DEFAULT_DAYS = 14
    DEFAULT_LIMIT = 10

    def __init__(
        self,
        *,
        progress_repository: EpisodeProgressRepository,
    ) -> None:
        self._progress_repository = progress_repository

    def list_for_user(
        self,
        *,
        user_id: UUID,
        reference_date: date | None = None,
        days: int = DEFAULT_DAYS,
        limit: int = DEFAULT_LIMIT,
    ) -> list[UpcomingItemResponse]:
        """Return recent unwatched Episodes from actively Watching Shows.

        Today is deliberately excluded because current-day Episodes belong
        to Premiering Today on Home.

        Filtering, ordering and limiting are performed by the repository
        so the database remains the source of truth for this collection.
        """

        if days <= 0 or limit <= 0:
            return []

        today = reference_date or datetime.now(UTC).date()

        from_date = today - timedelta(days=days)
        to_date = today - timedelta(days=1)

        items = self._progress_repository.list_missed_recently(
            user_id=user_id,
            from_date=from_date,
            to_date=to_date,
            limit=limit,
        )

        return [
            UpcomingItemResponse(
                library_entry_id=item.library_entry_id,
                library_status=item.library_status,
                show=item.show,
                episode=UpcomingEpisodeResponse(
                    id=item.episode.id,
                    tmdb_id=item.episode.tmdb_id,
                    season_number=item.season_number,
                    episode_number=item.episode.episode_number,
                    title=item.episode.title,
                    air_date=item.episode.air_date,
                    runtime=item.episode.runtime,
                    still_url=item.episode.still_url,
                    is_watched=False,
                ),
            )
            for item in items
            if item.episode.air_date is not None
        ]
