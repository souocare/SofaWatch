from datetime import date
from unittest.mock import Mock
from uuid import uuid4

import pytest

from app.core.config import Settings
from app.providers.tmdb import TMDBClient
from app.providers.tmdb.schemas import (
    TMDBGenre,
    TMDBGenreListResponse,
    TMDBMovieSearchResponse,
    TMDBMovieSearchResult,
    TMDBMultiMovieSearchResult,
    TMDBMultiPersonSearchResult,
    TMDBMultiSearchResponse,
    TMDBMultiTVSearchResult,
    TMDBTVSearchResponse,
    TMDBTVSearchResult,
)
from app.repositories.library import LibraryRepository
from app.schemas.explore import ExploreMediaType, ExploreTrendingWindow
from app.services.explore import ExploreService

USER_ID = uuid4()


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
def library_repository() -> Mock:
    repository = Mock(spec=LibraryRepository)

    repository.get_show_tmdb_ids_in_library.return_value = set()
    repository.get_movie_tmdb_ids_in_library.return_value = set()

    return repository


@pytest.fixture
def service(
    settings: Settings,
    tmdb_client: Mock,
    library_repository: Mock,
) -> ExploreService:
    return ExploreService(
        settings=settings,
        tmdb_client=tmdb_client,
        library_repository=library_repository,
    )


def test_get_trending_preserves_mixed_media_order_and_filters_people(
    service: ExploreService,
    tmdb_client: Mock,
) -> None:
    """Preserve provider ranking while excluding people."""

    tmdb_client.get_trending_all.return_value = TMDBMultiSearchResponse(
        page=1,
        results=[
            TMDBMultiMovieSearchResult(
                id=438631,
                media_type="movie",
                title="Dune",
                original_title="Dune",
                overview="",
                release_date=date(2021, 9, 15),
                poster_path=None,
                backdrop_path=None,
                original_language="en",
                genre_ids=[878],
                popularity=95.4,
                vote_average=7.8,
                vote_count=13000,
            ),
            TMDBMultiPersonSearchResult(
                id=1,
                media_type="person",
                name="Someone",
                popularity=90,
            ),
            TMDBMultiTVSearchResult(
                id=95396,
                media_type="tv",
                name="Severance",
                original_name="Severance",
                overview="",
                first_air_date=date(2022, 2, 17),
                poster_path=None,
                backdrop_path=None,
                original_language="en",
                genre_ids=[18],
                popularity=120,
                vote_average=8.4,
                vote_count=2100,
            ),
        ],
        total_pages=1,
        total_results=3,
    )

    result = service.get_trending(
        user_id=USER_ID,
        window=ExploreTrendingWindow.DAY,
    )

    assert len(result.items) == 2

    assert result.items[0].media_type is (ExploreMediaType.MOVIE)

    assert result.items[0].title == "Dune"

    assert result.items[1].media_type is (ExploreMediaType.SHOW)

    assert result.items[1].title == "Severance"

    tmdb_client.get_trending_all.assert_called_once_with(
        time_window="day",
        language=None,
    )


def test_get_trending_preserves_missing_images(
    service: ExploreService,
    tmdb_client: Mock,
) -> None:
    """Keep missing provider artwork as null."""

    tmdb_client.get_trending_all.return_value = TMDBMultiSearchResponse(
        page=1,
        results=[
            TMDBMultiTVSearchResult(
                id=95396,
                media_type="tv",
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

    result = service.get_trending(
        user_id=USER_ID,
        window=ExploreTrendingWindow.WEEK,
    )

    assert len(result.items) == 1

    item = result.items[0]

    assert item.poster_url is None
    assert item.backdrop_url is None

    tmdb_client.get_trending_all.assert_called_once_with(
        time_window="week",
        language=None,
    )


def test_get_trending_supports_trailing_image_base_slash(
    tmdb_client: Mock,
    library_repository: Mock,
) -> None:
    settings = Settings(
        secret_key="a" * 32,
        tmdb_image_base_url="https://image.tmdb.org/t/p/",
    )

    service = ExploreService(
        settings=settings,
        tmdb_client=tmdb_client,
        library_repository=library_repository,
    )

    tmdb_client.get_trending_all.return_value = TMDBMultiSearchResponse(
        page=1,
        results=[
            TMDBMultiTVSearchResult(
                id=95396,
                media_type="tv",
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

    result = service.get_trending(
        user_id=USER_ID,
        window=ExploreTrendingWindow.WEEK,
    )

    assert len(result.items) == 1

    item = result.items[0]

    assert item.poster_url == "https://image.tmdb.org/t/p/w500/poster.jpg"

    assert item.backdrop_url == "https://image.tmdb.org/t/p/original/backdrop.jpg"


def test_get_popular_shows_maps_tmdb_results(
    service: ExploreService,
    tmdb_client: Mock,
) -> None:
    tmdb_client.get_popular_tv_shows.return_value = TMDBTVSearchResponse(
        page=1,
        results=[
            TMDBTVSearchResult(
                id=95396,
                name="Severance",
                original_name="Severance",
                overview="",
                first_air_date=date(
                    2022,
                    2,
                    17,
                ),
                poster_path="/poster.jpg",
                backdrop_path="/backdrop.jpg",
                original_language="en",
                genre_ids=[18],
                popularity=120,
                vote_average=8.4,
                vote_count=2100,
            ),
        ],
        total_pages=1,
        total_results=1,
    )

    result = service.get_popular_shows(
        user_id=USER_ID,
    )

    assert len(result.items) == 1

    item = result.items[0]

    assert item.media_type is ExploreMediaType.SHOW
    assert item.tmdb_id == 95396
    assert item.title == "Severance"
    assert item.release_date == date(
        2022,
        2,
        17,
    )

    tmdb_client.get_popular_tv_shows.assert_called_once_with(
        language=None,
    )


def test_get_popular_movies_maps_tmdb_movies(
    service: ExploreService,
    tmdb_client: Mock,
) -> None:
    """Map popular TMDB Movies into Explore items."""

    tmdb_client.get_popular_movies.return_value = TMDBMovieSearchResponse(
        page=1,
        results=[
            TMDBMovieSearchResult(
                id=438631,
                title="Dune",
                original_title="Dune",
                overview=("Paul Atreides travels to Arrakis."),
                release_date=date(
                    2021,
                    9,
                    15,
                ),
                poster_path="/dune.jpg",
                backdrop_path=("/dune-backdrop.jpg"),
                original_language="en",
                genre_ids=[878, 12],
                popularity=95.4,
                vote_average=7.8,
                vote_count=13000,
                adult=False,
                video=False,
            ),
        ],
        total_pages=1,
        total_results=1,
    )

    result = service.get_popular_movies(
        user_id=USER_ID,
    )

    assert len(result.items) == 1

    movie = result.items[0]

    assert movie.media_type is ExploreMediaType.MOVIE
    assert movie.tmdb_id == 438631
    assert movie.title == "Dune"

    tmdb_client.get_popular_movies.assert_called_once_with(
        language=None,
    )


def test_get_genres_returns_independent_show_and_movie_genres(
    service: ExploreService,
    tmdb_client: Mock,
) -> None:
    tmdb_client.get_tv_genres.return_value = TMDBGenreListResponse(
        genres=[
            TMDBGenre(
                id=18,
                name="Drama",
            ),
            TMDBGenre(
                id=35,
                name="Comedy",
            ),
        ],
    )

    tmdb_client.get_movie_genres.return_value = TMDBGenreListResponse(
        genres=[
            TMDBGenre(
                id=28,
                name="Action",
            ),
            TMDBGenre(
                id=878,
                name="Science Fiction",
            ),
        ],
    )

    result = service.get_genres()

    assert [genre.id for genre in result.shows] == [
        18,
        35,
    ]

    assert [genre.name for genre in result.shows] == [
        "Drama",
        "Comedy",
    ]

    assert [genre.id for genre in result.movies] == [
        28,
        878,
    ]

    assert [genre.name for genre in result.movies] == [
        "Action",
        "Science Fiction",
    ]


def test_get_genres_forwards_language(
    service: ExploreService,
    tmdb_client: Mock,
) -> None:
    tmdb_client.get_tv_genres.return_value = TMDBGenreListResponse(
        genres=[],
    )

    tmdb_client.get_movie_genres.return_value = TMDBGenreListResponse(
        genres=[],
    )

    service.get_genres(
        language="pt-PT",
    )

    tmdb_client.get_tv_genres.assert_called_once_with(
        language="pt-PT",
    )

    tmdb_client.get_movie_genres.assert_called_once_with(
        language="pt-PT",
    )
