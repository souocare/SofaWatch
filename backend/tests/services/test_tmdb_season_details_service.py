from datetime import date
from unittest.mock import Mock

import pytest

from app.providers.tmdb import TMDBClient
from app.providers.tmdb.schemas import (
    TMDBEpisodeSummary,
    TMDBSeasonDetails,
)
from app.services.tmdb_season_details import TMDBSeasonDetailsService

TMDB_ID = 95396
SEASON_NUMBER = 1


@pytest.fixture
def tmdb_client() -> Mock:
    """Provide a mocked TMDB client."""

    return Mock(spec=TMDBClient)


@pytest.fixture
def season_details() -> TMDBSeasonDetails:
    """Provide representative TMDB season metadata."""

    return TMDBSeasonDetails(
        id=134792,
        air_date=date(2022, 2, 18),
        name="Season 1",
        overview="The first season.",
        poster_path="/season-1.jpg",
        season_number=1,
        episodes=[
            TMDBEpisodeSummary(
                id=2001,
                name="Good News About Hell",
                overview="Mark starts a new day at Lumon.",
                vote_average=8.1,
                vote_count=42,
                air_date=date(2022, 2, 18),
                episode_number=1,
                episode_type="standard",
                production_code="",
                runtime=57,
                season_number=1,
                show_id=TMDB_ID,
                still_path="/episode-1.jpg",
            ),
            TMDBEpisodeSummary(
                id=2002,
                name="Half Loop",
                overview="The team continues its work.",
                vote_average=8.2,
                vote_count=38,
                air_date=date(2022, 2, 25),
                episode_number=2,
                episode_type="standard",
                production_code="",
                runtime=54,
                season_number=1,
                show_id=TMDB_ID,
                still_path="/episode-2.jpg",
            ),
        ],
    )


@pytest.fixture
def service(
    tmdb_client: Mock,
) -> TMDBSeasonDetailsService:
    """Provide a season details service using a mocked TMDB client."""

    return TMDBSeasonDetailsService(
        tmdb_client=tmdb_client,
    )


def test_get_episodes_requests_season_details(
    service: TMDBSeasonDetailsService,
    tmdb_client: Mock,
    season_details: TMDBSeasonDetails,
) -> None:
    """Request the correct TV season from TMDB."""

    tmdb_client.get_tv_season_details.return_value = season_details

    service.get_episodes(
        tmdb_id=TMDB_ID,
        season_number=SEASON_NUMBER,
        language="en-US",
    )

    tmdb_client.get_tv_season_details.assert_called_once_with(
        tmdb_id=TMDB_ID,
        season_number=SEASON_NUMBER,
        language="en-US",
    )


def test_get_episodes_forwards_selected_language(
    service: TMDBSeasonDetailsService,
    tmdb_client: Mock,
    season_details: TMDBSeasonDetails,
) -> None:
    """Forward the explicitly requested language to TMDB."""

    tmdb_client.get_tv_season_details.return_value = season_details

    service.get_episodes(
        tmdb_id=TMDB_ID,
        season_number=SEASON_NUMBER,
        language="pt-PT",
    )

    tmdb_client.get_tv_season_details.assert_called_once_with(
        tmdb_id=TMDB_ID,
        season_number=SEASON_NUMBER,
        language="pt-PT",
    )


def test_get_episodes_allows_unspecified_language(
    service: TMDBSeasonDetailsService,
    tmdb_client: Mock,
    season_details: TMDBSeasonDetails,
) -> None:
    """Allow the TMDB client to choose its default language."""

    tmdb_client.get_tv_season_details.return_value = season_details

    service.get_episodes(
        tmdb_id=TMDB_ID,
        season_number=SEASON_NUMBER,
    )

    tmdb_client.get_tv_season_details.assert_called_once_with(
        tmdb_id=TMDB_ID,
        season_number=SEASON_NUMBER,
        language=None,
    )


def test_get_episodes_maps_tmdb_episodes(
    service: TMDBSeasonDetailsService,
    tmdb_client: Mock,
    season_details: TMDBSeasonDetails,
) -> None:
    """Map TMDB episode metadata to SofaWatch episode summaries."""

    tmdb_client.get_tv_season_details.return_value = season_details

    episodes = service.get_episodes(
        tmdb_id=TMDB_ID,
        season_number=SEASON_NUMBER,
        language="en-US",
    )

    assert len(episodes) == 2

    first_episode = episodes[0]

    assert first_episode.tmdb_id == 2001
    assert first_episode.episode_number == 1
    assert first_episode.title == "Good News About Hell"
    assert first_episode.overview == "Mark starts a new day at Lumon."
    assert first_episode.air_date == date(2022, 2, 18)
    assert first_episode.runtime == 57
    assert first_episode.vote_average == 8.1
    assert first_episode.vote_count == 42
    assert first_episode.still_path == "/episode-1.jpg"

    second_episode = episodes[1]

    assert second_episode.tmdb_id == 2002
    assert second_episode.episode_number == 2
    assert second_episode.title == "Half Loop"


def test_get_episodes_preserves_episode_order(
    service: TMDBSeasonDetailsService,
    tmdb_client: Mock,
    season_details: TMDBSeasonDetails,
) -> None:
    """Preserve the episode ordering returned by TMDB."""

    tmdb_client.get_tv_season_details.return_value = season_details

    episodes = service.get_episodes(
        tmdb_id=TMDB_ID,
        season_number=SEASON_NUMBER,
    )

    assert [episode.episode_number for episode in episodes] == [
        1,
        2,
    ]


def test_get_episodes_returns_empty_list_when_season_has_no_episodes(
    service: TMDBSeasonDetailsService,
    tmdb_client: Mock,
) -> None:
    """Return an empty list when TMDB reports no episodes."""

    season_details = TMDBSeasonDetails(
        id=134792,
        air_date=date(2022, 2, 18),
        name="Season 1",
        overview="The first season.",
        poster_path="/season-1.jpg",
        season_number=1,
        episodes=[],
    )

    tmdb_client.get_tv_season_details.return_value = season_details

    episodes = service.get_episodes(
        tmdb_id=TMDB_ID,
        season_number=SEASON_NUMBER,
    )

    assert episodes == []


def test_get_episodes_maps_optional_metadata(
    service: TMDBSeasonDetailsService,
    tmdb_client: Mock,
) -> None:
    """Map missing optional TMDB episode metadata."""

    season_details = TMDBSeasonDetails(
        id=134792,
        air_date=None,
        name="Season 1",
        overview="",
        poster_path=None,
        season_number=1,
        episodes=[
            TMDBEpisodeSummary(
                id=2001,
                name="Future Episode",
                overview="",
                vote_average=0.0,
                vote_count=0,
                air_date=None,
                episode_number=1,
                episode_type="standard",
                production_code="",
                runtime=None,
                season_number=1,
                show_id=TMDB_ID,
                still_path=None,
            ),
        ],
    )

    tmdb_client.get_tv_season_details.return_value = season_details

    episodes = service.get_episodes(
        tmdb_id=TMDB_ID,
        season_number=SEASON_NUMBER,
    )

    assert len(episodes) == 1

    episode = episodes[0]

    assert episode.tmdb_id == 2001
    assert episode.title == "Future Episode"
    assert episode.overview == ""
    assert episode.air_date is None
    assert episode.runtime is None
    assert episode.vote_average == 0.0
    assert episode.vote_count == 0
    assert episode.still_path is None


def test_get_episodes_supports_specials_season(
    service: TMDBSeasonDetailsService,
    tmdb_client: Mock,
) -> None:
    """Allow season number zero for TV specials."""

    season_details = TMDBSeasonDetails(
        id=1000,
        air_date=None,
        name="Specials",
        overview="Special episodes.",
        poster_path=None,
        season_number=0,
        episodes=[],
    )

    tmdb_client.get_tv_season_details.return_value = season_details

    episodes = service.get_episodes(
        tmdb_id=TMDB_ID,
        season_number=0,
        language="en-US",
    )

    assert episodes == []

    tmdb_client.get_tv_season_details.assert_called_once_with(
        tmdb_id=TMDB_ID,
        season_number=0,
        language="en-US",
    )
