from dataclasses import dataclass
from datetime import UTC, datetime, timedelta
from uuid import UUID

from sqlalchemy.orm import Session

from app.core.security.session_credentials import (
    generate_session_credential,
    hash_session_credential,
)
from app.models.auth_session import AuthSession, AuthSessionType
from app.repositories.auth_session import AuthSessionRepository

_SESSION_RENEWAL_INTERVAL = timedelta(days=1)


@dataclass(frozen=True, slots=True)
class CreatedAuthSession:
    """Authentication session together with its plaintext credential."""

    session: AuthSession
    credential: str


class AuthSessionService:
    """Manage the lifecycle of persistent authenticated sessions."""

    def __init__(
        self,
        *,
        session: Session,
        repository: AuthSessionRepository,
        idle_expire_days: int,
    ) -> None:
        if idle_expire_days <= 0:
            raise ValueError("Session idle expiration must be positive.")

        self._session = session
        self._repository = repository
        self._idle_expiration = timedelta(
            days=idle_expire_days,
        )

    def create(
        self,
        *,
        user_id: UUID,
        session_type: AuthSessionType,
        now: datetime | None = None,
    ) -> CreatedAuthSession:
        """Create a persistent authentication session."""

        created_at = _normalize_datetime(
            now or datetime.now(UTC),
        )

        generated_credential = generate_session_credential()

        auth_session = AuthSession(
            user_id=user_id,
            session_type=session_type,
            credential_hash=generated_credential.hash,
            expires_at=created_at + self._idle_expiration,
            last_used_at=created_at,
        )

        self._repository.add(
            auth_session,
        )

        self._session.commit()
        self._session.refresh(
            auth_session,
        )

        return CreatedAuthSession(
            session=auth_session,
            credential=generated_credential.value,
        )

    def resolve(
        self,
        credential: str,
        *,
        now: datetime | None = None,
    ) -> AuthSession | None:
        """Resolve a valid persistent authentication credential."""

        normalized_credential = credential.strip()

        if not normalized_credential:
            return None

        credential_hash = hash_session_credential(
            normalized_credential,
        )

        auth_session = self._repository.get_by_credential_hash(
            credential_hash,
        )

        if auth_session is None:
            return None

        current_time = _normalize_datetime(
            now or datetime.now(UTC),
        )

        if auth_session.revoked_at is not None:
            return None

        expires_at = _normalize_datetime(
            auth_session.expires_at,
        )

        if expires_at <= current_time:
            return None

        last_used_at = (
            _normalize_datetime(auth_session.last_used_at)
            if auth_session.last_used_at is not None
            else None
        )

        if last_used_at is None or current_time - last_used_at >= _SESSION_RENEWAL_INTERVAL:
            auth_session.last_used_at = current_time
            auth_session.expires_at = current_time + self._idle_expiration

            self._session.commit()

        return auth_session

    def rotate_mobile_credential(
        self,
        credential: str,
        *,
        now: datetime | None = None,
    ) -> CreatedAuthSession | None:
        """Rotate a valid Mobile refresh credential.

        The previous credential becomes invalid immediately because its
        stored hash is replaced by the newly generated credential hash.
        """

        normalized_credential = credential.strip()

        if not normalized_credential:
            return None

        credential_hash = hash_session_credential(
            normalized_credential,
        )

        auth_session = self._repository.get_by_credential_hash(
            credential_hash,
        )

        if auth_session is None:
            return None

        if auth_session.session_type != AuthSessionType.MOBILE:
            return None

        current_time = _normalize_datetime(
            now or datetime.now(UTC),
        )

        if auth_session.revoked_at is not None:
            return None

        expires_at = _normalize_datetime(
            auth_session.expires_at,
        )

        if expires_at <= current_time:
            return None

        generated_credential = generate_session_credential()

        auth_session.credential_hash = generated_credential.hash
        auth_session.last_used_at = current_time
        auth_session.expires_at = current_time + self._idle_expiration

        self._session.commit()
        self._session.refresh(
            auth_session,
        )

        return CreatedAuthSession(
            session=auth_session,
            credential=generated_credential.value,
        )

    def revoke_by_credential(
        self,
        credential: str,
        *,
        now: datetime | None = None,
    ) -> bool:
        """Revoke the authentication session represented by a credential."""

        normalized_credential = credential.strip()

        if not normalized_credential:
            return False

        credential_hash = hash_session_credential(
            normalized_credential,
        )

        auth_session = self._repository.get_by_credential_hash(
            credential_hash,
        )

        if auth_session is None:
            return False

        if auth_session.revoked_at is not None:
            return True

        auth_session.revoked_at = _normalize_datetime(
            now or datetime.now(UTC),
        )

        self._session.commit()

        return True

    def revoke(
        self,
        *,
        session_id: UUID,
        now: datetime | None = None,
    ) -> bool:
        """Revoke one authentication session."""

        auth_session = self._repository.get_by_id(
            session_id,
        )

        if auth_session is None:
            return False

        if auth_session.revoked_at is not None:
            return True

        auth_session.revoked_at = _normalize_datetime(
            now or datetime.now(UTC),
        )

        self._session.commit()

        return True

    def revoke_for_user(
        self,
        *,
        session_id: UUID,
        user_id: UUID,
        now: datetime | None = None,
    ) -> bool:
        """Revoke one authentication session when it belongs to the user."""

        auth_session = self._repository.get_by_id(
            session_id,
        )

        if auth_session is None or auth_session.user_id != user_id:
            return False

        if auth_session.revoked_at is not None:
            return True

        auth_session.revoked_at = _normalize_datetime(
            now or datetime.now(UTC),
        )

        self._session.commit()

        return True

    def revoke_all_for_user(
        self,
        *,
        user_id: UUID,
        now: datetime | None = None,
    ) -> int:
        """Revoke every active authentication session belonging to a user."""

        revoked_at = _normalize_datetime(
            now or datetime.now(UTC),
        )

        auth_sessions = self._repository.list_by_user(
            user_id,
        )

        revoked_count = 0

        for auth_session in auth_sessions:
            if auth_session.revoked_at is not None:
                continue

            auth_session.revoked_at = revoked_at
            revoked_count += 1

        if revoked_count > 0:
            self._session.commit()

        return revoked_count


def _normalize_datetime(
    value: datetime,
) -> datetime:
    """Return an aware UTC datetime."""

    if value.tzinfo is None:
        return value.replace(
            tzinfo=UTC,
        )

    return value.astimezone(UTC)
