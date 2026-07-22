from app.schemas.tmdb_show import ShowDetailsResponse
from sqlalchemy.orm import Session

from app.models.show import Show


class ShowImportService:
    """Import and update TV series in the local database."""

    def __init__(self, db_session: Session) -> None:
        self._db_session = db_session

    def create_from_details(
        self,
        *,
        details: ShowDetailsResponse,
        metadata_language: str,
    ) -> Show:
        show = Show(
            tmdb_id=details.tmdb_id,
            title=details.title,
            original_title=details.original_title,
            overview=details.overview,
            tagline=details.tagline,
            first_air_date=details.first_air_date,
            last_air_date=details.last_air_date,
            homepage_url=details.homepage_url,
            original_language=details.original_language,
            status=details.status,
            show_type=details.show_type,
            in_production=details.in_production,
            number_of_seasons=details.number_of_seasons,
            number_of_episodes=details.number_of_episodes,
            episode_run_time=(details.episode_run_times[0] if details.episode_run_times else None),
            popularity=details.popularity,
            vote_average=details.vote_average,
            vote_count=details.vote_count,
            metadata_language=metadata_language,
        )

        self._db_session.add(show)
        self._db_session.commit()
        self._db_session.refresh(show)

        return show
