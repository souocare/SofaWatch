from uuid import UUID

from sqlalchemy.exc import IntegrityError

from app.models.data_import_run import DataImportRun
from app.repositories.data_import_run import DataImportRunRepository
from app.schemas.data_export import SofaWatchExportResponse


class ActiveDataImportExistsError(Exception):
    """Raised when the user already has an active data import."""

    def __init__(
        self,
        run: DataImportRun,
    ) -> None:
        super().__init__("The user already has an active data import.")
        self.run = run


class DataImportRunNotFoundError(Exception):
    """Raised when an import run is not visible to the requested user."""


class DataImportRunService:
    """Manage persistent user-scoped data import executions."""

    def __init__(
        self,
        repository: DataImportRunRepository,
    ) -> None:
        self._repository = repository

    def submit(
        self,
        *,
        user_id: UUID,
        export: SofaWatchExportResponse,
    ) -> DataImportRun:
        """Create a queued persistent data import execution."""

        active = self._repository.get_active_for_user(
            user_id=user_id,
        )

        if active is not None:
            raise ActiveDataImportExistsError(
                active,
            )

        run = DataImportRun(
            user_id=user_id,
            payload=export.model_dump(
                mode="json",
            ),
        )

        self._repository.add(
            run,
        )

        try:
            self._repository.commit()
        except IntegrityError:
            self._repository.rollback()

            active = self._repository.get_active_for_user(
                user_id=user_id,
            )

            if active is not None:
                raise ActiveDataImportExistsError(
                    active,
                ) from None

            raise

        self._repository.refresh(
            run,
        )

        return run

    def get_active(
        self,
        *,
        user_id: UUID,
    ) -> DataImportRun | None:
        """Return the user's current queued or running import."""

        return self._repository.get_active_for_user(
            user_id=user_id,
        )

    def get(
        self,
        *,
        run_id: UUID,
        user_id: UUID,
    ) -> DataImportRun:
        """Return a specific import execution owned by the user."""

        run = self._repository.get_for_user(
            run_id=run_id,
            user_id=user_id,
        )

        if run is None:
            raise DataImportRunNotFoundError

        return run