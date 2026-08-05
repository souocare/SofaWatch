from datetime import date
from unittest.mock import Mock

import pytest

from app.core.config import Settings
from app.providers.tmdb import TMDBClient
from app.providers.tmdb.schemas import (
    TMDBMovieSearchResponse,
    TMDBMovieSearchResult,
    TMDBMultiMovieSearchResult,
    TMDBMultiPersonSearchResult,
    TMDBMultiSearchResponse,
    TMDBMultiTVSearchResult,
    TMDBTVSearchResponse,
    TMDBTVSearchResult,
)
from app.schemas.search import (
    SearchMediaType,
    SearchMediaTypeFilter,
)
from app.services.media_search import MediaSearchService


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
) -> MediaSearchService:
    return MediaSearchService(
        settings=settings,
        tmdb_client=tmdb_client,
    )


def test_search_all_maps_movies_and_shows_and_filters_people(
    service: MediaSearchService,
    tmdb_client: Mock,
) -> None:
    tmdb_client.search_multi.return_value = TMDBMultiSearchResponse(
        page=1,
        results=[
            TMDBMultiMovieSearchResult(
                media_type="movie",
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
            TMDBMultiTVSearchResult(
                media_type="tv",
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
            TMDBMultiPersonSearchResult(
                media_type="person",
                id=500,
                name="Example Person",
                original_name="Example Person",
                profile_path="/person.jpg",
                known_for_department="Acting",
                popularity=50,
            ),
        ],
        total_pages=3,
        total_results=30,
    )

    response = service.search(
        query="Dune",
        page=1,
        language="pt-PT",
        media_type=SearchMediaTypeFilter.ALL,
    )

    tmdb_client.search_multi.assert_called_once_with(
        query="Dune",
        page=1,
        language="pt-PT",
    )

    tmdb_client.search_tv_shows.assert_not_called()
    tmdb_client.search_movies.assert_not_called()

    assert response.page == 1
    assert response.total_pages == 3
    assert response.total_results == 30
    assert len(response.results) == 2

    movie = response.results[0]

    assert movie.media_type is SearchMediaType.MOVIE
    assert movie.tmdb_id == 438631
    assert movie.title == "Dune"
    assert movie.release_date == date(2021, 9, 15)
    assert movie.poster_url == ("https://image.tmdb.org/t/p/w500/dune.jpg")
    assert movie.backdrop_url == ("https://image.tmdb.org/t/p/original/dune-backdrop.jpg")

    show = response.results[1]

    assert show.media_type is SearchMediaType.SHOW
    assert show.tmdb_id == 95396
    assert show.title == "Severance"
    assert show.release_date == date(2022, 2, 17)
    assert show.poster_url == ("https://image.tmdb.org/t/p/w500/severance.jpg")


def test_search_shows_uses_the_tv_search_endpoint(
    service: MediaSearchService,
    tmdb_client: Mock,
) -> None:
    tmdb_client.search_tv_shows.return_value = TMDBTVSearchResponse(
        page=2,
        results=[
            TMDBTVSearchResult(
                id=95396,
                name="Severance",
                original_name="Severance",
                overview="Employees undergo a severance procedure.",
                first_air_date=date(2022, 2, 17),
                poster_path="/poster.jpg",
                backdrop_path="/backdrop.jpg",
                original_language="en",
                genre_ids=[18, 9648],
                popularity=120.5,
                vote_average=8.4,
                vote_count=2100,
            )
        ],
        total_pages=2,
        total_results=25,
    )

    response = service.search(
        query="Severance",
        page=2,
        language=None,
        media_type=SearchMediaTypeFilter.SHOW,
    )

    tmdb_client.search_tv_shows.assert_called_once_with(
        query="Severance",
        page=2,
        language=None,
    )

    tmdb_client.search_multi.assert_not_called()
    tmdb_client.search_movies.assert_not_called()

    assert response.page == 2
    assert len(response.results) == 1
    assert response.results[0].media_type is SearchMediaType.SHOW


def test_search_movies_uses_the_movie_search_endpoint(
    service: MediaSearchService,
    tmdb_client: Mock,
) -> None:
    tmdb_client.search_movies.return_value = TMDBMovieSearchResponse(
        page=1,
        results=[
            TMDBMovieSearchResult(
                id=438631,
                title="Dune",
                original_title="Dune",
                overview="Paul Atreides travels to Arrakis.",
                release_date=date(2021, 9, 15),
                poster_path="/poster.jpg",
                backdrop_path="/backdrop.jpg",
                original_language="en",
                genre_ids=[878, 12],
                popularity=95.4,
                vote_average=7.8,
                vote_count=13000,
            )
        ],
        total_pages=1,
        total_results=1,
    )

    response = service.search(
        query="Dune",
        media_type=SearchMediaTypeFilter.MOVIE,
    )

    tmdb_client.search_movies.assert_called_once_with(
        query="Dune",
        page=1,
        language=None,
    )

    tmdb_client.search_multi.assert_not_called()
    tmdb_client.search_tv_shows.assert_not_called()

    assert len(response.results) == 1
    assert response.results[0].media_type is SearchMediaType.MOVIE


def test_search_preserves_missing_images(
    service: MediaSearchService,
    tmdb_client: Mock,
) -> None:
    tmdb_client.search_movies.return_value = TMDBMovieSearchResponse(
        page=1,
        results=[
            TMDBMovieSearchResult(
                id=438631,
                title="Dune",
                original_title="Dune",
                overview="",
                release_date=None,
                poster_path=None,
                backdrop_path=None,
                original_language="en",
                genre_ids=[],
                popularity=0,
                vote_average=0,
                vote_count=0,
            )
        ],
        total_pages=1,
        total_results=1,
    )

    response = service.search(
        query="Dune",
        media_type=SearchMediaTypeFilter.MOVIE,
    )

    result = response.results[0]

    assert result.overview is None
    assert result.release_date is None
    assert result.poster_url is None
    assert result.backdrop_url is None


def test_search_image_urls_support_a_trailing_base_slash(
    tmdb_client: Mock,
) -> None:
    settings = Settings(
        secret_key="a" * 32,
        tmdb_image_base_url="https://image.tmdb.org/t/p/",
    )

    service = MediaSearchService(
        settings=settings,
        tmdb_client=tmdb_client,
    )

    tmdb_client.search_movies.return_value = TMDBMovieSearchResponse(
        page=1,
        results=[
            TMDBMovieSearchResult(
                id=438631,
                title="Dune",
                original_title="Dune",
                overview="",
                poster_path="/poster.jpg",
                backdrop_path="/backdrop.jpg",
                original_language="en",
                genre_ids=[],
                popularity=0,
                vote_average=0,
                vote_count=0,
            )
        ],
        total_pages=1,
        total_results=1,
    )

    response = service.search(
        query="Dune",
        media_type=SearchMediaTypeFilter.MOVIE,
    )

    assert response.results[0].poster_url == ("https://image.tmdb.org/t/p/w500/poster.jpg")
