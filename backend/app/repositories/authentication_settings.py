from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.authentication_settings import AuthenticationSettings


class AuthenticationSettingsRepository:
    """Persistence operations for global authentication settings."""

    def __init__(
        self,
        session: Session,
    ) -> None:
        self._session = session

    def get(self) -> AuthenticationSettings | None:
        """Return the installation authentication settings, if they exist."""

        return self._session.scalar(select(AuthenticationSettings).limit(1))

    def add(
        self,
        settings: AuthenticationSettings,
    ) -> AuthenticationSettings:
        """Add authentication settings to the current unit of work."""

        self._session.add(settings)

        return settings
