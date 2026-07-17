from pydantic import BaseModel, ConfigDict


class GenreResponse(BaseModel):
    """Genre returned by the API."""

    id: int
    name: str
    slug: str

    model_config = ConfigDict(
        from_attributes=True,
    )