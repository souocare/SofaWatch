from datetime import UTC, datetime, timedelta, date


INACTIVITY_THRESHOLD_DAYS = 60


def as_utc(value: datetime) -> datetime:
    """Return a datetime normalized to UTC."""

    if value.tzinfo is None:
        return value.replace(tzinfo=UTC)

    return value.astimezone(UTC)


def is_stale_watching(
    watched_at: datetime,
    *,
    now: datetime,
) -> bool:
    """Return whether watched activity is beyond the inactivity threshold."""

    threshold = as_utc(now) - timedelta(
        days=INACTIVITY_THRESHOLD_DAYS,
    )

    return as_utc(watched_at) <= threshold

def is_stale_pending_episode(
    air_date: date | None,
    *,
    now: datetime,
) -> bool:
    """Return whether an unwatched Episode has been available long enough."""

    if air_date is None:
        return False

    threshold_date = (
        as_utc(now) - timedelta(days=INACTIVITY_THRESHOLD_DAYS)
    ).date()

    return air_date <= threshold_date


def belongs_to_stale_watching(
    *,
    watched_at: datetime,
    next_episode_air_date: date | None,
    now: datetime,
) -> bool:
    """Return whether a Show belongs in Haven't Watched in a While."""

    return is_stale_watching(
        watched_at,
        now=now,
    ) and is_stale_pending_episode(
        next_episode_air_date,
        now=now,
    )