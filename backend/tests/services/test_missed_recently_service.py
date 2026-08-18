
from datetime import date
from uuid import uuid4

from app.models.enums import LibraryStatus
from app.repositories.episode_progress import MissedRecentlyEpisode
from app.services.missed_recently import MissedRecentlyService


class FakeEpisode:
    def __init__(
        self,
        *,
        air_date: date,
    ) -> None:
        self.id = uuid4()
        self.tmdb_id = 300001
        self.episode_number = 3
        self.title = "Who Is Alive?"
        self.air_date = air_date
        self.runtime = 52
        self.still_url = None


class FakeShow:
    def __init__(self) -> None:
        self.id = uuid4()
        self.tmdb_id = 95396
        self.title = "Severance"
        self.original_title = "Severance"
        self.first_air_date = date(2022, 2, 18)
        self.tmdb_poster_path = None
        self.local_poster_path = None
        self.poster_url = None
        self.backdrop_url = None
        self.status = "Returning Series"
        self.vote_average = 8.4


class FakeEpisodeProgressRepository:
    def __init__(
        self,
        *,
        result: list[MissedRecentlyEpisode] | None = None,
    ) -> None:
        self.result = result or []

        self.requested_user_id = None
        self.requested_from_date = None
        self.requested_to_date = None
        self.requested_limit = None

    def list_missed_recently(
        self,
        *,
        user_id,
        from_date,
        to_date,
        limit,
    ):
        self.requested_user_id = user_id
        self.requested_from_date = from_date
        self.requested_to_date = to_date
        self.requested_limit = limit

        return self.result


def test_list_for_user_requests_previous_fourteen_days() -> None:
    repository = FakeEpisodeProgressRepository()

    service = MissedRecentlyService(
        progress_repository=repository,
    )

    user_id = uuid4()

    result = service.list_for_user(
        user_id=user_id,
        reference_date=date(2026, 8, 18),
    )

    assert result == []

    assert repository.requested_user_id == user_id
    assert repository.requested_from_date == date(2026, 8, 4)
    assert repository.requested_to_date == date(2026, 8, 17)
    assert repository.requested_limit == 10


def test_list_for_user_maps_repository_result() -> None:
    show = FakeShow()

    episode = FakeEpisode(
        air_date=date(2026, 8, 17),
    )

    repository = FakeEpisodeProgressRepository(
        result=[
            MissedRecentlyEpisode(
                library_entry_id=uuid4(),
                library_status=LibraryStatus.WATCHING,
                show=show,
                episode=episode,
                season_number=2,
            ),
        ],
    )

    service = MissedRecentlyService(
        progress_repository=repository,
    )

    result = service.list_for_user(
        user_id=uuid4(),
        reference_date=date(2026, 8, 18),
    )

    assert len(result) == 1

    item = result[0]

    assert item.library_status == LibraryStatus.WATCHING

    assert item.show.id == show.id
    assert item.show.tmdb_id == 95396
    assert item.show.title == "Severance"

    assert item.episode.id == episode.id
    assert item.episode.season_number == 2
    assert item.episode.episode_number == 3
    assert item.episode.title == "Who Is Alive?"
    assert item.episode.air_date == date(2026, 8, 17)
    assert item.episode.is_watched is False


def test_list_for_user_uses_explicit_home_limit() -> None:
    repository = FakeEpisodeProgressRepository()

    service = MissedRecentlyService(
        progress_repository=repository,
    )

    service.list_for_user(
        user_id=uuid4(),
        reference_date=date(2026, 8, 18),
    )

    assert repository.requested_limit == MissedRecentlyService.DEFAULT_LIMIT
    assert MissedRecentlyService.DEFAULT_LIMIT == 10
