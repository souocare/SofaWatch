from sqlalchemy import text
from sqlalchemy.orm import Session

from app.core.security.passwords import hash_password
from app.models.user import User
from app.repositories.user import UserRepository


class InitialSetupAlreadyCompletedError(Exception):
    """Raised when the first SofaWatch account has already been created."""


class InitialSetupService:
    """Create the first SofaWatch administrator account."""

    def __init__(
        self,
        *,
        session: Session,
        user_repository: UserRepository,
    ) -> None:
        self._session = session
        self._user_repository = user_repository

    def create_first_admin(
        self,
        *,
        username: str,
        display_name: str,
        password: str,
        email: str | None = None,
    ) -> User:
        """Create the first account and grant it administrator privileges."""

        normalized_username = username.strip().lower()
        normalized_display_name = display_name.strip()
        normalized_email = (
            email.strip().lower()
            if email is not None and email.strip()
            else None
        )

        try:
            # SofaWatch currently uses SQLite.
            #
            # BEGIN IMMEDIATE serializes concurrent writers before we check
            # whether a user already exists. This prevents two simultaneous
            # first-run requests from both creating an administrator.
            self._session.execute(
                text("BEGIN IMMEDIATE"),
            )

            if self._user_repository.exists_any():
                raise InitialSetupAlreadyCompletedError

            user = User(
                username=normalized_username,
                email=normalized_email,
                display_name=normalized_display_name,
                password_hash=hash_password(password),
                is_active=True,
                is_admin=True,
            )

            self._user_repository.add(user)

            self._session.commit()
            self._session.refresh(user)

            return user

        except InitialSetupAlreadyCompletedError:
            self._session.rollback()
            raise

        except Exception:
            self._session.rollback()
            raise