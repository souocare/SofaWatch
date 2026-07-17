from pydantic import BaseModel, ConfigDict


class GenreBase(BaseModel):
    """Common genre fields."""

    name: str
    slug: str


class GenreCreate(GenreBase):
    """Schema used when creating a genre."""

    pass


class GenreUpdate(BaseModel):
    """Schema used when updating a genre."""

    name: str | None = None
    slug: str | None = None


class GenreResponse(GenreBase):
    """Genre returned by the API."""

    id: int

    model_config = ConfigDict(
        from_attributes=True,
    )