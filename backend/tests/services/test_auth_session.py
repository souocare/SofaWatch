from datetime import UTC, datetime, timedelta
from uuid import uuid4

from sqlalchemy.orm import Session

from app.models.auth_session import AuthSessionType
from app.models.user import User
from app.repositories.auth_session import AuthSessionRepository
from app.services.auth_session import AuthSessionService


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


def _create_service(
    db_session: Session,
) -> AuthSessionService:
    return AuthSessionService(
        session=db_session,
        repository=AuthSessionRepository(
            db_session,
        ),
        idle_expire_days=180,
    )


def _as_utc(value: datetime) -> datetime:
    """Normalize SQLite datetime values to aware UTC datetimes."""

    if value.tzinfo is None:
        return value.replace(tzinfo=UTC)

    return value.astimezone(UTC)


def test_create_persists_session_without_plaintext_credential(
    db_session: Session,
) -> None:
    """Create a session while persisting only the credential hash."""

    user = _create_user(db_session)
    service = _create_service(db_session)

    now = datetime(
        2026,
        8,
        21,
        10,
        0,
        tzinfo=UTC,
    )

    created = service.create(
        user_id=user.id,
        session_type=AuthSessionType.WEB,
        now=now,
    )

    assert created.credential
    assert created.session.credential_hash != created.credential
    assert created.session.session_type == AuthSessionType.WEB
    assert created.session.last_used_at is not None

    assert (
        _as_utc(
            created.session.last_used_at,
        )
        == now
    )

    assert _as_utc(
        created.session.expires_at,
    ) == now + timedelta(
        days=180,
    )


def test_resolve_returns_session_for_valid_credential(
    db_session: Session,
) -> None:
    """Resolve a valid persistent session credential."""

    user = _create_user(db_session)
    service = _create_service(db_session)

    created_at = datetime(
        2026,
        8,
        21,
        10,
        0,
        tzinfo=UTC,
    )

    created = service.create(
        user_id=user.id,
        session_type=AuthSessionType.WEB,
        now=created_at,
    )

    result = service.resolve(
        created.credential,
        now=created_at + timedelta(hours=1),
    )

    assert result is not None
    assert result.id == created.session.id


def test_resolve_returns_none_for_unknown_credential(
    db_session: Session,
) -> None:
    """Reject an unknown persistent session credential."""

    service = _create_service(db_session)

    result = service.resolve(
        "unknown-credential",
        now=datetime(
            2026,
            8,
            21,
            10,
            0,
            tzinfo=UTC,
        ),
    )

    assert result is None


def test_resolve_does_not_renew_before_interval(
    db_session: Session,
) -> None:
    """Avoid persisting session activity more than once per renewal interval."""

    user = _create_user(db_session)
    service = _create_service(db_session)

    created_at = datetime(
        2026,
        8,
        21,
        10,
        0,
        tzinfo=UTC,
    )

    created = service.create(
        user_id=user.id,
        session_type=AuthSessionType.WEB,
        now=created_at,
    )

    original_expires_at = created.session.expires_at

    result = service.resolve(
        created.credential,
        now=created_at + timedelta(hours=23),
    )

    assert result is not None
    assert result.last_used_at is not None

    assert (
        _as_utc(
            result.last_used_at,
        )
        == created_at
    )

    assert _as_utc(
        result.expires_at,
    ) == _as_utc(
        original_expires_at,
    )


def test_resolve_renews_session_after_interval(
    db_session: Session,
) -> None:
    """Extend the idle expiration after the renewal interval."""

    user = _create_user(db_session)
    service = _create_service(db_session)

    created_at = datetime(
        2026,
        8,
        21,
        10,
        0,
        tzinfo=UTC,
    )

    created = service.create(
        user_id=user.id,
        session_type=AuthSessionType.WEB,
        now=created_at,
    )

    renewed_at = created_at + timedelta(
        days=2,
    )

    result = service.resolve(
        created.credential,
        now=renewed_at,
    )

    assert result is not None
    assert result.last_used_at is not None

    assert (
        _as_utc(
            result.last_used_at,
        )
        == renewed_at
    )

    assert _as_utc(
        result.expires_at,
    ) == renewed_at + timedelta(
        days=180,
    )


def test_resolve_returns_none_for_expired_session(
    db_session: Session,
) -> None:
    """Reject a session after its idle expiration."""

    user = _create_user(db_session)
    service = _create_service(db_session)

    created_at = datetime(
        2026,
        8,
        21,
        10,
        0,
        tzinfo=UTC,
    )

    created = service.create(
        user_id=user.id,
        session_type=AuthSessionType.WEB,
        now=created_at,
    )

    result = service.resolve(
        created.credential,
        now=created_at + timedelta(days=180),
    )

    assert result is None


def test_revoke_invalidates_session(
    db_session: Session,
) -> None:
    """Reject a session after explicit revocation."""

    user = _create_user(db_session)
    service = _create_service(db_session)

    created_at = datetime(
        2026,
        8,
        21,
        10,
        0,
        tzinfo=UTC,
    )

    created = service.create(
        user_id=user.id,
        session_type=AuthSessionType.WEB,
        now=created_at,
    )

    revoked = service.revoke(
        session_id=created.session.id,
        now=created_at + timedelta(hours=1),
    )

    result = service.resolve(
        created.credential,
        now=created_at + timedelta(hours=2),
    )

    assert revoked is True
    assert result is None


def test_revoke_returns_false_for_unknown_session(
    db_session: Session,
) -> None:
    """Return False when the requested session does not exist."""

    from uuid import uuid4

    service = _create_service(db_session)

    result = service.revoke(
        session_id=uuid4(),
    )

    assert result is False


def test_revoke_all_for_user_does_not_revoke_other_users_sessions(
    db_session: Session,
) -> None:
    """Revoke sessions only for the requested user."""

    user = _create_user(
        db_session,
        username="first-user",
    )
    other_user = _create_user(
        db_session,
        username="second-user",
    )

    service = _create_service(db_session)

    now = datetime(
        2026,
        8,
        21,
        10,
        0,
        tzinfo=UTC,
    )

    first = service.create(
        user_id=user.id,
        session_type=AuthSessionType.WEB,
        now=now,
    )
    second = service.create(
        user_id=user.id,
        session_type=AuthSessionType.MOBILE,
        now=now,
    )
    other = service.create(
        user_id=other_user.id,
        session_type=AuthSessionType.WEB,
        now=now,
    )

    revoked_count = service.revoke_all_for_user(
        user_id=user.id,
        now=now + timedelta(hours=1),
    )

    assert revoked_count == 2

    assert (
        service.resolve(
            first.credential,
            now=now + timedelta(hours=2),
        )
        is None
    )

    assert (
        service.resolve(
            second.credential,
            now=now + timedelta(hours=2),
        )
        is None
    )

    assert (
        service.resolve(
            other.credential,
            now=now + timedelta(hours=2),
        )
        is not None
    )


def test_revoke_by_credential_invalidates_session(
    db_session: Session,
) -> None:
    """Revoke a persistent session using its plaintext credential."""

    user = _create_user(db_session)
    service = _create_service(db_session)

    created_at = datetime(
        2026,
        8,
        21,
        10,
        0,
        tzinfo=UTC,
    )

    created = service.create(
        user_id=user.id,
        session_type=AuthSessionType.WEB,
        now=created_at,
    )

    revoked = service.revoke_by_credential(
        created.credential,
        now=created_at + timedelta(hours=1),
    )

    assert revoked is True

    assert (
        service.resolve(
            created.credential,
            now=created_at + timedelta(hours=2),
        )
        is None
    )


def test_revoke_by_credential_returns_false_for_unknown_credential(
    db_session: Session,
) -> None:
    """Return False when the credential does not identify a session."""

    service = _create_service(db_session)

    result = service.revoke_by_credential(
        "unknown-credential",
    )

    assert result is False


def test_rotate_mobile_credential_replaces_previous_credential(
    db_session: Session,
) -> None:
    """Rotate a Mobile credential and invalidate the previous credential."""

    user = _create_user(db_session)
    service = _create_service(db_session)

    now = datetime(
        2026,
        8,
        21,
        10,
        0,
        tzinfo=UTC,
    )

    created = service.create(
        user_id=user.id,
        session_type=AuthSessionType.MOBILE,
        now=now,
    )

    original_credential = created.credential

    rotated = service.rotate_mobile_credential(
        original_credential,
        now=now + timedelta(hours=1),
    )

    assert rotated is not None
    assert rotated.session.id == created.session.id
    assert rotated.credential != original_credential

    assert (
        service.resolve(
            original_credential,
            now=now + timedelta(hours=2),
        )
        is None
    )

    assert (
        service.resolve(
            rotated.credential,
            now=now + timedelta(hours=2),
        )
        is not None
    )


def test_rotate_mobile_credential_rejects_web_session(
    db_session: Session,
) -> None:
    """Do not use Web session credentials as Mobile refresh credentials."""

    user = _create_user(db_session)
    service = _create_service(db_session)

    created = service.create(
        user_id=user.id,
        session_type=AuthSessionType.WEB,
    )

    rotated = service.rotate_mobile_credential(
        created.credential,
    )

    assert rotated is None


def test_revoke_for_user_revokes_owned_session(
    db_session: Session,
) -> None:
    """Revoke a session when it belongs to the requested user."""

    user = _create_user(
        db_session,
    )

    service = _create_service(
        db_session,
    )

    now = datetime(
        2026,
        8,
        21,
        10,
        0,
        tzinfo=UTC,
    )

    created = service.create(
        user_id=user.id,
        session_type=AuthSessionType.WEB,
        now=now,
    )

    revoked = service.revoke_for_user(
        session_id=created.session.id,
        user_id=user.id,
        now=now + timedelta(hours=1),
    )

    assert revoked is True

    assert (
        service.resolve(
            created.credential,
            now=now + timedelta(hours=2),
        )
        is None
    )


def test_revoke_for_user_does_not_revoke_other_users_session(
    db_session: Session,
) -> None:
    """Do not revoke a session belonging to another user."""

    user = _create_user(
        db_session,
        username="first-user",
    )

    other_user = _create_user(
        db_session,
        username="second-user",
    )

    service = _create_service(
        db_session,
    )

    now = datetime(
        2026,
        8,
        21,
        10,
        0,
        tzinfo=UTC,
    )

    created = service.create(
        user_id=other_user.id,
        session_type=AuthSessionType.WEB,
        now=now,
    )

    revoked = service.revoke_for_user(
        session_id=created.session.id,
        user_id=user.id,
        now=now + timedelta(hours=1),
    )

    assert revoked is False

    assert (
        service.resolve(
            created.credential,
            now=now + timedelta(hours=2),
        )
        is not None
    )


def test_revoke_for_user_returns_false_for_unknown_session(
    db_session: Session,
) -> None:
    """Return False when the requested session does not exist."""

    user = _create_user(
        db_session,
    )

    service = _create_service(
        db_session,
    )

    result = service.revoke_for_user(
        session_id=uuid4(),
        user_id=user.id,
    )

    assert result is False
