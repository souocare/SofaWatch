from datetime import UTC, datetime, timedelta

from sqlalchemy.orm import Session

from app.core.security.passwords import (
    hash_password,
    verify_password,
)
from app.models.auth_session import (
    AuthSession,
    AuthSessionType,
)
from app.models.user import User
from app.repositories.auth_session import AuthSessionRepository
from app.repositories.password_reset_token import (
    PasswordResetTokenRepository,
)
from app.repositories.user import UserRepository
from app.services.password_recovery import (
    PasswordRecoveryInvalidError,
    PasswordRecoveryService,
)
from app.services.password_reset_token import (
    PasswordResetTokenService,
)


def _as_utc(
    value: datetime,
) -> datetime:
    if value.tzinfo is None:
        return value.replace(tzinfo=UTC)

    return value.astimezone(UTC)


def _create_user(
    db_session: Session,
    *,
    is_active: bool = True,
    is_admin: bool = False,
) -> User:
    user = User(
        username="regular-user",
        display_name="Regular User",
        password_hash=hash_password("old-password"),
        is_active=is_active,
        is_admin=is_admin,
    )

    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)

    return user


def _create_recovery_service(
    db_session: Session,
) -> PasswordRecoveryService:
    return PasswordRecoveryService(
        session=db_session,
        password_reset_token_repository=PasswordResetTokenRepository(
            db_session,
        ),
        user_repository=UserRepository(
            db_session,
        ),
        auth_session_repository=AuthSessionRepository(
            db_session,
        ),
    )


def _create_token(
    db_session: Session,
    *,
    user: User,
    now: datetime,
) -> str:
    service = PasswordResetTokenService(
        session=db_session,
        repository=PasswordResetTokenRepository(
            db_session,
        ),
    )

    return service.create(
        user_id=user.id,
        now=now,
    ).credential


def test_complete_password_recovery_changes_password(
    db_session: Session,
) -> None:
    user = _create_user(db_session)

    now = datetime(
        2026,
        8,
        26,
        9,
        0,
        tzinfo=UTC,
    )

    credential = _create_token(
        db_session,
        user=user,
        now=now,
    )

    service = _create_recovery_service(
        db_session,
    )

    service.complete(
        credential=credential,
        new_password="new-password",
        now=now + timedelta(minutes=5),
    )

    db_session.refresh(user)

    assert verify_password(
        "new-password",
        user.password_hash,
    )

    assert not verify_password(
        "old-password",
        user.password_hash,
    )


def test_complete_password_recovery_consumes_token(
    db_session: Session,
) -> None:
    user = _create_user(db_session)

    now = datetime(
        2026,
        8,
        26,
        9,
        0,
        tzinfo=UTC,
    )

    credential = _create_token(
        db_session,
        user=user,
        now=now,
    )

    service = _create_recovery_service(
        db_session,
    )

    service.complete(
        credential=credential,
        new_password="new-password",
        now=now + timedelta(minutes=5),
    )

    try:
        service.complete(
            credential=credential,
            new_password="another-password",
            now=now + timedelta(minutes=6),
        )
    except PasswordRecoveryInvalidError:
        pass
    else:
        raise AssertionError(
            "Expected an already-used password recovery token "
            "to be rejected."
        )


def test_complete_password_recovery_rejects_expired_token(
    db_session: Session,
) -> None:
    user = _create_user(db_session)

    now = datetime(
        2026,
        8,
        26,
        9,
        0,
        tzinfo=UTC,
    )

    credential = _create_token(
        db_session,
        user=user,
        now=now,
    )

    service = _create_recovery_service(
        db_session,
    )

    try:
        service.complete(
            credential=credential,
            new_password="new-password",
            now=now + timedelta(minutes=31),
        )
    except PasswordRecoveryInvalidError:
        pass
    else:
        raise AssertionError(
            "Expected an expired password recovery token "
            "to be rejected."
        )

    db_session.refresh(user)

    assert verify_password(
        "old-password",
        user.password_hash,
    )


def test_complete_password_recovery_rejects_invalid_token(
    db_session: Session,
) -> None:
    service = _create_recovery_service(
        db_session,
    )

    try:
        service.complete(
            credential="invalid-token",
            new_password="new-password",
        )
    except PasswordRecoveryInvalidError:
        pass
    else:
        raise AssertionError(
            "Expected an invalid password recovery token "
            "to be rejected."
        )


def test_complete_password_recovery_revokes_existing_sessions(
    db_session: Session,
) -> None:
    user = _create_user(db_session)

    now = datetime(
        2026,
        8,
        26,
        9,
        0,
        tzinfo=UTC,
    )

    auth_session = AuthSession(
        user_id=user.id,
        session_type=AuthSessionType.WEB,
        credential_hash="a" * 64,
        expires_at=now + timedelta(days=30),
        last_used_at=now,
    )

    db_session.add(auth_session)
    db_session.commit()
    db_session.refresh(auth_session)

    credential = _create_token(
        db_session,
        user=user,
        now=now,
    )

    service = _create_recovery_service(
        db_session,
    )

    completed_at = now + timedelta(minutes=5)

    service.complete(
        credential=credential,
        new_password="new-password",
        now=completed_at,
    )

    db_session.refresh(auth_session)

    assert auth_session.revoked_at is not None

    assert _as_utc(auth_session.revoked_at) == completed_at


def test_complete_password_recovery_rejects_inactive_user(
    db_session: Session,
) -> None:
    user = _create_user(
        db_session,
        is_active=False,
    )

    now = datetime(
        2026,
        8,
        26,
        9,
        0,
        tzinfo=UTC,
    )

    credential = _create_token(
        db_session,
        user=user,
        now=now,
    )

    service = _create_recovery_service(
        db_session,
    )

    try:
        service.complete(
            credential=credential,
            new_password="new-password",
            now=now + timedelta(minutes=5),
        )
    except PasswordRecoveryInvalidError:
        pass
    else:
        raise AssertionError(
            "Expected password recovery for an inactive user "
            "to be rejected."
        )

    db_session.refresh(user)

    assert verify_password(
        "old-password",
        user.password_hash,
    )


def test_complete_password_recovery_rejects_administrator(
    db_session: Session,
) -> None:
    user = _create_user(
        db_session,
        is_admin=True,
    )

    now = datetime(
        2026,
        8,
        26,
        9,
        0,
        tzinfo=UTC,
    )

    credential = _create_token(
        db_session,
        user=user,
        now=now,
    )

    service = _create_recovery_service(
        db_session,
    )

    try:
        service.complete(
            credential=credential,
            new_password="new-password",
            now=now + timedelta(minutes=5),
        )
    except PasswordRecoveryInvalidError:
        pass
    else:
        raise AssertionError(
            "Expected Web password recovery for an administrator "
            "to be rejected."
        )