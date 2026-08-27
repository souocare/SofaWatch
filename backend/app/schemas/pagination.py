from pydantic import BaseModel, Field


class PaginatedResponse[T](BaseModel):
    """Paginated API response."""

    items: list[T] = Field(default_factory=list)

    total: int = Field(ge=0)

    offset: int = Field(ge=0)
    limit: int = Field(gt=0)

    has_next: bool
