from logging.config import dictConfig
from typing import Literal

from app.core.config import get_settings

LogComponent = Literal[
    "api",
    "worker",
]


def configure_logging(
    *,
    component: LogComponent = "api",
) -> None:
    """Configure SofaWatch logging for the current process."""

    del component

    settings = get_settings()

    log_level = "DEBUG" if settings.debug else "INFO"

    logging_config = {
        "version": 1,
        "disable_existing_loggers": False,
        "formatters": {
            "console": {
                "format": ("%(asctime)s | %(levelname)s | %(name)s | %(message)s"),
                "datefmt": "%Y-%m-%d %H:%M:%S",
            },
        },
        "handlers": {
            "console": {
                "class": "logging.StreamHandler",
                "formatter": "console",
                "stream": "ext://sys.stdout",
            },
        },
        "root": {
            "level": log_level,
            "handlers": ["console"],
        },
        "loggers": {
            "uvicorn": {
                "level": log_level,
                "handlers": ["console"],
                "propagate": False,
            },
            "uvicorn.error": {
                "level": log_level,
                "handlers": ["console"],
                "propagate": False,
            },
            "uvicorn.access": {
                "level": log_level,
                "handlers": ["console"],
                "propagate": False,
            },
        },
    }

    dictConfig(logging_config)
