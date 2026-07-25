from types import SimpleNamespace
from unittest.mock import Mock
from uuid import UUID, uuid4

import pytest

from app.models.season import Season
from app.models.show import Show
from app.repositories.season import SeasonRepository
from app.repositories.show import ShowRepository
from app.services.season import SeasonService


@pytest.fixture
def show_id() -> UUID:
    """Provide a local TV series identifier."""

    return uuid4()


@pytest.fixture
def show_repository() -> Mock:
    """Provide a mocked show repository."""

    return Mock(spec=ShowRepository)


@pytest.fixture
def season_repository() -> Mock:
    """Provide a mocked season repository."""

    return Mock(spec=SeasonRepository)


@pytest.fixture
def season_service(
    show_repository: Mock,
    season_repository: Mock,
) -> SeasonService:
    """Provide a season service using mocked repositories."""

    return SeasonService(
        show_repository=show_repository,
        season_repository=season_repository,
    )


def make_show(
    *,
    show_id: UUID,
    tmdb_id: int = 1399,
    title: str = "Game of Thrones",
) -> SimpleNamespace:
    """Create a lightweight TV series object for service tests."""

    return SimpleNamespace(
        id=show_id,
        tmdb_id=tmdb_id,
        title=title,
    )


def make_season(
    *,
    show_id: UUID,
    tmdb_id: int,
    season_number: int,
    title: str,
) -> SimpleNamespace:
    """Create a lightweight TV season object for service tests."""

    return SimpleNamespace(
        id=uuid4(),
        show_id=show_id,
        tmdb_id=tmdb_id,
        season_number=season_number,
        title=title,
    )


def test_list_for_show_returns_none_when_show_does_not_exist(
    show_id: UUID,
    season_service: SeasonService,
    show_repository: Mock,
    season_repository: Mock,
) -> None:
    """Return None when the requested TV series does not exist."""

    show_repository.get_by_id.return_value = None

    result = season_service.list_for_show(show_id)

    assert result is None

    show_repository.get_by_id.assert_called_once_with(show_id)
    season_repository.list_by_show_id.assert_not_called()


def test_list_for_show_returns_empty_list_when_show_has_no_seasons(
    show_id: UUID,
    season_service: SeasonService,
    show_repository: Mock,
    season_repository: Mock,
) -> None:
    """Return an empty list when the TV series has no seasons."""

    show = make_show(show_id=show_id)

    show_repository.get_by_id.return_value = show
    season_repository.list_by_show_id.return_value = []

    result = season_service.list_for_show(show_id)

    assert result == []

    show_repository.get_by_id.assert_called_once_with(show_id)
    season_repository.list_by_show_id.assert_called_once_with(
        show_id,
    )


def test_list_for_show_returns_stored_seasons(
    show_id: UUID,
    season_service: SeasonService,
    show_repository: Mock,
    season_repository: Mock,
) -> None:
    """Return the locally stored seasons belonging to a TV series."""

    show = make_show(show_id=show_id)

    seasons = [
        make_season(
            show_id=show_id,
            tmdb_id=2000,
            season_number=0,
            title="Specials",
        ),
        make_season(
            show_id=show_id,
            tmdb_id=2001,
            season_number=1,
            title="Season 1",
        ),
        make_season(
            show_id=show_id,
            tmdb_id=2002,
            season_number=2,
            title="Season 2",
        ),
    ]

    show_repository.get_by_id.return_value = show
    season_repository.list_by_show_id.return_value = seasons

    result = season_service.list_for_show(show_id)

    assert result == seasons
    assert len(result) == 3
    assert [
        season.season_number
        for season in result
    ] == [
        0,
        1,
        2,
    ]

    show_repository.get_by_id.assert_called_once_with(show_id)
    season_repository.list_by_show_id.assert_called_once_with(
        show_id,
    )


def test_list_for_show_returns_repository_result_without_modifying_it(
    show_id: UUID,
    season_service: SeasonService,
    show_repository: Mock,
    season_repository: Mock,
) -> None:
    """Return the exact collection provided by the repository."""

    show = make_show(show_id=show_id)

    seasons = [
        make_season(
            show_id=show_id,
            tmdb_id=2002,
            season_number=2,
            title="Season 2",
        ),
        make_season(
            show_id=show_id,
            tmdb_id=2001,
            season_number=1,
            title="Season 1",
        ),
    ]

    show_repository.get_by_id.return_value = show
    season_repository.list_by_show_id.return_value = seasons

    result = season_service.list_for_show(show_id)

    assert result is seasons
    assert result[0].season_number == 2
    assert result[1].season_number == 1

def test_get_by_number_returns_season(
    show_id: UUID,
    season_service: SeasonService,
    season_repository: Mock,
) -> None:
    """Return a season identified by its show and season number."""

    season = make_season(
        show_id=show_id,
        tmdb_id=2001,
        season_number=1,
        title="Season 1",
    )

    season_repository.get_by_number.return_value = season

    result = season_service.get_by_number(
        show_id=show_id,
        season_number=1,
    )

    assert result is season
    assert result.show_id == show_id
    assert result.season_number == 1

    season_repository.get_by_number.assert_called_once_with(
        show_id=show_id,
        season_number=1,
    )


def test_get_by_number_returns_specials(
    show_id: UUID,
    season_service: SeasonService,
    season_repository: Mock,
) -> None:
    """Allow season number zero to represent specials."""

    specials = make_season(
        show_id=show_id,
        tmdb_id=2000,
        season_number=0,
        title="Specials",
    )

    season_repository.get_by_number.return_value = specials

    result = season_service.get_by_number(
        show_id=show_id,
        season_number=0,
    )

    assert result is specials
    assert result.season_number == 0
    assert result.title == "Specials"

    season_repository.get_by_number.assert_called_once_with(
        show_id=show_id,
        season_number=0,
    )


def test_get_by_number_returns_none_when_season_does_not_exist(
    show_id: UUID,
    season_service: SeasonService,
    season_repository: Mock,
) -> None:
    """Return None when the requested season does not exist."""

    season_repository.get_by_number.return_value = None

    result = season_service.get_by_number(
        show_id=show_id,
        season_number=5,
    )

    assert result is None

    season_repository.get_by_number.assert_called_once_with(
        show_id=show_id,
        season_number=5,
    )