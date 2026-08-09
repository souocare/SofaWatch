from app.core.config import Settings
from app.providers.tmdb.client import TMDBClient
from app.providers.tmdb.schemas import (
    TMDBMovieSearchResult,
    TMDBMultiMovieSearchResult,
    TMDBMultiPersonSearchResult,
    TMDBMultiTVSearchResult,
    TMDBTVSearchResult,
)
from app.schemas.explore import (
    ExploreMediaCollection,
    ExploreMediaItem,
    ExploreMediaType,
    ExploreTrendingResponse,
    ExploreTrendingWindow,
)



class ExploreService:
    """Build discovery content for Explore."""

    def __init__(
        self,
        *,
        settings: Settings,
        tmdb_client: TMDBClient,
    ) -> None:
        self._settings = settings
        self._tmdb_client = tmdb_client

    def get_trending(
        self,
        *,
        window: ExploreTrendingWindow,
        language: str | None = None,
    ) -> ExploreTrendingResponse:
        """Return ordered trending Movies and TV series."""

        response = self._tmdb_client.get_trending_all(
            time_window=window.value,
            language=language,
        )

        items: list[ExploreMediaItem] = []

        for result in response.results:
            if isinstance(
                result,
                TMDBMultiTVSearchResult,
            ):
                items.append(
                    self._map_show(result),
                )
                continue

            if isinstance(
                result,
                TMDBMultiMovieSearchResult,
            ):
                items.append(
                    self._map_movie(result),
                )

        return ExploreTrendingResponse(
            items=items,
        )
    def _map_show(
        self,
        item: TMDBMultiTVSearchResult,
    ) -> ExploreMediaItem:
        return ExploreMediaItem(
            media_type=ExploreMediaType.SHOW,
            tmdb_id=item.id,
            title=item.name,
            original_title=item.original_name,
            overview=item.overview,
            release_date=item.first_air_date,
            poster_url=self._image_url(
                "w500",
                item.poster_path,
            ),
            backdrop_url=self._image_url(
                "original",
                item.backdrop_path,
            ),
            original_language=item.original_language,
            genre_ids=item.genre_ids,
            popularity=item.popularity,
            vote_average=item.vote_average,
            vote_count=item.vote_count,
        )

    def _map_movie(
        self,
        item: TMDBMultiMovieSearchResult,
    ) -> ExploreMediaItem:
        return ExploreMediaItem(
            media_type=ExploreMediaType.MOVIE,
            tmdb_id=item.id,
            title=item.title,
            original_title=item.original_title,
            overview=item.overview,
            release_date=item.release_date,
            poster_url=self._image_url(
                "w500",
                item.poster_path,
            ),
            backdrop_url=self._image_url(
                "original",
                item.backdrop_path,
            ),
            original_language=item.original_language,
            genre_ids=item.genre_ids,
            popularity=item.popularity,
            vote_average=item.vote_average,
            vote_count=item.vote_count,
        )

    def _image_url(
        self,
        size: str,
        path: str | None,
    ) -> str | None:
        if path is None:
            return None

        base_url = (
            self._settings.tmdb_image_base_url
            .rstrip("/")
        )

        return f"{base_url}/{size}{path}"

    def get_popular_shows(
        self,
        *,
        language: str | None = None,
    ) -> ExploreMediaCollection:
        """Return popular TV series for Explore."""

        response = self._tmdb_client.get_popular_tv_shows(
            language=language,
        )

        items = [
            self._map_show(item)
            for item in response.results
        ]

        return ExploreMediaCollection(
            items=items,
        )

    def get_popular_movies(
        self,
        *,
        language: str | None = None,
    ) -> ExploreMediaCollection:
        """Return popular Movies for Explore."""

        response = self._tmdb_client.get_popular_movies(
            language=language,
        )

        items = [
            self._map_movie(item)
            for item in response.results
        ]

        return ExploreMediaCollection(
            items=items,
        )

    