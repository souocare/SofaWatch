from datetime import UTC, datetime

from sqlalchemy.orm import Session

from app.core.security.passwords import hash_password
from app.models.user import User
from app.repositories.auth_session import AuthSessionRepository


class AdministratorRecoveryUnavailableError(Exception):
    """Raised when password recovery is not allowed for the target user."""


class AdministratorPasswordRecoveryService:
    """Recover an administrator password directly from the server."""

    def __init__(
        self,
        *,
        session: Session,
        auth_session_repository: AuthSessionRepository,
    ) -> None:
        self._session = session
        self._auth_session_repository = auth_session_repository

    def reset_password(
        self,
        *,
        user: User,
        new_password: str,
        now: datetime | None = None,
    ) -> User:
        """Set a new administrator password and revoke existing sessions."""

        if not user.is_admin or not user.is_active:
            raise AdministratorRecoveryUnavailableError

        if len(new_password) < 8 or len(new_password) > 128:
            raise ValueError("Password must contain between 8 and 128 characters.")

        revoked_at = now or datetime.now(UTC)

        if revoked_at.tzinfo is None:
            revoked_at = revoked_at.replace(tzinfo=UTC)
        else:
            revoked_at = revoked_at.astimezone(UTC)

        user.password_hash = hash_password(
            new_password,
        )

        auth_sessions = self._auth_session_repository.list_by_user(
            user.id,
        )

        for auth_session in auth_sessions:
            if auth_session.revoked_at is None:
                auth_session.revoked_at = revoked_at

        self._session.commit()
        self._session.refresh(user)

        return user
