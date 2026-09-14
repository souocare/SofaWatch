from typing import Protocol

from app.models.enums import DataImportPhase


class DataImportProgressCallback(Protocol):
    """Receive progress updates while a user data import is processed."""

    def __call__(
        self,
        *,
        phase: DataImportPhase,
        current: int,
        total: int,
    ) -> None: ...
