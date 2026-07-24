from enum import StrEnum

from fastapi import Query
from pydantic import BaseModel, Field

from typing import Annotated

from fastapi import Depends


class ShowSortField(StrEnum):
    """Supported fields for sorting TV series."""

    TITLE = "title"
    FIRST_AIR_DATE = "first_air_date"
    VOTE_AVERAGE = "vote_average"
    POPULARITY = "popularity"
    CREATED_AT = "created_at"
    UPDATED_AT = "updated_at"


class SortDirection(StrEnum):
    """Supported sort directions."""

    ASC = "asc"
    DESC = "desc"


class ShowStatus(StrEnum):
    RETURNING_SERIES = "Returning Series"
    ENDED = "Ended"
    CANCELED = "Canceled"
    IN_PRODUCTION = "In Production"
    PLANNED = "Planned"
    PILOT = "Pilot"

class ShowListParams(BaseModel):
    """Query parameters for listing TV series."""

    offset: int = 0
    limit: int = 50

    sort_by: ShowSortField = ShowSortField.TITLE
    sort_direction: SortDirection = SortDirection.ASC
    query: str | None = None
    genre: str | None = None
    status: ShowStatus | None = None


def get_show_list_params(
    offset: Annotated[
        int,
        Query(
            ge=0,
            description="Number of shows to skip.",
        ),
    ] = 0,
    limit: Annotated[
        int,
        Query(
            ge=1,
            le=100,
            description="Maximum number of shows to return.",
        ),
    ] = 50,
    sort_by: Annotated[
        ShowSortField,
        Query(
            description="Field used to sort the results.",
        ),
    ] = ShowSortField.TITLE,

    sort_direction: Annotated[
        SortDirection,
        Query(
            description="Sorting direction.",
        ),
    ] = SortDirection.ASC,
    query: Annotated[
        str | None,
        Query(
            min_length=1,
            description="Search by TV series title.",
        ),
    ] = None,
    genre: Annotated[
        str | None,
        Query(
            min_length=1,
            description="Filter TV series by genre slug.",
        ),
    ] = None,
    status: Annotated[
        ShowStatus | None,
        Query(
            description="Filter TV series by status.",
        ),
    ] = None,
) -> ShowListParams:
    """Return validated query parameters for listing TV series."""

    return ShowListParams(
        offset=offset,
        limit=limit,
        sort_by=sort_by,
        sort_direction=sort_direction,
        query=query,
        genre=genre,
        status=status,
    )