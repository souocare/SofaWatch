from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field

from app.models.enums import BackgroundJobStatus


class BackgroundJobResultSummaryResponse(BaseModel):
    """Summary metrics from the latest background job execution."""

    checked: int = Field(
        ge=0,
    )
    refreshed: int = Field(
        ge=0,
    )
    skipped: int = Field(
        ge=0,
    )
    failed: int = Field(
        ge=0,
    )

class BackgroundJobResponse(BaseModel):
    """Current state of a background job."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    key: str
    name: str
    schedule: str
    status: BackgroundJobStatus

    last_started_at: datetime | None
    last_finished_at: datetime | None
    last_duration_ms: int | None
    last_error: str | None
    next_run_at: datetime | None
    last_result: BackgroundJobResultSummaryResponse | None = None


class BackgroundJobRunResponse(BaseModel):
    """Execution history entry for a background job."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    job_id: UUID
    status: BackgroundJobStatus

    started_at: datetime
    finished_at: datetime | None
    duration_ms: int | None
    error: str | None
    result: dict[str, object] | None


class BackgroundJobRunNowResponse(BaseModel):
    """Accepted manual background job execution."""

    job: BackgroundJobResponse
