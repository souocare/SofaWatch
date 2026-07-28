from enum import StrEnum


class LibraryStatus(StrEnum):
    """Tracking status of a TV series in a user's library."""

    PLANNING = "planning"
    WATCHING = "watching"
    COMPLETED = "completed"
    PAUSED = "paused"
    DROPPED = "dropped"


class BackgroundJobStatus(StrEnum):
    """Execution status of a background job."""

    IDLE = "idle"
    RUNNING = "running"
    SUCCESS = "success"
    FAILED = "failed"