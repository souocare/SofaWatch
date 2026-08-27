from dataclasses import dataclass
from datetime import UTC, datetime, timedelta
from uuid import UUID

from sqlalchemy.orm import Session

from app.core.security.session_credentials import (
    generate_session_credential,
    hash_session_credential,
)
from app.models.password_reset_token import PasswordResetToken
from app.repositories.password_reset_token import (
    PasswordResetTokenRepository,
)

_DEFAULT_PASSWORD_RESET_EXPIRATION = timedelta(minutes=30)


@dataclass(frozen=True, slots=True)
class CreatedPasswordResetToken:
    """Password reset token together with its plaintext credential."""

    reset_token: PasswordResetToken
    credential: str


class PasswordResetTokenService:
    """Manage short-lived one-time password reset credentials."""

    def __init__(
        self,
        *,
        session: Session,
        repository: PasswordResetTokenRepository,
        expiration: timedelta = _DEFAULT_PASSWORD_RESET_EXPIRATION,
    ) -> None:
        if expiration <= timedelta(0):
            raise ValueError("Password reset token expiration must be positive.")

        self._session = session
        self._repository = repository
        self._expiration = expiration

    @property
    def expiration(self) -> timedelta:
        """Return the lifetime of newly-created password reset tokens."""

        return self._expiration

    def create(
        self,
        *,
        user_id: UUID,
        now: datetime | None = None,
    ) -> CreatedPasswordResetToken:
        """Create a short-lived one-time password reset token."""

        created_at = _normalize_datetime(
            now or datetime.now(UTC),
        )

        generated_credential = generate_session_credential()

        reset_token = PasswordResetToken(
            user_id=user_id,
            credential_hash=generated_credential.hash,
            expires_at=created_at + self._expiration,
        )

        self._repository.add(reset_token)

        self._session.commit()
        self._session.refresh(reset_token)

        reset_token.expires_at = _normalize_datetime(
            reset_token.expires_at,
        )

        return CreatedPasswordResetToken(
            reset_token=reset_token,
            credential=generated_credential.value,
        )

    def consume(
        self,
        credential: str,
        *,
        now: datetime | None = None,
    ) -> PasswordResetToken | None:
        """Atomically consume a valid password reset token exactly once."""

        normalized_credential = credential.strip()

        if not normalized_credential:
            return None

        current_time = _normalize_datetime(
            now or datetime.now(UTC),
        )

        credential_hash = hash_session_credential(
            normalized_credential,
        )

        reset_token = self._repository.consume_valid_by_credential_hash(
            credential_hash,
            used_at=current_time,
        )

        if reset_token is None:
            return None

        self._session.commit()
        self._session.refresh(reset_token)

        reset_token.expires_at = _normalize_datetime(
            reset_token.expires_at,
        )

        if reset_token.used_at is not None:
            reset_token.used_at = _normalize_datetime(
                reset_token.used_at,
            )

        return reset_token


def _normalize_datetime(
    value: datetime,
) -> datetime:
    """Return an aware UTC datetime."""

    if value.tzinfo is None:
        return value.replace(tzinfo=UTC)

    return value.astimezone(UTC)
