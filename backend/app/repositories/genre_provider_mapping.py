from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.genre_provider_mapping import (
    GenreProviderMapping,
)


class GenreProviderMappingRepository:
    def __init__(
        self,
        session: Session,
    ) -> None:
        self._session = session

    def get(
        self,
        *,
        provider: str,
        media_type: str,
        provider_genre_id: int,
    ) -> GenreProviderMapping | None:
        statement = select(
            GenreProviderMapping,
        ).where(
            GenreProviderMapping.provider == provider,
            GenreProviderMapping.media_type == media_type,
            GenreProviderMapping.provider_genre_id
            == provider_genre_id,
        )

        return self._session.scalar(statement)

    def add(
        self,
        mapping: GenreProviderMapping,
    ) -> GenreProviderMapping:
        self._session.add(mapping)
        self._session.flush()

        return mapping