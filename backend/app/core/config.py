from functools import lru_cache
from pathlib import Path

from pydantic import Field, SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict

BACKEND_DIR = Path(__file__).resolve().parents[2]
PROJECT_DIR = BACKEND_DIR.parent
ENV_FILE = PROJECT_DIR / ".env"


class Settings(BaseSettings):
    app_name: str = "SofaWatch"
    environment: str = "development"
    debug: bool = False

    api_host: str = "0.0.0.0"
    api_port: int = 8000

    database_url: str = "sqlite:///./data/sofawatch.db"

    secret_key: SecretStr = Field(min_length=32)

    default_language: str = "en"
    supported_languages: str = "en,pt-PT"

    tmdb_api_token: SecretStr | None = None
    tmdb_base_url: str = "https://api.themoviedb.org/3"
    tmdb_image_base_url: str = "https://image.tmdb.org/t/p"
    tmdb_timeout_seconds: float = 20.0

    tvdb_api_key: SecretStr | None = None
    tvdb_pin: SecretStr | None = None
    tvdb_base_url: str = "https://api4.thetvdb.com/v4"

    model_config = SettingsConfigDict(
        env_file=ENV_FILE,
        env_prefix="SOFAWATCH_",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    @property
    def supported_language_list(self) -> list[str]:
        return [
            language.strip() for language in self.supported_languages.split(",") if language.strip()
        ]


@lru_cache
def get_settings() -> Settings:
    return Settings()
