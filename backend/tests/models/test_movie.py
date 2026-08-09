from app.models.genre import Genre
from app.models.movie import Movie


def test_movie_can_be_created() -> None:
    movie = Movie(
        tmdb_id=438631,
        title="Dune",
        original_title="Dune",
        overview="Paul Atreides travels to Arrakis.",
        tagline="Beyond fear, destiny awaits.",
        original_language="en",
        runtime=155,
        status="Released",
        adult=False,
        video=False,
        popularity=100.0,
        vote_average=7.8,
        vote_count=13000,
        metadata_language="en-US",
    )

    assert movie.tmdb_id == 438631
    assert movie.title == "Dune"
    assert movie.original_title == "Dune"
    assert movie.runtime == 155
    assert movie.status == "Released"
    assert movie.adult is False
    assert movie.video is False
    assert movie.metadata_language == "en-US"


def test_movie_can_have_genres() -> None:
    science_fiction = Genre(
        name="Science Fiction",
        slug="science-fiction",
    )

    adventure = Genre(
        name="Adventure",
        slug="adventure",
    )

    movie = Movie(
        tmdb_id=438631,
        title="Dune",
        original_title="Dune",
        original_language="en",
        runtime=155,
        status="Released",
        adult=False,
        video=False,
        popularity=100.0,
        vote_average=7.8,
        vote_count=13000,
        metadata_language="en-US",
        genres=[
            science_fiction,
            adventure,
        ],
    )

    assert movie.genres == [
        science_fiction,
        adventure,
    ]


def test_poster_url_returns_endpoint() -> None:
    movie = Movie()

    movie.id = "12345678-1234-1234-1234-123456789abc"
    movie.tmdb_poster_path = "/poster.jpg"

    assert movie.poster_url == ("/api/v1/images/movies/12345678-1234-1234-1234-123456789abc/poster")


def test_poster_url_returns_none_when_no_image_exists() -> None:
    movie = Movie()

    assert movie.poster_url is None


def test_backdrop_url_returns_endpoint() -> None:
    movie = Movie()

    movie.id = "12345678-1234-1234-1234-123456789abc"
    movie.tmdb_backdrop_path = "/backdrop.jpg"

    assert movie.backdrop_url == (
        "/api/v1/images/movies/12345678-1234-1234-1234-123456789abc/backdrop"
    )


def test_backdrop_url_returns_none_when_no_image_exists() -> None:
    movie = Movie()

    assert movie.backdrop_url is None
