from datetime import datetime

from sqlalchemy import select, update
from sqlalchemy.orm import Session

from app.models.auth_handoff import AuthHandoff


class AuthHandoffRepository:
    """Persistence operations for authentication handoff credentials."""

    def __init__(
        self,
        session: Session,
    ) -> None:
        self._session = session

    def get_by_credential_hash(
        self,
        credential_hash: str,
    ) -> AuthHandoff | None:
        """Return the handoff represented by a credential hash."""

        return self._session.scalar(
            select(AuthHandoff).where(
                AuthHandoff.credential_hash == credential_hash,
            )
        )

    def consume_valid_by_credential_hash(
        self,
        credential_hash: str,
        *,
        used_at: datetime,
    ) -> AuthHandoff | None:
        """Atomically consume a valid handoff exactly once."""

        handoff_id = self._session.scalar(
            update(AuthHandoff)
            .where(
                AuthHandoff.credential_hash == credential_hash,
                AuthHandoff.used_at.is_(None),
                AuthHandoff.expires_at > used_at,
            )
            .values(
                used_at=used_at,
            )
            .returning(
                AuthHandoff.id,
            )
        )

        if handoff_id is None:
            return None

        return self._session.get(
            AuthHandoff,
            handoff_id,
        )

    def add(
        self,
        handoff: AuthHandoff,
    ) -> AuthHandoff:
        """Add an authentication handoff to the current unit of work."""

        self._session.add(handoff)

        return handoff