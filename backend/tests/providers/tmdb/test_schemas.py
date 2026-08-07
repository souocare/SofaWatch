from datetime import date

import pytest
from pydantic import ValidationError
from app.providers.tmdb.schemas import (
    TMDBMovieSearchResponse,
    TMDBMultiMovieSearchResult,
    TMDBMultiPersonSearchResult,
    TMDBMultiSearchResponse,
    TMDBMultiSearchResult,
    TMDBMultiTVSearchResult,
    TMDBMovieDetails
)


def test_movie_search_response_parses_a_movie() -> None:
    response = TMDBMovieSearchResponse.model_validate(
        {
            "page": 1,
            "results": [
                {
                    "id": 438631,
                    "title": "Dune",
                    "original_title": "Dune",
                    "overview": "Paul Atreides travels to Arrakis.",
                    "release_date": "2021-09-15",
                    "poster_path": "/dune-poster.jpg",
                    "backdrop_path": "/dune-backdrop.jpg",
                    "original_language": "en",
                    "genre_ids": [878, 12],
                    "popularity": 95.4,
                    "vote_average": 7.8,
                    "vote_count": 13000,
                    "adult": False,
                    "video": False,
                }
            ],
            "total_pages": 3,
            "total_results": 50,
        }
    )

    assert response.page == 1
    assert len(response.results) == 1

    movie = response.results[0]

    assert movie.id == 438631
    assert movie.title == "Dune"
    assert movie.release_date == date(2021, 9, 15)
    assert movie.genre_ids == [878, 12]


def test_movie_search_response_normalizes_empty_release_date() -> None:
    response = TMDBMovieSearchResponse.model_validate(
        {
            "page": 1,
            "results": [
                {
                    "id": 438631,
                    "title": "Dune",
                    "original_title": "Dune",
                    "overview": "",
                    "release_date": "",
                    "poster_path": None,
                    "backdrop_path": None,
                    "original_language": "en",
                    "genre_ids": [],
                    "popularity": 0.0,
                    "vote_average": 0.0,
                    "vote_count": 0,
                }
            ],
            "total_pages": 1,
            "total_results": 1,
        }
    )

    assert response.results[0].release_date is None


def test_multi_search_response_selects_models_by_media_type() -> None:
    response = TMDBMultiSearchResponse.model_validate(
        {
            "page": 1,
            "results": [
                {
                    "media_type": "movie",
                    "id": 438631,
                    "title": "Dune",
                    "original_title": "Dune",
                    "overview": "Paul Atreides travels to Arrakis.",
                    "release_date": "2021-09-15",
                    "poster_path": "/dune.jpg",
                    "backdrop_path": "/dune-backdrop.jpg",
                    "original_language": "en",
                    "genre_ids": [878, 12],
                    "popularity": 95.4,
                    "vote_average": 7.8,
                    "vote_count": 13000,
                },
                {
                    "media_type": "tv",
                    "id": 95396,
                    "name": "Severance",
                    "original_name": "Severance",
                    "overview": "Employees undergo a severance procedure.",
                    "first_air_date": "2022-02-17",
                    "poster_path": "/severance.jpg",
                    "backdrop_path": "/severance-backdrop.jpg",
                    "original_language": "en",
                    "genre_ids": [18, 9648],
                    "popularity": 120.5,
                    "vote_average": 8.4,
                    "vote_count": 2100,
                },
                {
                    "media_type": "person",
                    "id": 500,
                    "name": "Example Person",
                    "original_name": "Example Person",
                    "profile_path": "/person.jpg",
                    "known_for_department": "Acting",
                    "popularity": 50.0,
                },
            ],
            "total_pages": 1,
            "total_results": 3,
        }
    )

    assert len(response.results) == 3

    assert isinstance(
        response.results[0],
        TMDBMultiMovieSearchResult,
    )

    assert isinstance(
        response.results[1],
        TMDBMultiTVSearchResult,
    )

    assert isinstance(
        response.results[2],
        TMDBMultiPersonSearchResult,
    )


def test_multi_search_result_type_alias_accepts_supported_results() -> None:
    results: list[TMDBMultiSearchResult] = []

    assert results == []



def _movie_payload() -> dict[str, object]:
    return {
        "id": 438631,
        "title": "Dune",
        "original_title": "Dune",
        "overview": "Paul Atreides travels to Arrakis.",
        "tagline": "Beyond fear, destiny awaits.",
        "release_date": "2021-09-15",
        "poster_path": "/poster.jpg",
        "backdrop_path": "/backdrop.jpg",
        "original_language": "en",
        "runtime": 155,
        "status": "Released",
        "genres": [
            {
                "id": 878,
                "name": "Science Fiction",
            },
            {
                "id": 12,
                "name": "Adventure",
            },
        ],
        "popularity": 123.45,
        "vote_average": 7.8,
        "vote_count": 13000,
        "adult": False,
        "video": False,
    }


def test_movie_details_parses_valid_payload() -> None:
    movie = TMDBMovieDetails.model_validate(_movie_payload())

    assert movie.id == 438631
    assert movie.title == "Dune"
    assert movie.release_date == date(2021, 9, 15)
    assert movie.runtime == 155
    assert len(movie.genres) == 2
    assert movie.genres[0].name == "Science Fiction"


def test_movie_details_normalizes_empty_release_date() -> None:
    payload = _movie_payload()
    payload["release_date"] = ""

    movie = TMDBMovieDetails.model_validate(payload)

    assert movie.release_date is None


def test_movie_details_accepts_null_release_date() -> None:
    payload = _movie_payload()
    payload["release_date"] = None

    movie = TMDBMovieDetails.model_validate(payload)

    assert movie.release_date is None


def test_movie_details_ignores_unmapped_tmdb_fields() -> None:
    payload = _movie_payload()
    payload["budget"] = 165_000_000
    payload["revenue"] = 407_000_000
    payload["production_companies"] = []

    movie = TMDBMovieDetails.model_validate(payload)

    assert movie.id == 438631


def test_movie_details_rejects_invalid_release_date() -> None:
    payload = _movie_payload()
    payload["release_date"] = "not-a-date"

    with pytest.raises(ValidationError):
        TMDBMovieDetails.model_validate(payload)