from datetime import UTC, datetime, timedelta

import pytest
from sqlalchemy.orm import Session

from app.core.security.passwords import (
    hash_password,
    verify_password,
)
from app.models.auth_session import AuthSession, AuthSessionType
from app.models.user import User
from app.repositories.auth_session import AuthSessionRepository
from app.services.administrator_password_recovery import (
    AdministratorPasswordRecoveryService,
    AdministratorRecoveryUnavailableError,
)


def _create_service(
    db_session: Session,
) -> AdministratorPasswordRecoveryService:
    return AdministratorPasswordRecoveryService(
        session=db_session,
        auth_session_repository=AuthSessionRepository(db_session),
    )


def _create_admin(
    db_session: Session,
    *,
    is_active: bool = True,
) -> User:
    user = User(
        username="administrator",
        email="admin@example.com",
        display_name="Administrator",
        password_hash=hash_password("old-password"),
        is_active=is_active,
        is_local=True,
        is_admin=True,
    )

    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)

    return user


def test_reset_password_changes_administrator_password(
    db_session: Session,
) -> None:
    user = _create_admin(
        db_session,
    )

    service = _create_service(
        db_session,
    )

    service.reset_password(
        user=user,
        new_password="new-password",
    )

    assert verify_password(
        "new-password",
        user.password_hash,
    )

    assert not verify_password(
        "old-password",
        user.password_hash,
    )


def test_reset_password_revokes_existing_sessions(
    db_session: Session,
) -> None:
    user = _create_admin(
        db_session,
    )

    now = datetime(
        2026,
        8,
        26,
        10,
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

    service = _create_service(
        db_session,
    )

    service.reset_password(
        user=user,
        new_password="new-password",
        now=now,
    )

    db_session.refresh(auth_session)

    revoked_at = auth_session.revoked_at

    assert revoked_at is not None

    if revoked_at.tzinfo is None:
        revoked_at = revoked_at.replace(
            tzinfo=UTC,
        )

    assert revoked_at == now


def test_reset_password_preserves_already_revoked_sessions(
    db_session: Session,
) -> None:
    user = _create_admin(
        db_session,
    )

    previous_revocation = datetime(
        2026,
        8,
        25,
        12,
        0,
        tzinfo=UTC,
    )

    auth_session = AuthSession(
        user_id=user.id,
        session_type=AuthSessionType.WEB,
        credential_hash="b" * 64,
        expires_at=previous_revocation + timedelta(days=30),
        last_used_at=previous_revocation,
        revoked_at=previous_revocation,
    )

    db_session.add(auth_session)
    db_session.commit()

    service = _create_service(
        db_session,
    )

    service.reset_password(
        user=user,
        new_password="new-password",
        now=datetime(
            2026,
            8,
            26,
            10,
            tzinfo=UTC,
        ),
    )

    db_session.refresh(auth_session)

    revoked_at = auth_session.revoked_at

    assert revoked_at is not None

    if revoked_at.tzinfo is None:
        revoked_at = revoked_at.replace(
            tzinfo=UTC,
        )

    assert revoked_at == previous_revocation


def test_reset_password_rejects_regular_user(
    db_session: Session,
) -> None:
    user = User(
        username="regular-user",
        display_name="Regular User",
        password_hash=hash_password("old-password"),
        is_active=True,
        is_local=False,
        is_admin=False,
    )

    db_session.add(user)
    db_session.commit()

    service = _create_service(
        db_session,
    )

    with pytest.raises(
        AdministratorRecoveryUnavailableError,
    ):
        service.reset_password(
            user=user,
            new_password="new-password",
        )


def test_reset_password_rejects_inactive_administrator(
    db_session: Session,
) -> None:
    user = _create_admin(
        db_session,
        is_active=False,
    )

    service = _create_service(
        db_session,
    )

    with pytest.raises(
        AdministratorRecoveryUnavailableError,
    ):
        service.reset_password(
            user=user,
            new_password="new-password",
        )


@pytest.mark.parametrize(
    "password",
    [
        "short",
        "x" * 129,
    ],
)
def test_reset_password_rejects_invalid_password_length(
    db_session: Session,
    password: str,
) -> None:
    user = _create_admin(
        db_session,
    )

    service = _create_service(
        db_session,
    )

    with pytest.raises(
        ValueError,
    ):
        service.reset_password(
            user=user,
            new_password=password,
        )