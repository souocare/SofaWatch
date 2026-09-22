import pytest

from app.services.show_lifecycle import is_terminal_show_status


@pytest.mark.parametrize(
    "status",
    [
        "Ended",
        "ended",
        " ENDED ",
        "Canceled",
        "canceled",
        "Cancelled",
        "cancelled",
        " CANCELLED ",
    ],
)
def test_is_terminal_show_status_accepts_terminal_variants(status: str) -> None:
    assert is_terminal_show_status(status) is True


@pytest.mark.parametrize(
    "status",
    [
        None,
        "",
        " ",
        "Returning Series",
        "In Production",
        "Planned",
        "Pilot",
    ],
)
def test_is_terminal_show_status_rejects_non_terminal_statuses(
    status: str | None,
) -> None:
    assert is_terminal_show_status(status) is False
