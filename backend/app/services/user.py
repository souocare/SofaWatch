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

    def get_local(
        self,
    ) -> User | None:
        """Return the local SofaWatch user."""

        return self._user_repository.get_local()