from datetime import UTC, datetime
from uuid import uuid4

import pytest

from app.services.watch_history_cursor import (
    WatchHistoryCursor,
    WatchHistoryCursorCodec,
)


def test_watch_history_cursor_round_trip() -> None:
    """Encode and decode a Watch History cursor without losing data."""

    cursor = WatchHistoryCursor(
        watched_at=datetime(
            2026,
            8,
            13,
            20,
            30,
            tzinfo=UTC,
        ),
        event_id=uuid4(),
    )

    encoded = WatchHistoryCursorCodec.encode(
        cursor,
    )

    decoded = WatchHistoryCursorCodec.decode(
        encoded,
    )

    assert decoded == cursor


def test_watch_history_cursor_is_opaque() -> None:
    """Do not expose raw cursor fields directly to API consumers."""

    cursor = WatchHistoryCursor(
        watched_at=datetime(
            2026,
            8,
            13,
            20,
            30,
            tzinfo=UTC,
        ),
        event_id=uuid4(),
    )

    encoded = WatchHistoryCursorCodec.encode(
        cursor,
    )

    assert "watched_at" not in encoded
    assert "event_id" not in encoded


@pytest.mark.parametrize(
    "value",
    [
        "",
        "invalid",
        "!!!",
    ],
)
def test_watch_history_cursor_rejects_invalid_values(
    value: str,
) -> None:
    """Reject malformed opaque cursor values."""

    with pytest.raises(
        ValueError,
        match="Invalid Watch History cursor",
    ):
        WatchHistoryCursorCodec.decode(
            value,
        )