from datetime import UTC, datetime, timedelta

from sqlalchemy.orm import Session

from app.core.security.session_credentials import (
    hash_session_credential,
)
from app.models.auth_session import AuthSession, AuthSessionType
from app.models.user import User
from app.repositories.auth_session import AuthSessionRepository


def _create_user(
    db_session: Session,
    *,
    username: str = "session-user",
) -> User:
    user = User(
        username=username,
        display_name="Session User",
    )

    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)

    return user


def _create_auth_session(
    db_session: Session,
    *,
    user: User,
    credential: str,
    session_type: AuthSessionType = AuthSessionType.WEB,
    created_at: datetime | None = None,
) -> AuthSession:
    timestamp = created_at or datetime(
        2026,
        8,
        21,
        10,
        0,
        tzinfo=UTC,
    )

    auth_session = AuthSession(
        user_id=user.id,
        session_type=session_type,
        credential_hash=hash_session_credential(
            credential,
        ),
        expires_at=timestamp + timedelta(days=180),
        last_used_at=timestamp,
    )

    db_session.add(auth_session)
    db_session.commit()
    db_session.refresh(auth_session)

    return auth_session


def test_add_persists_auth_session(
    db_session: Session,
) -> None:
    """Persist an authentication session."""

    user = _create_user(db_session)

    auth_session = AuthSession(
        user_id=user.id,
        session_type=AuthSessionType.WEB,
        credential_hash=hash_session_credential(
            "credential",
        ),
        expires_at=datetime(
            2027,
            2,
            17,
            tzinfo=UTC,
        ),
    )

    repository = AuthSessionRepository(
        db_session,
    )

    repository.add(auth_session)

    db_session.commit()
    db_session.refresh(auth_session)

    assert auth_session.id is not None
    assert auth_session.user_id == user.id


def test_get_by_id_returns_auth_session(
    db_session: Session,
) -> None:
    """Return an authentication session by UUID."""

    user = _create_user(db_session)

    auth_session = _create_auth_session(
        db_session,
        user=user,
        credential="credential",
    )

    repository = AuthSessionRepository(
        db_session,
    )

    result = repository.get_by_id(
        auth_session.id,
    )

    assert result is not None
    assert result.id == auth_session.id


def test_get_by_credential_hash_returns_auth_session(
    db_session: Session,
) -> None:
    """Return the session represented by a credential hash."""

    user = _create_user(db_session)

    credential = "credential"

    auth_session = _create_auth_session(
        db_session,
        user=user,
        credential=credential,
    )

    repository = AuthSessionRepository(
        db_session,
    )

    result = repository.get_by_credential_hash(
        hash_session_credential(
            credential,
        ),
    )

    assert result is not None
    assert result.id == auth_session.id


def test_get_by_credential_hash_returns_none_when_missing(
    db_session: Session,
) -> None:
    """Return None for an unknown credential hash."""

    repository = AuthSessionRepository(
        db_session,
    )

    result = repository.get_by_credential_hash(
        hash_session_credential(
            "unknown",
        ),
    )

    assert result is None


def test_list_by_user_returns_only_owned_sessions(
    db_session: Session,
) -> None:
    """Return authentication sessions belonging only to the requested user."""

    user = _create_user(
        db_session,
        username="first-user",
    )
    other_user = _create_user(
        db_session,
        username="second-user",
    )

    first = _create_auth_session(
        db_session,
        user=user,
        credential="first",
    )
    second = _create_auth_session(
        db_session,
        user=user,
        credential="second",
    )

    _create_auth_session(
        db_session,
        user=other_user,
        credential="other",
    )

    repository = AuthSessionRepository(
        db_session,
    )

    result = repository.list_by_user(
        user.id,
    )

    assert {session.id for session in result} == {
        first.id,
        second.id,
    }