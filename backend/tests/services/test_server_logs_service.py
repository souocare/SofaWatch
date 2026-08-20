import json
from pathlib import Path

from pydantic import SecretStr

from app.core.config import Settings
from app.services.server_logs import ServerLogsService


def make_settings(
    tmp_path: Path,
) -> Settings:
    """Create Server Logs test settings."""

    return Settings.model_construct(
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


def write_log(
    path: Path,
    *,
    timestamp: str,
    level: str = "INFO",
    logger: str = "app.test",
    message: str = "Test message.",
) -> None:
    """Append one structured log entry."""

    path.parent.mkdir(
        parents=True,
        exist_ok=True,
    )

    with path.open(
        "a",
        encoding="utf-8",
    ) as handle:
        handle.write(
            json.dumps(
                {
                    "timestamp": timestamp,
                    "level": level,
                    "logger": logger,
                    "message": message,
                }
            )
        )

        handle.write(
            "\n",
        )


def test_list_logs_returns_api_and_worker_logs_newest_first(
    tmp_path: Path,
) -> None:
    """Aggregate process logs ordered from newest to oldest."""

    write_log(
        tmp_path / "logs" / "api.log",
        timestamp="2026-08-20T10:00:00+00:00",
        message="API message.",
    )

    write_log(
        tmp_path / "logs" / "worker.log",
        timestamp="2026-08-20T12:00:00+00:00",
        message="Worker message.",
    )

    service = ServerLogsService(
        settings=make_settings(
            tmp_path,
        ),
    )

    result = service.list_logs()

    assert result.total == 2
    assert result.has_next is False

    assert [
        item.message
        for item in result.items
    ] == [
        "Worker message.",
        "API message.",
    ]

    assert result.items[0].component == "worker"
    assert result.items[1].component == "api"


def test_list_logs_filters_by_level(
    tmp_path: Path,
) -> None:
    """Filter entries by exact log level."""

    log_file = (
        tmp_path
        / "logs"
        / "api.log"
    )

    write_log(
        log_file,
        timestamp="2026-08-20T10:00:00Z",
        level="INFO",
    )

    write_log(
        log_file,
        timestamp="2026-08-20T11:00:00Z",
        level="ERROR",
        message="Failure.",
    )

    service = ServerLogsService(
        settings=make_settings(
            tmp_path,
        ),
    )

    result = service.list_logs(
        level="ERROR",
    )

    assert result.total == 1
    assert result.items[0].level == "ERROR"
    assert result.items[0].message == "Failure."


def test_list_logs_applies_offset_and_limit(
    tmp_path: Path,
) -> None:
    """Paginate Server logs."""

    log_file = (
        tmp_path
        / "logs"
        / "api.log"
    )

    for index in range(5):
        write_log(
            log_file,
            timestamp=(
                f"2026-08-20T10:0{index}:00Z"
            ),
            message=f"Message {index}.",
        )

    service = ServerLogsService(
        settings=make_settings(
            tmp_path,
        ),
    )

    result = service.list_logs(
        offset=1,
        limit=2,
    )

    assert result.offset == 1
    assert result.limit == 2
    assert result.total == 5
    assert result.has_next is True

    assert [
        item.message
        for item in result.items
    ] == [
        "Message 3.",
        "Message 2.",
    ]


def test_list_logs_includes_rotated_files(
    tmp_path: Path,
) -> None:
    """Read active and rotated process log files."""

    write_log(
        tmp_path / "logs" / "api.log.1",
        timestamp="2026-08-19T10:00:00Z",
        message="Rotated.",
    )

    write_log(
        tmp_path / "logs" / "api.log",
        timestamp="2026-08-20T10:00:00Z",
        message="Current.",
    )

    service = ServerLogsService(
        settings=make_settings(
            tmp_path,
        ),
    )

    result = service.list_logs()

    assert result.total == 2

    assert [
        item.message
        for item in result.items
    ] == [
        "Current.",
        "Rotated.",
    ]


def test_list_logs_ignores_invalid_lines(
    tmp_path: Path,
) -> None:
    """Ignore malformed persisted log entries."""

    log_file = (
        tmp_path
        / "logs"
        / "api.log"
    )

    log_file.parent.mkdir(
        parents=True,
        exist_ok=True,
    )

    log_file.write_text(
        "not-json\n",
        encoding="utf-8",
    )

    write_log(
        log_file,
        timestamp="2026-08-20T10:00:00Z",
        message="Valid.",
    )

    service = ServerLogsService(
        settings=make_settings(
            tmp_path,
        ),
    )

    result = service.list_logs()

    assert result.total == 1
    assert result.items[0].message == "Valid."


def test_list_logs_redacts_common_secret_values(
    tmp_path: Path,
) -> None:
    """Do not expose common credential values through Server Logs."""

    write_log(
        tmp_path / "logs" / "api.log",
        timestamp="2026-08-20T10:00:00Z",
        level="ERROR",
        message=(
            "Request failed token=super-secret-value "
            "password=hunter2"
        ),
    )

    service = ServerLogsService(
        settings=make_settings(
            tmp_path,
        ),
    )

    result = service.list_logs()

    message = result.items[0].message

    assert "super-secret-value" not in message
    assert "hunter2" not in message

    assert "token=[REDACTED]" in message
    assert "password=[REDACTED]" in message