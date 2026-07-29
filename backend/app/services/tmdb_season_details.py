from app.providers.tmdb import TMDBClient
from app.providers.tmdb.schemas import TMDBSeasonDetails
from app.schemas.tmdb_episode import EpisodeSummary


class TMDBSeasonDetailsService:
    """Service responsible for retrieving TV season details."""

    def __init__(
        self,
        tmdb_client: TMDBClient,
    ) -> None:
        self._tmdb_client = tmdb_client

    def get_episodes(
        self,
        *,
        tmdb_id: int,
        season_number: int,
        language: str | None = None,
    ) -> list[EpisodeSummary]:
        """Get episodes belonging to a TV season."""

        tmdb_season = self._tmdb_client.get_tv_season_details(
            tmdb_id=tmdb_id,
            season_number=season_number,
            language=language,
        )

        return self._map_episodes(tmdb_season)

    @staticmethod
    def _map_episodes(
        tmdb_season: TMDBSeasonDetails,
    ) -> list[EpisodeSummary]:
        """Map TMDB episodes to SofaWatch schemas."""

        return [
            EpisodeSummary(
                tmdb_id=episode.id,
                episode_number=episode.episode_number,
                title=episode.name,
                overview=episode.overview,
                air_date=episode.air_date,
                runtime=episode.runtime,
                vote_average=episode.vote_average,
                vote_count=episode.vote_count,
                still_path=episode.still_path,
            )
            for episode in tmdb_season.episodes
        ]
