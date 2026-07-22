from app.schemas.tmdb_show import (
    ShowSearchResponse,
    ShowSearchResult,
)

from app.core.config import Settings
from app.providers.tmdb import TMDBClient


class ShowSearchService:
    """Service responsible for searching TV series."""

    def __init__(
        self,
        settings: Settings,
        tmdb_client: TMDBClient,
    ) -> None:
        self._settings = settings
        self._tmdb_client = tmdb_client

    def search(
        self,
        *,
        query: str,
        page: int = 1,
        language: str | None = None,
    ) -> ShowSearchResponse:
        """Search TV series."""

        tmdb_response = self._tmdb_client.search_tv_shows(
            query=query,
            page=page,
            language=language,
        )

        return ShowSearchResponse(
            page=tmdb_response.page,
            total_pages=tmdb_response.total_pages,
            total_results=tmdb_response.total_results,
            results=[
                ShowSearchResult(
                    tmdb_id=show.id,
                    title=show.name,
                    original_title=show.original_name,
                    overview=show.overview,
                    first_air_date=show.first_air_date,
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
                for show in tmdb_response.results
            ],
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

        return f"{self._settings.tmdb_image_base_url.rstrip('/')}/{size}{image_path}"
