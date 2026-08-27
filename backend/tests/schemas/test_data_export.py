import pytest
from pydantic import ValidationError

from app.schemas.data_export import SofaWatchExportResponse


def test_export_schema_rejects_unknown_format() -> None:
    """Reject files that are not SofaWatch exports."""

    with pytest.raises(ValidationError):
        SofaWatchExportResponse.model_validate(
            {
                "format": "other-export",
                "version": 1,
                "exported_at": "2026-08-20T15:30:00Z",
                "user": {
                    "display_name": "Gonçalo",
                },
                "library": {
                    "shows": [],
                    "movies": [],
                },
                "history": {
                    "episodes": [],
                    "movies": [],
                },
            }
        )


def test_export_schema_rejects_unsupported_version() -> None:
    """Reject SofaWatch export versions not supported by this release."""

    with pytest.raises(ValidationError):
        SofaWatchExportResponse.model_validate(
            {
                "format": "sofawatch-export",
                "version": 2,
                "exported_at": "2026-08-20T15:30:00Z",
                "user": {
                    "display_name": "Gonçalo",
                },
                "library": {
                    "shows": [],
                    "movies": [],
                },
                "history": {
                    "episodes": [],
                    "movies": [],
                },
            }
        )
