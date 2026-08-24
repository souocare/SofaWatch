from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.core.security.passwords import hash_password
from app.models.user import User
from app.repositories.user import UserRepository
from app.services.authentication_settings import AuthenticationSettingsService


class RegistrationClosedError(Exception):
    """Raised when public account registration is disabled."""


class UsernameAlreadyExistsError(Exception):
    """Raised when the requested username is already in use."""


class EmailAlreadyExistsError(Exception):
    """Raised when the requested email address is already in use."""


class RegistrationService:
    """Register regular SofaWatch users when public registration is enabled."""

    def __init__(
        self,
        *,
        session: Session,
        user_repository: UserRepository,
        authentication_settings_service: AuthenticationSettingsService,
    ) -> None:
        self._session = session
        self._user_repository = user_repository
        self._authentication_settings_service = authentication_settings_service

    def register(
        self,
        *,
        username: str,
        display_name: str,
        password: str,
        email: str | None = None,
    ) -> User:
        """Create a regular SofaWatch user through public registration."""

        settings = self._authentication_settings_service.get()

        if not settings.open_registration:
            raise RegistrationClosedError

        normalized_username = username.strip().lower()
        normalized_display_name = display_name.strip()

        normalized_email = (
            email.strip().lower()
            if email is not None and email.strip()
            else None
        )

        if self._user_repository.get_by_username(normalized_username) is not None:
            raise UsernameAlreadyExistsError

        if (
            normalized_email is not None
            and self._user_repository.get_by_email(normalized_email) is not None
        ):
            raise EmailAlreadyExistsError

        user = User(
            username=normalized_username,
            email=normalized_email,
            display_name=normalized_display_name,
            password_hash=hash_password(password),
            is_active=True,
            is_local=False,
            is_admin=False,
        )

        self._user_repository.add(user)

        try:
            self._session.commit()
        except IntegrityError as error:
            self._session.rollback()

            if self._user_repository.get_by_username(normalized_username) is not None:
                raise UsernameAlreadyExistsError from error

            if (
                normalized_email is not None
                and self._user_repository.get_by_email(normalized_email) is not None
            ):
                raise EmailAlreadyExistsError from error

            raise

        self._session.refresh(user)

        return user