"""Shared lifecycle semantics for TV series metadata."""

_TERMINAL_SHOW_STATUSES = frozenset(
    {
        "ended",
        "canceled",
        "cancelled",
    }
)


def is_terminal_show_status(status: str | None) -> bool:
    """Return whether a provider Show status represents a terminal lifecycle."""

    if status is None:
        return False

    return status.strip().lower() in _TERMINAL_SHOW_STATUSES
