import json
import logging
from datetime import UTC, datetime
from logging.config import dictConfig
from pathlib import Path
from typing import Literal

from app.core.config import get_settings


LogComponent = Literal[
    "api",
    "worker",
]

_LOG_MAX_BYTES = 5 * 1024 * 1024
_LOG_BACKUP_COUNT = 5


class SafeJsonLogFormatter(logging.Formatter):
    """Write structured log records without exposing exception tracebacks."""

    def format(
        self,
        record: logging.LogRecord,
    ) -> str:
        payload = {
            "timestamp": datetime.fromtimestamp(
                record.created,
                tz=UTC,
            ).isoformat(),
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
        }

        return json.dumps(
            payload,
            ensure_ascii=False,
        )


def configure_logging(
    *,
    component: LogComponent = "api",
) -> None:
    """Configure console and component-specific persistent logging."""

    settings = get_settings()

    log_level = (
        "DEBUG"
        if settings.debug
        else "INFO"
    )

    log_directory = (
        Path(settings.data_storage_path)
        / "logs"
    ).resolve()

    log_directory.mkdir(
        parents=True,
        exist_ok=True,
    )

    log_file = (
        log_directory
        / f"{component}.log"
    )

    logging_config = {
        "version": 1,
        "disable_existing_loggers": False,
        "formatters": {
            "console": {
                "format": (
                    "%(asctime)s | %(levelname)s | "
                    "%(name)s | %(message)s"
                ),
                "datefmt": "%Y-%m-%d %H:%M:%S",
            },
            "file": {
                "()": SafeJsonLogFormatter,
            },
        },
        "handlers": {
            "console": {
                "class": "logging.StreamHandler",
                "formatter": "console",
                "stream": "ext://sys.stdout",
            },
            "file": {
                "class": "logging.handlers.RotatingFileHandler",
                "formatter": "file",
                "filename": str(log_file),
                "maxBytes": _LOG_MAX_BYTES,
                "backupCount": _LOG_BACKUP_COUNT,
                "encoding": "utf-8",
            },
        },
        "root": {
            "level": log_level,
            "handlers": [
                "console",
                "file",
            ],
        },
        "loggers": {
            "uvicorn": {
                "level": log_level,
                "handlers": [
                    "console",
                    "file",
                ],
                "propagate": False,
            },
            "uvicorn.error": {
                "level": log_level,
                "handlers": [
                    "console",
                    "file",
                ],
                "propagate": False,
            },
            "uvicorn.access": {
                "level": log_level,
                "handlers": [
                    "console",
                    "file",
                ],
                "propagate": False,
            },
        },
    }

    dictConfig(
        logging_config,
    )