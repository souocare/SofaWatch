from app.models.genre import Genre
from app.models.show import Show


def test_show_can_be_created() -> None:
    show = Show(
        tmdb_id=1399,
        title="Game of Thrones",
        original_title="Game of Thrones",
        overview="Nine noble families fight for control of Westeros.",
        tagline="Winter is coming.",
        original_language="en",
        status="Ended",
        show_type="Scripted",
        in_production=False,
        number_of_seasons=8,
        number_of_episodes=73,
        popularity=100.0,
        vote_average=8.4,
        vote_count=25000,
        metadata_language="en-US",
    )

    assert show.tmdb_id == 1399
    assert show.title == "Game of Thrones"
    assert show.original_title == "Game of Thrones"
    assert show.in_production is False
    assert show.number_of_seasons == 8
    assert show.number_of_episodes == 73
    assert show.metadata_language == "en-US"


def test_show_can_have_genres() -> None:
    drama = Genre(
        name="Drama",
        slug="drama",
    )
    fantasy = Genre(
        name="Fantasy",
        slug="fantasy",
    )

    show = Show(
        tmdb_id=1399,
        title="Game of Thrones",
        original_title="Game of Thrones",
        overview="Nine noble families fight for control of Westeros.",
        tagline="Winter is coming.",
        original_language="en",
        status="Ended",
        show_type="Scripted",
        in_production=False,
        number_of_seasons=8,
        number_of_episodes=73,
        popularity=100.0,
        vote_average=8.4,
        vote_count=25000,
        metadata_language="en-US",
        genres=[drama, fantasy],
    )

    assert show.genres == [drama, fantasy]
    assert drama in show.genres
    assert fantasy in show.genres




def test_poster_url_returns_endpoint() -> None:
    show = Show()

    show.id = "12345678-1234-1234-1234-123456789abc"
    show.tmdb_poster_path = "/poster.jpg"

    assert show.poster_url == (
        "/api/v1/images/shows/"
        "12345678-1234-1234-1234-123456789abc/poster"
    )


def test_poster_url_returns_none_when_no_image_exists() -> None:
    show = Show()

    assert show.poster_url is None

def test_backdrop_url_returns_endpoint() -> None:
    show = Show()

    show.id = "12345678-1234-1234-1234-123456789abc"
    show.tmdb_backdrop_path = "/backdrop.jpg"

    assert show.backdrop_url == (
        "/api/v1/images/shows/"
        "12345678-1234-1234-1234-123456789abc/backdrop"
    )