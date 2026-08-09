from app.models.genre import Genre
from app.models.genre_provider_mapping import (
    GenreProviderMapping,
)
from app.repositories.genre import GenreRepository
from app.repositories.genre_provider_mapping import (
    GenreProviderMappingRepository,
)


class GenreMappingService:
    def __init__(
        self,
        *,
        genre_repository: GenreRepository,
        mapping_repository: GenreProviderMappingRepository,
    ) -> None:
        self._genre_repository = genre_repository
        self._mapping_repository = mapping_repository

    def resolve(
        self,
        *,
        provider: str,
        media_type: str,
        provider_genre_id: int,
        name: str,
    ) -> Genre:
        existing_mapping = (
            self._mapping_repository.get(
                provider=provider,
                media_type=media_type,
                provider_genre_id=provider_genre_id,
            )
        )

        if existing_mapping is not None:
            return existing_mapping.genre

        genre = self._genre_repository.get_or_create(
            name=name,
        )

        self._mapping_repository.add(
            GenreProviderMapping(
                genre_id=genre.id,
                provider=provider,
                media_type=media_type,
                provider_genre_id=provider_genre_id,
            ),
        )

        return genre