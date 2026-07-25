from datetime import date, datetime, timedelta, timezone
from types import SimpleNamespace
from unittest.mock import Mock

import pytest
from app.repositories.season import SeasonRepository
from app.models.season import Season
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.config import Settings
from app.models.genre import Genre
from app.models.show import Show
from app.models.show import Show
from app.repositories.genre import GenreRepository
from app.repositories.show import ShowRepository
from app.repositories.show import ShowRepository
from app.services.show_import import ShowImportService
from app.services.tmdb_show_details import TMDBShowDetailsService

TMDB_ID = 95396


@pytest.fixture
def show_details() -> SimpleNamespace:
    """Provide representative TMDB show metadata."""

    return SimpleNamespace(
        tmdb_id=TMDB_ID,
        title="Severance",
        original_title="Severance",
        overview="Employees undergo a severance procedure.",
        tagline="We're all different people at work.",
        first_air_date=date(2022, 2, 18),
        last_air_date=date(2025, 3, 21),
        poster_path="/poster.jpg",
        backdrop_path="/backdrop.jpg",
        homepage_url="https://tv.apple.com/show/severance",
        original_language="en",
        status="Returning Series",
        show_type="Scripted",
        in_production=True,
        number_of_seasons=2,
        number_of_episodes=19,
        episode_run_times=[50],
        popularity=120.5,
        vote_average=8.4,
        vote_count=2100,
        genres=[
            SimpleNamespace(
                tmdb_id=18,
                name="Drama",
            ),
            SimpleNamespace(
                tmdb_id=9648,
                name="Mystery",
            ),
        ],
        seasons=[
            SimpleNamespace(
                tmdb_id=199716,
                season_number=0,
                title="Specials",
                overview="Special episodes.",
                air_date=date(2022, 2, 17),
                episode_count=2,
                vote_average=7.5,
                poster_path="/specials.jpg",
            ),
            SimpleNamespace(
                tmdb_id=134792,
                season_number=1,
                title="Season 1",
                overview="The first season.",
                air_date=date(2022, 2, 18),
                episode_count=9,
                vote_average=8.4,
                poster_path="/season-1.jpg",
            ),
            SimpleNamespace(
                tmdb_id=368201,
                season_number=2,
                title="Season 2",
                overview="The second season.",
                air_date=date(2025, 1, 17),
                episode_count=10,
                vote_average=8.6,
                poster_path="/season-2.jpg",
            ),
        ],
    )


@pytest.fixture
def tmdb_show_details_service(
    show_details: SimpleNamespace,
) -> Mock:
    """Provide a mocked TMDB details service."""

    service = Mock(spec=TMDBShowDetailsService)
    service.get_details.return_value = show_details

    return service


@pytest.fixture
def show_import_service(
    db_session: Session,
    settings: Settings,
    tmdb_show_details_service: Mock,
) -> ShowImportService:
    """Provide a show import service using the test database."""

    return ShowImportService(
        session=db_session,
        settings=settings,
        show_repository=ShowRepository(db_session),
        genre_repository=GenreRepository(db_session),
        season_repository=SeasonRepository(db_session),
        tmdb_show_details_service=tmdb_show_details_service,
    )


def test_import_show_creates_new_show(
    db_session: Session,
    show_import_service: ShowImportService,
    tmdb_show_details_service: Mock,
) -> None:
    """Import a show that does not yet exist locally."""

    show = show_import_service.import_show(
        tmdb_id=TMDB_ID,
    )

    stored_show = db_session.scalar(
        select(Show).where(
            Show.tmdb_id == TMDB_ID,
        )
    )

    assert stored_show is not None
    assert show.id == stored_show.id
    assert show.tmdb_id == TMDB_ID
    assert show.title == "Severance"
    assert show.original_title == "Severance"
    assert show.metadata_language == "en-US"
    assert show.metadata_updated_at is not None

    tmdb_show_details_service.get_details.assert_called_once_with(
        tmdb_id=TMDB_ID,
        language="en-US",
    )


def test_import_show_persists_metadata(
    show_import_service: ShowImportService,
) -> None:
    """Persist the metadata returned by TMDB."""

    show = show_import_service.import_show(
        tmdb_id=TMDB_ID,
    )

    assert show.overview == "Employees undergo a severance procedure."
    assert show.tagline == "We're all different people at work."
    assert show.first_air_date == date(2022, 2, 18)
    assert show.last_air_date == date(2025, 3, 21)

    assert show.tmdb_poster_path == "/poster.jpg"
    assert show.tmdb_backdrop_path == "/backdrop.jpg"

    assert show.homepage_url == "https://tv.apple.com/show/severance"
    assert show.original_language == "en"

    assert show.status == "Returning Series"
    assert show.show_type == "Scripted"
    assert show.in_production is True

    assert show.number_of_seasons == 2
    assert show.number_of_episodes == 19
    assert show.episode_run_time == 50

    assert show.popularity == 120.5
    assert show.vote_average == 8.4
    assert show.vote_count == 2100


def test_import_show_creates_and_associates_genres(
    db_session: Session,
    show_import_service: ShowImportService,
) -> None:
    """Create missing genres and associate them with the show."""

    show = show_import_service.import_show(
        tmdb_id=TMDB_ID,
    )

    genre_count = db_session.scalar(
        select(func.count()).select_from(Genre)
    )

    assert genre_count == 2

    genres_by_tmdb_id = {
        genre.tmdb_id: genre
        for genre in show.genres
    }

    assert set(genres_by_tmdb_id) == {
        18,
        9648,
    }

    assert genres_by_tmdb_id[18].name == "Drama"
    assert genres_by_tmdb_id[18].slug == "drama"

    assert genres_by_tmdb_id[9648].name == "Mystery"
    assert genres_by_tmdb_id[9648].slug == "mystery"


def test_import_show_does_not_create_duplicate(
    db_session: Session,
    show_import_service: ShowImportService,
    tmdb_show_details_service: Mock,
) -> None:
    """Return the existing show instead of creating a duplicate."""

    first_show = show_import_service.import_show(
        tmdb_id=TMDB_ID,
    )

    second_show = show_import_service.import_show(
        tmdb_id=TMDB_ID,
    )

    show_count = db_session.scalar(
        select(func.count()).select_from(Show)
    )

    assert show_count == 1
    assert first_show.id == second_show.id

    tmdb_show_details_service.get_details.assert_called_once_with(
        tmdb_id=TMDB_ID,
        language="en-US",
    )


def test_import_show_returns_recent_show_without_tmdb_request(
    db_session: Session,
    settings: Settings,
    tmdb_show_details_service: Mock,
) -> None:
    """Avoid refreshing recently imported metadata."""

    existing_show = Show(
        tmdb_id=TMDB_ID,
        title="Existing Severance",
        original_title="Severance",
        original_language="en",
        metadata_language="en-US",
        metadata_updated_at=datetime.now(timezone.utc),
    )

    db_session.add(existing_show)
    db_session.commit()
    db_session.refresh(existing_show)

    service = ShowImportService(
        session=db_session,
        settings=settings,
        show_repository=ShowRepository(db_session),
        genre_repository=GenreRepository(db_session),
        tmdb_show_details_service=tmdb_show_details_service,
        season_repository=SeasonRepository(db_session),
    )

    imported_show = service.import_show(
        tmdb_id=TMDB_ID,
    )

    assert imported_show.id == existing_show.id
    assert imported_show.title == "Existing Severance"

    tmdb_show_details_service.get_details.assert_not_called()


def test_import_show_refreshes_old_metadata(
    db_session: Session,
    settings: Settings,
    tmdb_show_details_service: Mock,
) -> None:
    """Refresh a show whose metadata is older than the configured limit."""

    existing_show = Show(
        tmdb_id=TMDB_ID,
        title="Old title",
        original_title="Old title",
        original_language="en",
        metadata_language="en-US",
        metadata_updated_at=(
            datetime.now(timezone.utc)
            - timedelta(days=settings.metadata_refresh_days + 1)
        ),
    )

    db_session.add(existing_show)
    db_session.commit()
    db_session.refresh(existing_show)

    service = ShowImportService(
        session=db_session,
        settings=settings,
        show_repository=ShowRepository(db_session),
        genre_repository=GenreRepository(db_session),
        tmdb_show_details_service=tmdb_show_details_service,
        season_repository=SeasonRepository(db_session),
    )

    imported_show = service.import_show(
        tmdb_id=TMDB_ID,
    )

    assert imported_show.id == existing_show.id
    assert imported_show.title == "Severance"

    tmdb_show_details_service.get_details.assert_called_once_with(
        tmdb_id=TMDB_ID,
        language="en-US",
    )


def test_import_show_force_refreshes_recent_metadata(
    db_session: Session,
    settings: Settings,
    tmdb_show_details_service: Mock,
) -> None:
    """Refresh recent metadata when force_refresh is enabled."""

    existing_show = Show(
        tmdb_id=TMDB_ID,
        title="Existing title",
        original_title="Existing title",
        original_language="en",
        metadata_language="en-US",
        metadata_updated_at=datetime.now(timezone.utc),
    )

    db_session.add(existing_show)
    db_session.commit()
    db_session.refresh(existing_show)

    service = ShowImportService(
        session=db_session,
        settings=settings,
        show_repository=ShowRepository(db_session),
        genre_repository=GenreRepository(db_session),
        tmdb_show_details_service=tmdb_show_details_service,
        season_repository=SeasonRepository(db_session),
    )

    imported_show = service.import_show(
        tmdb_id=TMDB_ID,
        force_refresh=True,
    )

    assert imported_show.id == existing_show.id
    assert imported_show.title == "Severance"

    tmdb_show_details_service.get_details.assert_called_once_with(
        tmdb_id=TMDB_ID,
        language="en-US",
    )


def test_import_show_forwards_selected_language(
    show_import_service: ShowImportService,
    tmdb_show_details_service: Mock,
) -> None:
    """Use the explicitly requested metadata language."""

    show = show_import_service.import_show(
        tmdb_id=TMDB_ID,
        language="pt-PT",
    )

    assert show.metadata_language == "pt-PT"

    tmdb_show_details_service.get_details.assert_called_once_with(
        tmdb_id=TMDB_ID,
        language="pt-PT",
    )


def test_import_show_rolls_back_when_persistence_fails(
    db_session: Session,
    settings: Settings,
    tmdb_show_details_service: Mock,
) -> None:
    """Rollback the transaction when the database operation fails."""

    show_repository = Mock(spec=ShowRepository)
    show_repository.get_by_tmdb_id.return_value = None
    show_repository.add.side_effect = RuntimeError(
        "Database write failed."
    )

    service = ShowImportService(
        session=db_session,
        settings=settings,
        show_repository=show_repository,
        genre_repository=GenreRepository(db_session),
        tmdb_show_details_service=tmdb_show_details_service,
        season_repository=SeasonRepository(db_session),
    )

    with pytest.raises(
        RuntimeError,
        match="Database write failed",
    ):
        service.import_show(
            tmdb_id=TMDB_ID,
        )

    show_count = db_session.scalar(
        select(func.count()).select_from(Show)
    )

    genre_count = db_session.scalar(
        select(func.count()).select_from(Genre)
    )

    assert show_count == 0
    assert genre_count == 0

def test_import_show_creates_seasons(
    db_session: Session,
    show_import_service: ShowImportService,
) -> None:
    """Create and associate the seasons returned by TMDB."""

    show = show_import_service.import_show(
        tmdb_id=TMDB_ID,
    )

    seasons = list(
        db_session.scalars(
            select(Season)
            .where(Season.show_id == show.id)
            .order_by(Season.season_number)
        ).all()
    )

    assert len(seasons) == 3

    assert [
        season.season_number
        for season in seasons
    ] == [
        0,
        1,
        2,
    ]

    assert seasons[0].tmdb_id == 199716
    assert seasons[0].title == "Specials"

    assert seasons[1].tmdb_id == 134792
    assert seasons[1].title == "Season 1"

    assert seasons[2].tmdb_id == 368201
    assert seasons[2].title == "Season 2"

def test_import_show_persists_season_metadata(
    db_session: Session,
    show_import_service: ShowImportService,
) -> None:
    """Persist the season metadata returned by TMDB."""

    show = show_import_service.import_show(
        tmdb_id=TMDB_ID,
    )

    season = db_session.scalar(
        select(Season).where(
            Season.show_id == show.id,
            Season.season_number == 1,
        )
    )

    assert season is not None
    assert season.tmdb_id == 134792
    assert season.title == "Season 1"
    assert season.overview == "The first season."
    assert season.air_date == date(2022, 2, 18)
    assert season.episode_count == 9
    assert season.vote_average == 8.4
    assert season.tmdb_poster_path == "/season-1.jpg"
    assert season.local_poster_path is None

def test_import_show_associates_seasons_with_show(
    show_import_service: ShowImportService,
) -> None:
    """Associate imported seasons with the local TV series."""

    show = show_import_service.import_show(
        tmdb_id=TMDB_ID,
    )

    assert len(show.seasons) == 3

    assert [
        season.season_number
        for season in show.seasons
    ] == [
        0,
        1,
        2,
    ]

    assert all(
        season.show_id == show.id
        for season in show.seasons
    )


def test_import_show_updates_existing_season(
    db_session: Session,
    show_import_service: ShowImportService,
    tmdb_show_details_service: Mock,
    show_details: SimpleNamespace,
) -> None:
    """Update an existing season instead of creating a duplicate."""

    show = show_import_service.import_show(
        tmdb_id=TMDB_ID,
    )

    original_season = db_session.scalar(
        select(Season).where(
            Season.show_id == show.id,
            Season.season_number == 1,
        )
    )

    assert original_season is not None

    original_season_id = original_season.id

    tmdb_show_details_service.reset_mock()

    season_details = show_details.seasons[1]
    season_details.title = "Season One Updated"
    season_details.overview = "Updated season overview."
    season_details.episode_count = 11
    season_details.vote_average = 9.1
    season_details.poster_path = "/updated-season-1.jpg"

    refreshed_show = show_import_service.import_show(
        tmdb_id=TMDB_ID,
        force_refresh=True,
    )

    updated_season = db_session.scalar(
        select(Season).where(
            Season.show_id == refreshed_show.id,
            Season.season_number == 1,
        )
    )

    assert updated_season is not None
    assert updated_season.id == original_season_id
    assert updated_season.title == "Season One Updated"
    assert updated_season.overview == "Updated season overview."
    assert updated_season.episode_count == 11
    assert updated_season.vote_average == 9.1
    assert updated_season.tmdb_poster_path == "/updated-season-1.jpg"

    season_count = db_session.scalar(
        select(func.count())
        .select_from(Season)
        .where(Season.show_id == refreshed_show.id)
    )

    assert season_count == 3


def test_import_show_adds_new_season_during_refresh(
    db_session: Session,
    show_import_service: ShowImportService,
    show_details: SimpleNamespace,
) -> None:
    """Create newly released seasons during a metadata refresh."""

    show = show_import_service.import_show(
        tmdb_id=TMDB_ID,
    )

    show_details.seasons.append(
        SimpleNamespace(
            tmdb_id=500000,
            season_number=3,
            title="Season 3",
            overview="The third season.",
            air_date=date(2027, 1, 1),
            episode_count=10,
            vote_average=0.0,
            poster_path="/season-3.jpg",
        )
    )

    refreshed_show = show_import_service.import_show(
        tmdb_id=TMDB_ID,
        force_refresh=True,
    )

    season = db_session.scalar(
        select(Season).where(
            Season.show_id == refreshed_show.id,
            Season.season_number == 3,
        )
    )

    assert season is not None
    assert season.tmdb_id == 500000
    assert season.title == "Season 3"
    assert season.tmdb_poster_path == "/season-3.jpg"

    season_count = db_session.scalar(
        select(func.count())
        .select_from(Season)
        .where(Season.show_id == refreshed_show.id)
    )

    assert season_count == 4


def test_import_show_keeps_seasons_missing_from_tmdb_response(
    db_session: Session,
    show_import_service: ShowImportService,
    show_details: SimpleNamespace,
) -> None:
    """Keep local seasons that are absent from a later TMDB response."""

    show = show_import_service.import_show(
        tmdb_id=TMDB_ID,
    )

    specials = db_session.scalar(
        select(Season).where(
            Season.show_id == show.id,
            Season.season_number == 0,
        )
    )

    assert specials is not None

    specials_id = specials.id

    show_details.seasons = [
        season
        for season in show_details.seasons
        if season.season_number != 0
    ]

    refreshed_show = show_import_service.import_show(
        tmdb_id=TMDB_ID,
        force_refresh=True,
    )

    preserved_specials = db_session.scalar(
        select(Season).where(
            Season.show_id == refreshed_show.id,
            Season.season_number == 0,
        )
    )

    assert preserved_specials is not None
    assert preserved_specials.id == specials_id
    assert preserved_specials.title == "Specials"

    season_count = db_session.scalar(
        select(func.count())
        .select_from(Season)
        .where(Season.show_id == refreshed_show.id)
    )

    assert season_count == 3


def test_import_show_matches_existing_season_by_number(
    db_session: Session,
    show_import_service: ShowImportService,
    show_details: SimpleNamespace,
) -> None:
    """Use the season number as fallback when the TMDB identifier changes."""

    show = show_import_service.import_show(
        tmdb_id=TMDB_ID,
    )

    season = db_session.scalar(
        select(Season).where(
            Season.show_id == show.id,
            Season.season_number == 1,
        )
    )

    assert season is not None

    original_season_id = season.id

    show_details.seasons[1].tmdb_id = 999001
    show_details.seasons[1].title = "Season 1 With New TMDB ID"

    refreshed_show = show_import_service.import_show(
        tmdb_id=TMDB_ID,
        force_refresh=True,
    )

    updated_season = db_session.scalar(
        select(Season).where(
            Season.show_id == refreshed_show.id,
            Season.season_number == 1,
        )
    )

    assert updated_season is not None
    assert updated_season.id == original_season_id
    assert updated_season.tmdb_id == 999001
    assert updated_season.title == "Season 1 With New TMDB ID"

    matching_seasons = list(
        db_session.scalars(
            select(Season).where(
                Season.show_id == refreshed_show.id,
                Season.season_number == 1,
            )
        ).all()
    )

    assert len(matching_seasons) == 1

def test_import_show_preserves_local_season_poster(
    db_session: Session,
    show_import_service: ShowImportService,
    show_details: SimpleNamespace,
) -> None:
    """Preserve local artwork while refreshing TMDB metadata."""

    show = show_import_service.import_show(
        tmdb_id=TMDB_ID,
    )

    season = db_session.scalar(
        select(Season).where(
            Season.show_id == show.id,
            Season.season_number == 1,
        )
    )

    assert season is not None

    season.local_poster_path = (
        "/media/shows/severance/season-1-poster.jpg"
    )
    db_session.commit()

    show_details.seasons[1].poster_path = (
        "/new-tmdb-season-1.jpg"
    )

    refreshed_show = show_import_service.import_show(
        tmdb_id=TMDB_ID,
        force_refresh=True,
    )

    updated_season = db_session.scalar(
        select(Season).where(
            Season.show_id == refreshed_show.id,
            Season.season_number == 1,
        )
    )

    assert updated_season is not None
    assert (
        updated_season.tmdb_poster_path
        == "/new-tmdb-season-1.jpg"
    )
    assert (
        updated_season.local_poster_path
        == "/media/shows/severance/season-1-poster.jpg"
    )


def test_import_show_does_not_duplicate_seasons(
    db_session: Session,
    show_import_service: ShowImportService,
) -> None:
    """Avoid duplicating seasons during repeated imports."""

    first_show = show_import_service.import_show(
        tmdb_id=TMDB_ID,
    )

    second_show = show_import_service.import_show(
        tmdb_id=TMDB_ID,
        force_refresh=True,
    )

    season_count = db_session.scalar(
        select(func.count())
        .select_from(Season)
        .where(Season.show_id == second_show.id)
    )

    assert first_show.id == second_show.id
    assert season_count == 3