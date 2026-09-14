from enum import StrEnum


class LibraryStatus(StrEnum):
    """Tracking status of media in a user's library."""

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


class DataImportRunStatus(StrEnum):
    """Execution status of a user data import."""

    QUEUED = "queued"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"


class DataImportPhase(StrEnum):
    """Current processing phase of a user data import."""

    QUEUED = "queued"
    LIBRARY_SHOWS = "library_shows"
    LIBRARY_MOVIES = "library_movies"
    HISTORY_EPISODES = "history_episodes"
    HISTORY_MOVIES = "history_movies"
    FINALIZING = "finalizing"
