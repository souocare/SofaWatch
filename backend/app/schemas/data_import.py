from pydantic import BaseModel, Field


class DataImportPreviewSummaryResponse(BaseModel):
    """Summary of data contained in a SofaWatch import file."""

    library_shows: int = Field(
        ge=0,
    )

    library_movies: int = Field(
        ge=0,
    )

    episode_watch_events: int = Field(
        ge=0,
    )

    movie_watch_events: int = Field(
        ge=0,
    )


class DataImportPreviewResponse(BaseModel):
    """Validated preview of a SofaWatch data import."""

    format: str
    version: int

    user_display_name: str

    summary: DataImportPreviewSummaryResponse


class DataImportMediaSummaryResponse(BaseModel):
    """Summary of one media type imported into the Library."""

    created: int = Field(ge=0)
    updated: int = Field(ge=0)
    unchanged: int = Field(ge=0)
    failed: int = Field(ge=0)


class DataImportLibraryResultResponse(BaseModel):
    """Result of importing portable Library data."""

    shows: DataImportMediaSummaryResponse
    movies: DataImportMediaSummaryResponse


class DataImportHistoryMediaSummaryResponse(BaseModel):
    """Summary of historical viewing events imported for one media type."""

    created: int = Field(ge=0)
    skipped: int = Field(ge=0)
    failed: int = Field(ge=0)


class DataImportHistoryResultResponse(BaseModel):
    """Result of importing portable viewing History."""

    episodes: DataImportHistoryMediaSummaryResponse
    movies: DataImportHistoryMediaSummaryResponse


class DataImportResultResponse(BaseModel):
    """Final result of importing portable SofaWatch user data."""

    library: DataImportLibraryResultResponse
    history: DataImportHistoryResultResponse
