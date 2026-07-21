from logging.config import dictConfig

from app.core.config import get_settings


def configure_logging() -> None:
    settings = get_settings()

    log_level = "DEBUG" if settings.debug else "INFO"

    logging_config = {
        "version": 1,
        "disable_existing_loggers": False,
        "formatters": {
            "default": {
                "format": "%(asctime)s | %(levelname)s | %(name)s | %(message)s",
                "datefmt": "%Y-%m-%d %H:%M:%S",
            },
        },
        "handlers": {
            "default": {
                "class": "logging.StreamHandler",
                "formatter": "default",
                "stream": "ext://sys.stdout",
            },
        },
        "root": {
            "level": log_level,
            "handlers": ["default"],
        },
        "loggers": {
            "uvicorn": {
                "level": log_level,
                "handlers": ["default"],
                "propagate": False,
            },
            "uvicorn.error": {
                "level": log_level,
                "handlers": ["default"],
                "propagate": False,
            },
            "uvicorn.access": {
                "level": log_level,
                "handlers": ["default"],
                "propagate": False,
            },
        },
    }

    dictConfig(logging_config)
