from datetime import date

import pytest
from pydantic import ValidationError

from app.schemas.search import (
    SearchMediaType,
    SearchMediaTypeFilter,
    SearchResponse,
    SearchResult,
)


def test_search_media_type_values() -> None:
    assert SearchMediaType.SHOW.value == "show"
    assert SearchMediaType.MOVIE.value == "movie"


def test_search_media_type_filter_values() -> None:
    assert SearchMediaTypeFilter.ALL.value == "all"
    assert SearchMediaTypeFilter.SHOW.value == "show"
    assert SearchMediaTypeFilter.MOVIE.value == "movie"


def test_search_result_represents_a_show() -> None:
    result = SearchResult(
        media_type=SearchMediaType.SHOW,
        tmdb_id=95396,
        title="Severance",
        original_title="Severance",
        overview="Employees undergo a severance procedure.",
        release_date=date(2022, 2, 17),
        poster_url="https://image.tmdb.org/t/p/w500/severance.jpg",
        backdrop_url=("https://image.tmdb.org/t/p/original/severance-backdrop.jpg"),
        original_language="en",
        genre_ids=[18, 9648],
        popularity=120.5,
        vote_average=8.4,
        vote_count=2100,
    )

    assert result.media_type is SearchMediaType.SHOW
    assert result.tmdb_id == 95396
    assert result.release_date == date(2022, 2, 17)


def test_search_result_represents_a_movie() -> None:
    result = SearchResult(
        media_type=SearchMediaType.MOVIE,
        tmdb_id=438631,
        title="Dune",
        original_title="Dune",
        overview="Paul Atreides travels to Arrakis.",
        release_date=date(2021, 9, 15),
        poster_url="https://image.tmdb.org/t/p/w500/dune.jpg",
        backdrop_url="https://image.tmdb.org/t/p/original/dune-backdrop.jpg",
        original_language="en",
        genre_ids=[878, 12],
        popularity=95.4,
        vote_average=7.8,
        vote_count=13000,
    )

    assert result.media_type is SearchMediaType.MOVIE
    assert result.tmdb_id == 438631
    assert result.release_date == date(2021, 9, 15)


def test_search_result_supports_missing_optional_content() -> None:
    result = SearchResult(
        media_type=SearchMediaType.SHOW,
        tmdb_id=95396,
        title="Severance",
        original_title="Severance",
        original_language="en",
    )

    assert result.overview is None
    assert result.release_date is None
    assert result.poster_url is None
    assert result.backdrop_url is None
    assert result.genre_ids == []
    assert result.popularity == 0.0
    assert result.vote_average == 0.0
    assert result.vote_count == 0


def test_search_response_contains_mixed_results() -> None:
    response = SearchResponse(
        page=1,
        results=[
            SearchResult(
                media_type=SearchMediaType.SHOW,
                tmdb_id=95396,
                title="Severance",
                original_title="Severance",
                original_language="en",
            ),
            SearchResult(
                media_type=SearchMediaType.MOVIE,
                tmdb_id=438631,
                title="Dune",
                original_title="Dune",
                original_language="en",
            ),
        ],
        total_pages=2,
        total_results=25,
    )

    assert response.page == 1
    assert len(response.results) == 2
    assert response.results[0].media_type is SearchMediaType.SHOW
    assert response.results[1].media_type is SearchMediaType.MOVIE


def test_search_result_rejects_an_invalid_tmdb_id() -> None:
    with pytest.raises(ValidationError):
        SearchResult(
            media_type=SearchMediaType.MOVIE,
            tmdb_id=0,
            title="Invalid movie",
            original_title="Invalid movie",
            original_language="en",
        )


def test_search_result_rejects_vote_average_above_ten() -> None:
    with pytest.raises(ValidationError):
        SearchResult(
            media_type=SearchMediaType.MOVIE,
            tmdb_id=438631,
            title="Dune",
            original_title="Dune",
            original_language="en",
            vote_average=10.1,
        )
