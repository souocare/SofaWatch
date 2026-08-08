from app.core.config import Settings
from app.providers.tmdb import TMDBClient
from app.providers.tmdb.schemas import (
    TMDBMovieSearchResult,
    TMDBMultiMovieSearchResult,
    TMDBMultiPersonSearchResult,
    TMDBMultiTVSearchResult,
    TMDBTVSearchResult,
)
from app.schemas.search import (
    SearchMediaType,
    SearchMediaTypeFilter,
    SearchResponse,
    SearchResult,
)
from uuid import UUID
from app.repositories.library import LibraryRepository


class MediaSearchService:
    """Service responsible for searching movies and TV series."""

    def __init__(
        self,
        settings: Settings,
        tmdb_client: TMDBClient,
        library_repository: LibraryRepository,
    ) -> None:
        self._settings = settings
        self._tmdb_client = tmdb_client
        self._library_repository = library_repository

    def search(
        self,
        *,
        user_id: UUID,
        query: str,
        page: int = 1,
        language: str | None = None,
        media_type: SearchMediaTypeFilter = SearchMediaTypeFilter.ALL,
    ) -> SearchResponse:
        """Search movies and TV series and resolve library membership."""

        if media_type is SearchMediaTypeFilter.SHOW:
            response = self._search_shows(
                query=query,
                page=page,
                language=language,
            )
        elif media_type is SearchMediaTypeFilter.MOVIE:
            response = self._search_movies(
                query=query,
                page=page,
                language=language,
            )
        else:
            response = self._search_all(
                query=query,
                page=page,
                language=language,
            )

        return self._enrich_library_state(
            response=response,
            user_id=user_id,
        )

    def _search_all(
        self,
        *,
        query: str,
        page: int,
        language: str | None,
    ) -> SearchResponse:
        """Search all supported media types using TMDB multi-search."""

        tmdb_response = self._tmdb_client.search_multi(
            query=query,
            page=page,
            language=language,
        )

        results: list[SearchResult] = []

        for item in tmdb_response.results:
            if isinstance(item, TMDBMultiMovieSearchResult):
                results.append(
                    self._map_movie_result(item),
                )
                continue

            if isinstance(item, TMDBMultiTVSearchResult):
                results.append(
                    self._map_show_result(item),
                )
                continue

            if isinstance(item, TMDBMultiPersonSearchResult):
                continue

        return SearchResponse(
            page=tmdb_response.page,
            results=results,
            total_pages=tmdb_response.total_pages,
            total_results=tmdb_response.total_results,
        )

    def _search_shows(
        self,
        *,
        query: str,
        page: int,
        language: str | None,
    ) -> SearchResponse:
        """Search only TV series."""

        tmdb_response = self._tmdb_client.search_tv_shows(
            query=query,
            page=page,
            language=language,
        )

        return SearchResponse(
            page=tmdb_response.page,
            results=[self._map_show_result(show) for show in tmdb_response.results],
            total_pages=tmdb_response.total_pages,
            total_results=tmdb_response.total_results,
        )

    def _search_movies(
        self,
        *,
        query: str,
        page: int,
        language: str | None,
    ) -> SearchResponse:
        """Search only movies."""

        tmdb_response = self._tmdb_client.search_movies(
            query=query,
            page=page,
            language=language,
        )

        return SearchResponse(
            page=tmdb_response.page,
            results=[self._map_movie_result(movie) for movie in tmdb_response.results],
            total_pages=tmdb_response.total_pages,
            total_results=tmdb_response.total_results,
        )

    def _map_show_result(
        self,
        show: TMDBTVSearchResult,
    ) -> SearchResult:
        """Convert a TMDB TV result into the public search contract."""

        return SearchResult(
            media_type=SearchMediaType.SHOW,
            tmdb_id=show.id,
            title=show.name,
            original_title=show.original_name,
            overview=show.overview or None,
            release_date=show.first_air_date,
            poster_url=self._build_image_url(
                show.poster_path,
                size="w500",
            ),
            backdrop_url=self._build_image_url(
                show.backdrop_path,
                size="original",
            ),
            original_language=show.original_language,
            genre_ids=show.genre_ids,
            popularity=show.popularity,
            vote_average=show.vote_average,
            vote_count=show.vote_count,
        )

    def _map_movie_result(
        self,
        movie: TMDBMovieSearchResult,
    ) -> SearchResult:
        """Convert a TMDB movie result into the public search contract."""

        return SearchResult(
            media_type=SearchMediaType.MOVIE,
            tmdb_id=movie.id,
            title=movie.title,
            original_title=movie.original_title,
            overview=movie.overview or None,
            release_date=movie.release_date,
            poster_url=self._build_image_url(
                movie.poster_path,
                size="w500",
            ),
            backdrop_url=self._build_image_url(
                movie.backdrop_path,
                size="original",
            ),
            original_language=movie.original_language,
            genre_ids=movie.genre_ids,
            popularity=movie.popularity,
            vote_average=movie.vote_average,
            vote_count=movie.vote_count,
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


    def _enrich_library_state(
        self,
        *,
        response: SearchResponse,
        user_id: UUID,
    ) -> SearchResponse:
        """Resolve library membership for a complete Search page."""

        show_tmdb_ids = {
            result.tmdb_id
            for result in response.results
            if result.media_type is SearchMediaType.SHOW
        }

        movie_tmdb_ids = {
            result.tmdb_id
            for result in response.results
            if result.media_type is SearchMediaType.MOVIE
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

        enriched_results = [
            result.model_copy(
                update={
                    "in_library": (
                        result.tmdb_id
                        in (
                            library_show_tmdb_ids
                            if result.media_type is SearchMediaType.SHOW
                            else library_movie_tmdb_ids
                        )
                    )
                }
            )
            for result in response.results
        ]

        return response.model_copy(
            update={
                "results": enriched_results,
            }
        )