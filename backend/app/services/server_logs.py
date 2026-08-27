import json
import re
from datetime import UTC, datetime
from pathlib import Path
from typing import cast

from app.core.config import Settings
from app.schemas.server import (
    ServerLogComponent,
    ServerLogEntryResponse,
    ServerLogLevel,
    ServerLogsResponse,
)

_LOG_COMPONENTS: tuple[ServerLogComponent, ...] = (
    "api",
    "worker",
)

_LOG_LEVELS: frozenset[str] = frozenset(
    {
        "DEBUG",
        "INFO",
        "WARNING",
        "ERROR",
        "CRITICAL",
    }
)

_SECRET_PATTERNS: tuple[re.Pattern[str], ...] = (
    re.compile(
        r"(?i)\b(authorization)\s*[:=]\s*(bearer\s+)?[^\s,;]+",
    ),
    re.compile(
        r"(?i)\b(api[_-]?key|token|secret|password|pin)\s*[:=]\s*[^\s,;]+",
    ),
)


class ServerLogsService:
    """Read and sanitize persisted SofaWatch Server logs."""

    def __init__(
        self,
        *,
        settings: Settings,
    ) -> None:
        self._log_directory = (Path(settings.data_storage_path) / "logs").resolve()

    def list_logs(
        self,
        *,
        level: ServerLogLevel | None = None,
        offset: int = 0,
        limit: int = 50,
    ) -> ServerLogsResponse:
        """Return recent safe log entries across SofaWatch processes."""

        entries = self._read_entries()

        if level is not None:
            entries = [entry for entry in entries if entry.level == level]

        entries.sort(
            key=lambda entry: entry.timestamp,
            reverse=True,
        )

        total = len(entries)

        items = entries[offset : offset + limit]

        return ServerLogsResponse(
            items=items,
            offset=offset,
            limit=limit,
            total=total,
            has_next=offset + len(items) < total,
        )

    def _read_entries(
        self,
    ) -> list[ServerLogEntryResponse]:
        entries: list[ServerLogEntryResponse] = []

        for component in _LOG_COMPONENTS:
            for path in self._component_log_paths(
                component,
            ):
                entries.extend(
                    self._read_log_file(
                        path=path,
                        component=component,
                    )
                )

        return entries

    def _component_log_paths(
        self,
        component: ServerLogComponent,
    ) -> list[Path]:
        """Return active and rotated log files for one process."""

        if not self._log_directory.is_dir():
            return []

        paths: list[Path] = []

        active_path = self._log_directory / f"{component}.log"

        if active_path.is_file():
            paths.append(
                active_path,
            )

        paths.extend(
            sorted(
                path
                for path in self._log_directory.glob(f"{component}.log.*")
                if path.is_file() and path.name.removeprefix(f"{component}.log.").isdigit()
            )
        )

        return paths

    def _read_log_file(
        self,
        *,
        path: Path,
        component: ServerLogComponent,
    ) -> list[ServerLogEntryResponse]:
        entries: list[ServerLogEntryResponse] = []

        try:
            with path.open(
                "r",
                encoding="utf-8",
            ) as handle:
                for line in handle:
                    entry = self._parse_entry(
                        line=line,
                        component=component,
                    )

                    if entry is not None:
                        entries.append(
                            entry,
                        )

        except OSError:
            return []

        return entries

    def _parse_entry(
        self,
        *,
        line: str,
        component: ServerLogComponent,
    ) -> ServerLogEntryResponse | None:
        try:
            payload = json.loads(
                line,
            )
        except (
            json.JSONDecodeError,
            TypeError,
        ):
            return None

        if not isinstance(
            payload,
            dict,
        ):
            return None

        timestamp = self._parse_timestamp(
            payload.get(
                "timestamp",
            )
        )

        level = payload.get(
            "level",
        )
        logger = payload.get(
            "logger",
        )
        message = payload.get(
            "message",
        )

        if (
            timestamp is None
            or not isinstance(level, str)
            or level not in _LOG_LEVELS
            or not isinstance(logger, str)
            or not logger.strip()
            or not isinstance(message, str)
        ):
            return None

        return ServerLogEntryResponse(
            timestamp=timestamp,
            level=cast(
                ServerLogLevel,
                level,
            ),
            logger=logger.strip(),
            message=self._sanitize_message(
                message,
            ),
            component=component,
        )

    @staticmethod
    def _parse_timestamp(
        value: object,
    ) -> datetime | None:
        if not isinstance(
            value,
            str,
        ):
            return None

        try:
            timestamp = datetime.fromisoformat(
                value,
            )
        except ValueError:
            return None

        if timestamp.tzinfo is None:
            return timestamp.replace(
                tzinfo=UTC,
            )

        return timestamp.astimezone(
            UTC,
        )

    @staticmethod
    def _sanitize_message(
        message: str,
    ) -> str:
        """Redact common credentials from log messages."""

        sanitized = message

        for pattern in _SECRET_PATTERNS:
            sanitized = pattern.sub(
                lambda match: f"{match.group(1)}=[REDACTED]",
                sanitized,
            )

        return sanitized
