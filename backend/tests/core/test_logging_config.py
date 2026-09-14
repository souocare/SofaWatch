from types import SimpleNamespace
from unittest.mock import Mock, patch

from app.core.logging_config import configure_logging


def test_configure_logging_uses_console_only() -> None:
    """Configure application logging without persistent log files."""

    settings = SimpleNamespace(
        debug=False,
    )

    dict_config = Mock()

    with (
        patch(
            "app.core.logging_config.get_settings",
            return_value=settings,
        ),
        patch(
            "app.core.logging_config.dictConfig",
            dict_config,
        ),
    ):
        configure_logging(component="api")

    dict_config.assert_called_once()

    config = dict_config.call_args.args[0]

    assert set(config["handlers"]) == {"console"}
    assert config["root"]["handlers"] == ["console"]

    assert config["loggers"]["uvicorn"]["handlers"] == ["console"]
    assert config["loggers"]["uvicorn.error"]["handlers"] == ["console"]
    assert config["loggers"]["uvicorn.access"]["handlers"] == ["console"]


def test_configure_logging_uses_info_level_by_default() -> None:
    """Use INFO logging outside debug mode."""

    settings = SimpleNamespace(
        debug=False,
    )

    dict_config = Mock()

    with (
        patch(
            "app.core.logging_config.get_settings",
            return_value=settings,
        ),
        patch(
            "app.core.logging_config.dictConfig",
            dict_config,
        ),
    ):
        configure_logging(component="worker")

    config = dict_config.call_args.args[0]

    assert config["root"]["level"] == "INFO"
    assert config["loggers"]["uvicorn"]["level"] == "INFO"


def test_configure_logging_uses_debug_level_in_debug_mode() -> None:
    """Use DEBUG logging when SofaWatch debug mode is enabled."""

    settings = SimpleNamespace(
        debug=True,
    )

    dict_config = Mock()

    with (
        patch(
            "app.core.logging_config.get_settings",
            return_value=settings,
        ),
        patch(
            "app.core.logging_config.dictConfig",
            dict_config,
        ),
    ):
        configure_logging()

    config = dict_config.call_args.args[0]

    assert config["root"]["level"] == "DEBUG"
    assert config["loggers"]["uvicorn"]["level"] == "DEBUG"