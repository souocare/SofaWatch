from dataclasses import dataclass
from datetime import UTC, datetime, timedelta
from uuid import UUID

from sqlalchemy.orm import Session

from app.core.security.session_credentials import (
    generate_session_credential,
    hash_session_credential,
)
from app.models.auth_handoff import AuthHandoff
from app.repositories.auth_handoff import AuthHandoffRepository

_DEFAULT_HANDOFF_EXPIRATION = timedelta(minutes=2)


@dataclass(frozen=True, slots=True)
class CreatedAuthHandoff:
    """Authentication handoff together with its plaintext credential."""

    handoff: AuthHandoff
    credential: str


class AuthHandoffService:
    """Manage short-lived one-time authentication handoffs."""

    def __init__(
        self,
        *,
        session: Session,
        repository: AuthHandoffRepository,
        expiration: timedelta = _DEFAULT_HANDOFF_EXPIRATION,
    ) -> None:
        if expiration <= timedelta(0):
            raise ValueError("Authentication handoff expiration must be positive.")

        self._session = session
        self._repository = repository
        self._expiration = expiration

    @property
    def expiration(self) -> timedelta:
        """Return the lifetime of newly-created authentication handoffs."""

        return self._expiration

    def create(
        self,
        *,
        user_id: UUID,
        now: datetime | None = None,
    ) -> CreatedAuthHandoff:
        """Create a short-lived one-time authentication handoff."""

        created_at = _normalize_datetime(
            now or datetime.now(UTC),
        )

        generated_credential = generate_session_credential()

        handoff = AuthHandoff(
            user_id=user_id,
            credential_hash=generated_credential.hash,
            expires_at=created_at + self._expiration,
        )

        self._repository.add(handoff)

        self._session.commit()
        self._session.refresh(handoff)

        handoff.expires_at = _normalize_datetime(
            handoff.expires_at,
        )

        return CreatedAuthHandoff(
            handoff=handoff,
            credential=generated_credential.value,
        )

    def consume(
        self,
        credential: str,
        *,
        now: datetime | None = None,
    ) -> AuthHandoff | None:
        """Atomically consume a valid authentication handoff exactly once."""

        normalized_credential = credential.strip()

        if not normalized_credential:
            return None

        current_time = _normalize_datetime(
            now or datetime.now(UTC),
        )

        credential_hash = hash_session_credential(
            normalized_credential,
        )

        handoff = self._repository.consume_valid_by_credential_hash(
            credential_hash,
            used_at=current_time,
        )

        if handoff is None:
            return None

        self._session.commit()
        self._session.refresh(handoff)

        handoff.expires_at = _normalize_datetime(
            handoff.expires_at,
        )

        if handoff.used_at is not None:
            handoff.used_at = _normalize_datetime(
                handoff.used_at,
            )

        return handoff


def _normalize_datetime(
    value: datetime,
) -> datetime:
    """Return an aware UTC datetime."""

    if value.tzinfo is None:
        return value.replace(tzinfo=UTC)

    return value.astimezone(UTC)
