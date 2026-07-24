# app/schemas/pagination.py

from typing import Generic, TypeVar

from pydantic import BaseModel, Field
from pydantic.generics import GenericModel

T = TypeVar("T")


class PaginatedResponse(GenericModel, Generic[T]):
    """Paginated API response."""

    items: list[T] = Field(default_factory=list)

    total: int = Field(ge=0)

    offset: int = Field(ge=0)
    limit: int = Field(gt=0)

    has_next: bool