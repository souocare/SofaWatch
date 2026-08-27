from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.auth_session import AuthSession


class AuthSessionRepository:
    """Persistence operations for authenticated SofaWatch sessions."""

    def __init__(
        self,
        session: Session,
    ) -> None:
        self._session = session

    def get_by_id(
        self,
        session_id: UUID,
    ) -> AuthSession | None:
        """Return an authentication session by identifier."""

        return self._session.get(
            AuthSession,
            session_id,
        )

    def get_by_credential_hash(
        self,
        credential_hash: str,
    ) -> AuthSession | None:
        """Return the session represented by a credential hash."""

        return self._session.scalar(
            select(AuthSession).where(
                AuthSession.credential_hash == credential_hash,
            )
        )

    def list_by_user(
        self,
        user_id: UUID,
    ) -> list[AuthSession]:
        """Return all authentication sessions belonging to a user."""

        return list(
            self._session.scalars(
                select(AuthSession)
                .where(
                    AuthSession.user_id == user_id,
                )
                .order_by(
                    AuthSession.created_at.desc(),
                    AuthSession.id.desc(),
                )
            ).all()
        )

    def add(
        self,
        auth_session: AuthSession,
    ) -> AuthSession:
        """Add an authentication session to the current unit of work."""

        self._session.add(
            auth_session,
        )

        return auth_session
