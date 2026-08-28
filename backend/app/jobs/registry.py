from collections.abc import Callable, Mapping
from dataclasses import dataclass
from datetime import timedelta
from types import MappingProxyType

from app.jobs.metadata_sync import (
    run_metadata_force_sync,
    run_metadata_sync,
)

JobResult = dict[str, object]
JobCallable = Callable[[], JobResult | None]


@dataclass(frozen=True, slots=True)
class BackgroundJobDefinition:
    """Static definition of a background job."""

    key: str
    name: str
    schedule_label: str
    interval: timedelta
    handler: JobCallable
    force_handler: JobCallable | None = None


_JOB_DEFINITIONS = {
    "metadata_sync": BackgroundJobDefinition(
        key="metadata_sync",
        name="Metadata sync",
        schedule_label="Every 8h",
        interval=timedelta(hours=8),
        handler=run_metadata_sync,
        force_handler=run_metadata_force_sync,
    ),
}


BACKGROUND_JOBS: Mapping[
    str,
    BackgroundJobDefinition,
] = MappingProxyType(_JOB_DEFINITIONS)


def get_background_job(
    key: str,
) -> BackgroundJobDefinition | None:
    """Return a registered background job definition."""

    return BACKGROUND_JOBS.get(key)