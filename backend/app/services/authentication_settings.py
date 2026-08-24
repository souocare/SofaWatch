from sqlalchemy.orm import Session

from app.models.authentication_settings import AuthenticationSettings
from app.repositories.authentication_settings import (
    AuthenticationSettingsRepository,
)


class AuthenticationSettingsService:
    """Manage global authentication settings for SofaWatch."""

    def __init__(
        self,
        *,
        session: Session,
        repository: AuthenticationSettingsRepository,
    ) -> None:
        self._session = session
        self._repository = repository

    def get(self) -> AuthenticationSettings:
        """Return the global authentication settings.

        The settings row is created lazily using secure defaults when the
        installation does not have one yet.
        """

        settings = self._repository.get()

        if settings is not None:
            return settings

        settings = AuthenticationSettings(
            open_registration=False,
        )

        self._repository.add(settings)

        self._session.commit()
        self._session.refresh(settings)

        return settings

    def set_open_registration(
        self,
        *,
        enabled: bool,
    ) -> AuthenticationSettings:
        """Enable or disable public account registration."""

        settings = self.get()

        settings.open_registration = enabled

        self._session.commit()
        self._session.refresh(settings)

        return settings