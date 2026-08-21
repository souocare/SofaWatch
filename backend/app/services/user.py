from uuid import UUID

from app.models.user import User
from app.repositories.user import UserRepository


class UserService:
    """Business logic for SofaWatch users."""

    def __init__(
        self,
        *,
        user_repository: UserRepository,
    ) -> None:
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

    def get_local(
        self,
    ) -> User | None:
        """Return the local SofaWatch user."""

        return self._user_repository.get_local()