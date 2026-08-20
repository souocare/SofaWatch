import json
import logging
from pathlib import Path
from unittest.mock import patch

from pydantic import SecretStr

from app.core.config import Settings
from app.core.logging_config import (
    SafeJsonLogFormatter,
    configure_logging,
)


def test_safe_json_log_formatter_serializes_supported_fields() -> None:
    """Serialize the safe subset exposed through Server Logs."""

    formatter = SafeJsonLogFormatter()

    record = logging.LogRecord(
        name="app.jobs.executor",
        level=logging.INFO,
        pathname=__file__,
        lineno=1,
        msg="Background job '%s' completed.",
        args=("metadata_sync",),
        exc_info=None,
    )

    payload = json.loads(
        formatter.format(
            record,
        )
    )

    assert payload["level"] == "INFO"
    assert payload["logger"] == "app.jobs.executor"
    assert payload["message"] == (
        "Background job 'metadata_sync' completed."
    )

    assert isinstance(
        payload["timestamp"],
        str,
    )


def test_safe_json_log_formatter_does_not_include_exception_traceback() -> None:
    """Do not expose exception traceback data in persistent structured logs."""

    formatter = SafeJsonLogFormatter()

    try:
        raise RuntimeError(
            "Expected failure.",
        )
    except RuntimeError:
        import sys

        exception_info = sys.exc_info()

    record = logging.LogRecord(
        name="app.jobs.executor",
        level=logging.ERROR,
        pathname=__file__,
        lineno=1,
        msg="Background job failed.",
        args=(),
        exc_info=exception_info,
    )

    payload = json.loads(
        formatter.format(
            record,
        )
    )

    assert payload == {
        "timestamp": payload["timestamp"],
        "level": "ERROR",
        "logger": "app.jobs.executor",
        "message": "Background job failed.",
    }


def test_configure_logging_creates_component_log_file(
    tmp_path: Path,
) -> None:
    """Create a dedicated persistent log file for each process component."""

    settings = Settings.model_construct(
        app_name="SofaWatch Test",
        environment="test",
        debug=False,
        api_host="127.0.0.1",
        api_port=8000,
        database_url="sqlite://",
        data_storage_path=str(
            tmp_path,
        ),
        image_storage_path=str(
            tmp_path / "images",
        ),
        secret_key=SecretStr(
            "test-secret-key",
        ),
        default_language="en-US",
        supported_languages="en-US,pt-PT",
        tmdb_api_token=None,
        tmdb_base_url="https://api.themoviedb.org/3",
        tmdb_image_base_url="https://image.tmdb.org/t/p",
        tmdb_timeout_seconds=10.0,
        tvdb_api_key=None,
        tvdb_pin=None,
        tvdb_base_url="https://api4.thetvdb.com/v4",
        metadata_refresh_days=7,
        cors_origins="",
    )

    with patch(
        "app.core.logging_config.get_settings",
        return_value=settings,
    ):
        configure_logging(
            component="api",
        )

    logging.getLogger(
        "test.logging",
    ).info(
        "Persistent test message.",
    )

    logging.shutdown()

    log_file = (
        tmp_path
        / "logs"
        / "api.log"
    )

    assert log_file.is_file()

    lines = log_file.read_text(
        encoding="utf-8",
    ).splitlines()

    payload = json.loads(
        lines[-1],
    )

    assert payload["level"] == "INFO"
    assert payload["logger"] == "test.logging"
    assert payload["message"] == (
        "Persistent test message."
    )