from datetime import UTC, date, datetime, timedelta

from app.services.watch_list_rules import (
    belongs_to_stale_watching,
    is_stale_watching,
)


def test_activity_at_inactivity_threshold_is_stale() -> None:
    """Activity exactly at the threshold is considered stale."""

    now = datetime(
        2026,
        8,
        14,
        20,
        0,
        tzinfo=UTC,
    )

    assert is_stale_watching(
        now - timedelta(days=60),
        now=now,
    )


def test_activity_older_than_inactivity_threshold_is_stale() -> None:
    """Activity older than the threshold is considered stale."""

    now = datetime(
        2026,
        8,
        14,
        20,
        0,
        tzinfo=UTC,
    )

    assert is_stale_watching(
        now - timedelta(days=61),
        now=now,
    )


def test_recent_activity_is_not_stale() -> None:
    """Activity inside the threshold is not stale."""

    now = datetime(
        2026,
        8,
        14,
        20,
        0,
        tzinfo=UTC,
    )

    assert not is_stale_watching(
        now - timedelta(days=59),
        now=now,
    )


def test_naive_watched_at_is_interpreted_as_utc() -> None:
    """Normalize legacy naive timestamps consistently as UTC."""

    now = datetime(
        2026,
        8,
        14,
        20,
        0,
        tzinfo=UTC,
    )

    watched_at = datetime(
        2026,
        6,
        15,
        20,
        0,
    )

    assert is_stale_watching(
        watched_at,
        now=now,
    )

def test_recent_pending_episode_does_not_belong_to_stale_watching() -> None:
    """Old viewing activity alone must not make newly available content stale."""

    now = datetime(
        2026,
        8,
        14,
        20,
        0,
        tzinfo=UTC,
    )

    assert not belongs_to_stale_watching(
        watched_at=now - timedelta(days=100),
        next_episode_air_date=date(2026, 8, 14),
        now=now,
    )


def test_old_activity_and_old_pending_episode_belong_to_stale_watching() -> None:
    """A Show is stale when both activity and pending content are old."""

    now = datetime(
        2026,
        8,
        14,
        20,
        0,
        tzinfo=UTC,
    )

    assert belongs_to_stale_watching(
        watched_at=now - timedelta(days=100),
        next_episode_air_date=date(2026, 6, 1),
        now=now,
    )


def test_recent_activity_does_not_belong_to_stale_watching() -> None:
    """Recently resumed Shows remain in Watch Next even with old Episodes."""

    now = datetime(
        2026,
        8,
        14,
        20,
        0,
        tzinfo=UTC,
    )

    assert not belongs_to_stale_watching(
        watched_at=now - timedelta(days=10),
        next_episode_air_date=date(2025, 1, 1),
        now=now,
    )


def test_unknown_pending_episode_air_date_is_not_stale() -> None:
    """Unknown Episode dates must not force a Show into stale Watching."""

    now = datetime(
        2026,
        8,
        14,
        20,
        0,
        tzinfo=UTC,
    )

    assert not belongs_to_stale_watching(
        watched_at=now - timedelta(days=100),
        next_episode_air_date=None,
        now=now,
    )