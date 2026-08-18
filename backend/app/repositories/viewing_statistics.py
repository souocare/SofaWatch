from dataclasses import dataclass


@dataclass(frozen=True, slots=True)
class DailyViewingStatistics:
    """Viewing statistics aggregated for one calendar day."""

    day: str
    watch_count: int
    watch_time_minutes: int