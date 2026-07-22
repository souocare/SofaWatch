from app.schemas.tmdb_show import (
    ShowCountry,
    ShowDetailsResponse,
    ShowGenre,
    ShowLanguage,
    ShowNetwork,
    ShowSeasonSummary,
)

from app.core.config import Settings
from app.providers.tmdb import TMDBClient
from app.providers.tmdb.schemas import TMDBTVDetails


class ShowDetailsService:
    """Service responsible for retrieving TV series details."""

    def __init__(
        self,
        settings: Settings,
        tmdb_client: TMDBClient,
    ) -> None:
        self._settings = settings
        self._tmdb_client = tmdb_client

    def get_details(
        self,
        *,
        tmdb_id: int,
        language: str | None = None,
    ) -> ShowDetailsResponse:
        """Get detailed information about a TV series."""

        tmdb_show = self._tmdb_client.get_tv_show_details(
            tmdb_id=tmdb_id,
            language=language,
        )

        return self._map_show_details(tmdb_show)

    def _map_show_details(
        self,
        tmdb_show: TMDBTVDetails,
    ) -> ShowDetailsResponse:
        """Map TMDB TV details to the public SofaWatch schema."""

        return ShowDetailsResponse(
            tmdb_id=tmdb_show.id,
            title=tmdb_show.name,
            original_title=tmdb_show.original_name,
            overview=tmdb_show.overview,
            tagline=tmdb_show.tagline,
            first_air_date=tmdb_show.first_air_date,
            last_air_date=tmdb_show.last_air_date,
            poster_url=self._build_image_url(
                tmdb_show.poster_path,
                size="w500",
            ),
            backdrop_url=self._build_image_url(
                tmdb_show.backdrop_path,
                size="original",
            ),
            homepage_url=tmdb_show.homepage or None,
            genres=[
                ShowGenre(
                    tmdb_id=genre.id,
                    name=genre.name,
                )
                for genre in tmdb_show.genres
            ],
            seasons=[
                ShowSeasonSummary(
                    tmdb_id=season.id,
                    season_number=season.season_number,
                    title=season.name,
                    overview=season.overview,
                    air_date=season.air_date,
                    episode_count=season.episode_count,
                    poster_url=self._build_image_url(
                        season.poster_path,
                        size="w500",
                    ),
                    vote_average=season.vote_average,
                )
                for season in tmdb_show.seasons
            ],
            networks=[
                ShowNetwork(
                    tmdb_id=network.id,
                    name=network.name,
                    logo_url=self._build_image_url(
                        network.logo_path,
                        size="w500",
                    ),
                    origin_country=network.origin_country,
                )
                for network in tmdb_show.networks
            ],
            origin_countries=tmdb_show.origin_country,
            production_countries=[
                ShowCountry(
                    code=country.iso_3166_1,
                    name=country.name,
                )
                for country in tmdb_show.production_countries
            ],
            languages=tmdb_show.languages,
            spoken_languages=[
                ShowLanguage(
                    code=language.iso_639_1,
                    name=language.name,
                    english_name=language.english_name,
                )
                for language in tmdb_show.spoken_languages
            ],
            original_language=tmdb_show.original_language,
            episode_run_times=tmdb_show.episode_run_time,
            number_of_episodes=tmdb_show.number_of_episodes,
            number_of_seasons=tmdb_show.number_of_seasons,
            in_production=tmdb_show.in_production,
            status=tmdb_show.status,
            show_type=tmdb_show.type,
            popularity=tmdb_show.popularity,
            vote_average=tmdb_show.vote_average,
            vote_count=tmdb_show.vote_count,
        )

    def _build_image_url(
        self,
        image_path: str | None,
        *,
        size: str,
    ) -> str | None:
        """Build a full TMDB image URL."""

        if image_path is None:
            return None

        base_url = self._settings.tmdb_image_base_url.rstrip("/")

        return f"{base_url}/{size}{image_path}"
