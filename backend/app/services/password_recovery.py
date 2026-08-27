from datetime import UTC, datetime

from sqlalchemy.orm import Session

from app.core.security.passwords import hash_password
from app.core.security.session_credentials import (
    hash_session_credential,
)
from app.repositories.auth_session import AuthSessionRepository
from app.repositories.password_reset_token import (
    PasswordResetTokenRepository,
)
from app.repositories.user import UserRepository


class PasswordRecoveryInvalidError(Exception):
    """Raised when a password recovery credential cannot be used."""


class PasswordRecoveryService:
    """Complete password recovery using a short-lived one-time credential."""

    def __init__(
        self,
        *,
        session: Session,
        password_reset_token_repository: PasswordResetTokenRepository,
        user_repository: UserRepository,
        auth_session_repository: AuthSessionRepository,
    ) -> None:
        self._session = session
        self._password_reset_token_repository = password_reset_token_repository
        self._user_repository = user_repository
        self._auth_session_repository = auth_session_repository

    def complete(
        self,
        *,
        credential: str,
        new_password: str,
        now: datetime | None = None,
    ) -> None:
        """Set a new password and invalidate existing sessions."""

        normalized_credential = credential.strip()

        if not normalized_credential:
            raise PasswordRecoveryInvalidError

        current_time = _normalize_datetime(
            now or datetime.now(UTC),
        )

        credential_hash = hash_session_credential(
            normalized_credential,
        )

        reset_token = self._password_reset_token_repository.consume_valid_by_credential_hash(
            credential_hash,
            used_at=current_time,
        )

        if reset_token is None:
            raise PasswordRecoveryInvalidError

        user = self._user_repository.get_by_id(
            reset_token.user_id,
        )

        if user is None or not user.is_active or user.is_admin:
            self._session.rollback()

            raise PasswordRecoveryInvalidError

        user.password_hash = hash_password(
            new_password,
        )

        auth_sessions = self._auth_session_repository.list_by_user(
            user.id,
        )

        for auth_session in auth_sessions:
            if auth_session.revoked_at is not None:
                continue

            auth_session.revoked_at = current_time

        try:
            self._session.commit()
        except BaseException:
            self._session.rollback()
            raise


def _normalize_datetime(
    value: datetime,
) -> datetime:
    """Return an aware UTC datetime."""

    if value.tzinfo is None:
        return value.replace(
            tzinfo=UTC,
        )

    return value.astimezone(UTC)
