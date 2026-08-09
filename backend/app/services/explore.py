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
from uuid import UUID

from app.repositories.library import LibraryRepository



class ExploreService:
    """Build discovery content for Explore."""

    def __init__(
        self,
        *,
        settings: Settings,
        tmdb_client: TMDBClient,
        library_repository: LibraryRepository,
    ) -> None:
        self._settings = settings
        self._tmdb_client = tmdb_client
        self._library_repository = library_repository

    def get_trending(
        self,
        *,
        user_id: UUID,
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
            items=self._enrich_library_state(
                items=items,
                user_id=user_id,
            ),
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

    def _enrich_library_state(
        self,
        *,
        items: list[ExploreMediaItem],
        user_id: UUID,
    ) -> list[ExploreMediaItem]:
        """Resolve Library membership for a collection of Explore items."""

        if not items:
            return items

        show_tmdb_ids = {
            item.tmdb_id
            for item in items
            if item.media_type is ExploreMediaType.SHOW
        }

        movie_tmdb_ids = {
            item.tmdb_id
            for item in items
            if item.media_type is ExploreMediaType.MOVIE
        }

        library_show_tmdb_ids = (
            self._library_repository.get_show_tmdb_ids_in_library(
                user_id=user_id,
                tmdb_ids=show_tmdb_ids,
            )
        )

        library_movie_tmdb_ids = (
            self._library_repository.get_movie_tmdb_ids_in_library(
                user_id=user_id,
                tmdb_ids=movie_tmdb_ids,
            )
        )

        return [
            item.model_copy(
                update={
                    "in_library": (
                        item.tmdb_id
                        in (
                            library_show_tmdb_ids
                            if item.media_type is ExploreMediaType.SHOW
                            else library_movie_tmdb_ids
                        )
                    )
                },
            )
            for item in items
        ]

    def get_popular_shows(
        self,
        *,
        user_id: UUID,
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
            items=self._enrich_library_state(
                items=items,
                user_id=user_id,
            ),
        )

    def get_popular_movies(
        self,
        *,
        user_id: UUID,
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
            items=self._enrich_library_state(
                items=items,
                user_id=user_id,
            ),
        )

    