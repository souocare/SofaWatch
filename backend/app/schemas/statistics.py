from datetime import date

from pydantic import BaseModel, Field


class WeeklyStatisticsResponse(BaseModel):
    """Viewing summary for one calendar week."""

    week_start: date
    week_end: date

    episodes_watched: int = Field(
        ge=0,
    )

    movies_watched: int = Field(
        ge=0,
    )

    watch_time_minutes: int = Field(
        ge=0,
    )