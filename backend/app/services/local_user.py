from sqlalchemy.orm import Session

from app.models.user import User
from app.repositories.user import UserRepository


class LocalUserService:
    """Manage the single local SofaWatch user."""

    def __init__(
        self,
        *,
        session: Session,
        user_repository: UserRepository,
    ) -> None:
        self._session = session
        self._user_repository = user_repository

    def get_or_create(self) -> User:
        """Return the local user, creating it when necessary."""

        user = self._user_repository.get_local()

        if user is not None:
            return user

        user = User(
            display_name="Local User",
            is_local=True,
        )

        self._user_repository.add(user)

        self._session.commit()
        self._session.refresh(user)

        return user