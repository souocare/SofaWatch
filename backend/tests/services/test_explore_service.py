from datetime import date
from unittest.mock import Mock

import pytest

from app.core.config import Settings
from app.providers.tmdb import TMDBClient
from app.providers.tmdb.schemas import (
    TMDBMovieSearchResponse,
    TMDBMovieSearchResult,
    TMDBTVSearchResponse,
    TMDBTVSearchResult,
)
from app.schemas.explore import ExploreMediaType
from app.services.explore import ExploreService


@pytest.fixture
def settings() -> Settings:
    return Settings(
        secret_key="a" * 32,
        tmdb_image_base_url="https://image.tmdb.org/t/p",
    )


@pytest.fixture
def tmdb_client() -> Mock:
    return Mock(spec=TMDBClient)


@pytest.fixture
def service(
    settings: Settings,
    tmdb_client: Mock,
) -> ExploreService:
    return ExploreService(
        settings=settings,
        tmdb_client=tmdb_client,
    )


def test_get_trending_maps_shows_and_movies(
    service: ExploreService,
    tmdb_client: Mock,
) -> None:
    """Map provider results into Explore media items."""

    tmdb_client.get_trending_shows.return_value = TMDBTVSearchResponse(
        page=1,
        results=[
            TMDBTVSearchResult(
                id=95396,
                name="Severance",
                original_name="Severance",
                overview="Employees undergo a severance procedure.",
                first_air_date=date(2022, 2, 17),
                poster_path="/severance.jpg",
                backdrop_path="/severance-backdrop.jpg",
                original_language="en",
                genre_ids=[18, 9648],
                popularity=120.5,
                vote_average=8.4,
                vote_count=2100,
            ),
        ],
        total_pages=1,
        total_results=1,
    )

    tmdb_client.get_trending_movies.return_value = (
        TMDBMovieSearchResponse(
            page=1,
            results=[
                TMDBMovieSearchResult(
                    id=438631,
                    title="Dune",
                    original_title="Dune",
                    overview="Paul Atreides travels to Arrakis.",
                    release_date=date(2021, 9, 15),
                    poster_path="/dune.jpg",
                    backdrop_path="/dune-backdrop.jpg",
                    original_language="en",
                    genre_ids=[878, 12],
                    popularity=95.4,
                    vote_average=7.8,
                    vote_count=13000,
                ),
            ],
            total_pages=1,
            total_results=1,
        )
    )

    result = service.get_trending(
        language="pt-PT",
    )

    tmdb_client.get_trending_shows.assert_called_once_with(
        language="pt-PT",
    )

    tmdb_client.get_trending_movies.assert_called_once_with(
        language="pt-PT",
    )

    assert len(result.shows) == 1
    assert len(result.movies) == 1

    show = result.shows[0]

    assert show.media_type is ExploreMediaType.SHOW
    assert show.tmdb_id == 95396
    assert show.title == "Severance"
    assert show.release_date == date(2022, 2, 17)
    assert show.poster_url == (
        "https://image.tmdb.org/t/p/w500/severance.jpg"
    )
    assert show.backdrop_url == (
        "https://image.tmdb.org/t/p/original/severance-backdrop.jpg"
    )

    movie = result.movies[0]

    assert movie.media_type is ExploreMediaType.MOVIE
    assert movie.tmdb_id == 438631
    assert movie.title == "Dune"
    assert movie.release_date == date(2021, 9, 15)
    assert movie.poster_url == (
        "https://image.tmdb.org/t/p/w500/dune.jpg"
    )


def test_get_trending_preserves_missing_images(
    service: ExploreService,
    tmdb_client: Mock,
) -> None:
    """Keep missing provider artwork as null."""

    tmdb_client.get_trending_shows.return_value = (
        TMDBTVSearchResponse(
            page=1,
            results=[
                TMDBTVSearchResult(
                    id=95396,
                    name="Severance",
                    original_name="Severance",
                    overview="",
                    first_air_date=None,
                    poster_path=None,
                    backdrop_path=None,
                    original_language="en",
                    genre_ids=[],
                    popularity=0,
                    vote_average=0,
                    vote_count=0,
                ),
            ],
            total_pages=1,
            total_results=1,
        )
    )

    tmdb_client.get_trending_movies.return_value = (
        TMDBMovieSearchResponse(
            page=1,
            results=[],
            total_pages=0,
            total_results=0,
        )
    )

    result = service.get_trending()

    assert result.shows[0].poster_url is None
    assert result.shows[0].backdrop_url is None


def test_get_trending_supports_trailing_image_base_slash(
    tmdb_client: Mock,
) -> None:
    """Normalize the configured TMDB image base URL."""

    settings = Settings(
        secret_key="a" * 32,
        tmdb_image_base_url="https://image.tmdb.org/t/p/",
    )

    service = ExploreService(
        settings=settings,
        tmdb_client=tmdb_client,
    )

    tmdb_client.get_trending_shows.return_value = (
        TMDBTVSearchResponse(
            page=1,
            results=[
                TMDBTVSearchResult(
                    id=95396,
                    name="Severance",
                    original_name="Severance",
                    overview="",
                    first_air_date=None,
                    poster_path="/poster.jpg",
                    backdrop_path="/backdrop.jpg",
                    original_language="en",
                    genre_ids=[],
                    popularity=0,
                    vote_average=0,
                    vote_count=0,
                ),
            ],
            total_pages=1,
            total_results=1,
        )
    )

    tmdb_client.get_trending_movies.return_value = (
        TMDBMovieSearchResponse(
            page=1,
            results=[],
            total_pages=0,
            total_results=0,
        )
    )

    result = service.get_trending()

    assert result.shows[0].poster_url == (
        "https://image.tmdb.org/t/p/w500/poster.jpg"
    )