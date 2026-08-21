from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.user import User


class UserRepository:
    """Persistence operations for SofaWatch users."""

    def __init__(
        self,
        session: Session,
    ) -> None:
        self._session = session

    def get_by_id(
        self,
        user_id: UUID,
    ) -> User | None:
        """Return a user by its internal identifier."""

        return self._session.get(
            User,
            user_id,
        )

    def get_by_username(
        self,
        username: str,
    ) -> User | None:
        """Return a user by its normalized username."""

        return self._session.scalar(
            select(User).where(
                User.username == username,
            )
        )

    def get_by_email(
        self,
        email: str,
    ) -> User | None:
        """Return a user by its normalized email address."""

        return self._session.scalar(
            select(User).where(
                User.email == email,
            )
        )

    def exists_any(self) -> bool:
        """Return whether at least one SofaWatch user exists."""

        user_id = self._session.scalar(
            select(User.id).limit(1)
        )

        return user_id is not None

    # def get_local(
    #     self,
    # ) -> User | None:
    #     """Return the legacy local SofaWatch user."""

    #     return self._session.scalar(
    #         select(User).where(
    #             User.is_local.is_(True),
    #         )
    #     )

    def add(
        self,
        user: User,
    ) -> User:
        """Add a user to the current unit of work."""

        self._session.add(user)

        return user