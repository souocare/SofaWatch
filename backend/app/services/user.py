from uuid import UUID

from sqlalchemy.orm import Session

from app.models.user import User
from app.repositories.user import UserRepository
from app.core.security.passwords import hash_password, verify_password


class CurrentPasswordInvalidError(Exception):
    """Raised when the supplied current password is incorrect."""


class PasswordUnavailableError(Exception):
    """Raised when the account does not have a password that can be changed."""

class UserService:
    """Business logic for SofaWatch users."""

    def __init__(
        self,
        *,
        session: Session,
        user_repository: UserRepository,
    ) -> None:
        self._session = session
        self._user_repository = user_repository

    def get_by_id(
        self,
        user_id: UUID,
    ) -> User | None:
        """Return a user by its internal identifier."""

        return self._user_repository.get_by_id(
            user_id,
        )

    def get_by_username(
        self,
        username: str,
    ) -> User | None:
        """Return a user by username."""

        normalized_username = username.strip().lower()

        if not normalized_username:
            return None

        return self._user_repository.get_by_username(
            normalized_username,
        )

    def get_by_email(
        self,
        email: str,
    ) -> User | None:
        """Return a user by email address."""

        normalized_email = email.strip().lower()

        if not normalized_email:
            return None

        return self._user_repository.get_by_email(
            normalized_email,
        )

    def requires_initial_setup(self) -> bool:
        """Return whether the installation still needs its first user."""

        return not self._user_repository.exists_any()

    def update_display_name(
        self,
        *,
        user: User,
        display_name: str,
    ) -> User:
        """Update the current user's display name."""

        normalized_display_name = display_name.strip()

        if not normalized_display_name:
            raise ValueError(
                "Display name must not be blank.",
            )

        user.display_name = normalized_display_name

        self._session.commit()
        self._session.refresh(user)

        return user


    def update_password(
        self,
        *,
        user: User,
        current_password: str,
        new_password: str,
    ) -> User:
        """Change the current user's password after verifying the old one."""

        if user.password_hash is None:
            raise PasswordUnavailableError

        if not verify_password(
            current_password,
            user.password_hash,
        ):
            raise CurrentPasswordInvalidError

        user.password_hash = hash_password(
            new_password,
        )

        self._session.commit()
        self._session.refresh(user)

        return user


    def list_users(self) -> list[User]:
        """Return all SofaWatch users."""

        return self._user_repository.list_all()