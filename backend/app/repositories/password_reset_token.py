from datetime import datetime

from sqlalchemy import select, update
from sqlalchemy.orm import Session

from app.models.password_reset_token import PasswordResetToken


class PasswordResetTokenRepository:
    """Persistence operations for password reset credentials."""

    def __init__(
        self,
        session: Session,
    ) -> None:
        self._session = session

    def get_by_credential_hash(
        self,
        credential_hash: str,
    ) -> PasswordResetToken | None:
        """Return the password reset represented by a credential hash."""

        return self._session.scalar(
            select(PasswordResetToken).where(
                PasswordResetToken.credential_hash == credential_hash,
            )
        )

    def consume_valid_by_credential_hash(
        self,
        credential_hash: str,
        *,
        used_at: datetime,
    ) -> PasswordResetToken | None:
        """Atomically consume a valid password reset token exactly once."""

        reset_token_id = self._session.scalar(
            update(PasswordResetToken)
            .where(
                PasswordResetToken.credential_hash == credential_hash,
                PasswordResetToken.used_at.is_(None),
                PasswordResetToken.expires_at > used_at,
            )
            .values(
                used_at=used_at,
            )
            .returning(
                PasswordResetToken.id,
            )
        )

        if reset_token_id is None:
            return None

        return self._session.get(
            PasswordResetToken,
            reset_token_id,
        )

    def add(
        self,
        reset_token: PasswordResetToken,
    ) -> PasswordResetToken:
        """Add a password reset token to the current unit of work."""

        self._session.add(reset_token)

        return reset_token