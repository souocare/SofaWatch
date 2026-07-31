"""Schemas for standardized API error responses."""

from typing import Any

from pydantic import BaseModel


class APIErrorDetail(BaseModel):
    """Describe one specific API error detail."""

    field: str | None = None
    message: str
    context: dict[str, Any] | None = None


class APIErrorBody(BaseModel):
    """Describe the contents of an API error."""

    code: str
    message: str
    details: list[APIErrorDetail] | None = None


class APIErrorResponse(BaseModel):
    """Standard error response returned by the API."""

    error: APIErrorBody