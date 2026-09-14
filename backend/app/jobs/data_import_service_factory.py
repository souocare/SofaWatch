from sqlalchemy.orm import Session

from app.core.config import Settings, get_settings
from app.providers.tmdb import TMDBClient
from app.services.data_import import DataImportService
from app.services.data_import_builder import build_data_import_service


class WorkerDataImportServiceFactory:
    """Build data import services using a worker-owned TMDB client."""

    def __init__(
        self,
        *,
        settings: Settings | None = None,
    ) -> None:
        self._settings = settings or get_settings()
        self._tmdb_client = TMDBClient(
            settings=self._settings,
        )

    def __call__(
        self,
        session: Session,
    ) -> DataImportService:
        """Build an import service for one worker database session."""

        return build_data_import_service(
            session=session,
            settings=self._settings,
            tmdb_client=self._tmdb_client,
        )

    def close(self) -> None:
        """Release worker-owned provider resources."""

        self._tmdb_client.close()
