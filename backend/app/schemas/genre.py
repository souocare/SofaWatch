from pydantic import BaseModel, ConfigDict, Field


class GenreBase(BaseModel):
    """Common genre fields."""

    name: str = Field(
        min_length=1,
        max_length=100,
    )
    slug: str = Field(
        min_length=1,
        max_length=100,
        pattern=r"^[a-z0-9]+(?:-[a-z0-9]+)*$",
    )


class GenreCreate(GenreBase):
    """Data required to create a genre."""


class GenreUpdate(BaseModel):
    """Data accepted when updating a genre."""

    name: str | None = Field(
        default=None,
        min_length=1,
        max_length=100,
    )
    slug: str | None = Field(
        default=None,
        min_length=1,
        max_length=100,
        pattern=r"^[a-z0-9]+(?:-[a-z0-9]+)*$",
    )


class GenreResponse(GenreBase):
    """Genre returned by the API."""

    id: int

    model_config = ConfigDict(
        from_attributes=True,
    )
