from datetime import UTC, datetime, timedelta

from sqlalchemy.orm import Session

from app.core.security.session_credentials import (
    hash_session_credential,
)
from app.models.password_reset_token import PasswordResetToken
from app.models.user import User
from app.repositories.password_reset_token import (
    PasswordResetTokenRepository,
)
from app.services.password_reset_token import (
    PasswordResetTokenService,
)


def _create_user(
    db_session: Session,
) -> User:
    user = User(
        username="regular-user",
        display_name="Regular User",
        is_active=True,
        is_local=False,
        is_admin=False,
    )

    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)

    return user


def test_create_password_reset_token(
    db_session: Session,
) -> None:
    user = _create_user(db_session)

    service = PasswordResetTokenService(
        session=db_session,
        repository=PasswordResetTokenRepository(db_session),
    )

    now = datetime(
        2026,
        8,
        26,
        8,
        30,
        tzinfo=UTC,
    )

    created = service.create(
        user_id=user.id,
        now=now,
    )

    assert created.credential
    assert created.reset_token.user_id == user.id
    assert created.reset_token.used_at is None
    assert created.reset_token.expires_at == (
        now + timedelta(minutes=30)
    )


def test_create_password_reset_token_stores_only_hash(
    db_session: Session,
) -> None:
    user = _create_user(db_session)

    service = PasswordResetTokenService(
        session=db_session,
        repository=PasswordResetTokenRepository(db_session),
    )

    created = service.create(
        user_id=user.id,
    )

    stored = db_session.query(
        PasswordResetToken,
    ).one()

    assert stored.credential_hash == hash_session_credential(
        created.credential,
    )

    assert stored.credential_hash != created.credential


def test_consume_password_reset_token(
    db_session: Session,
) -> None:
    user = _create_user(db_session)

    service = PasswordResetTokenService(
        session=db_session,
        repository=PasswordResetTokenRepository(db_session),
    )

    now = datetime(
        2026,
        8,
        26,
        8,
        30,
        tzinfo=UTC,
    )

    created = service.create(
        user_id=user.id,
        now=now,
    )

    consumed = service.consume(
        created.credential,
        now=now + timedelta(minutes=5),
    )

    assert consumed is not None
    assert consumed.id == created.reset_token.id
    assert consumed.user_id == user.id
    assert consumed.used_at == now + timedelta(minutes=5)


def test_password_reset_token_can_only_be_consumed_once(
    db_session: Session,
) -> None:
    user = _create_user(db_session)

    service = PasswordResetTokenService(
        session=db_session,
        repository=PasswordResetTokenRepository(db_session),
    )

    now = datetime(
        2026,
        8,
        26,
        8,
        30,
        tzinfo=UTC,
    )

    created = service.create(
        user_id=user.id,
        now=now,
    )

    first = service.consume(
        created.credential,
        now=now + timedelta(minutes=1),
    )

    second = service.consume(
        created.credential,
        now=now + timedelta(minutes=2),
    )

    assert first is not None
    assert second is None


def test_expired_password_reset_token_cannot_be_consumed(
    db_session: Session,
) -> None:
    user = _create_user(db_session)

    service = PasswordResetTokenService(
        session=db_session,
        repository=PasswordResetTokenRepository(db_session),
    )

    now = datetime(
        2026,
        8,
        26,
        8,
        30,
        tzinfo=UTC,
    )

    created = service.create(
        user_id=user.id,
        now=now,
    )

    consumed = service.consume(
        created.credential,
        now=now + timedelta(minutes=31),
    )

    assert consumed is None


def test_password_reset_token_expiring_exactly_now_is_invalid(
    db_session: Session,
) -> None:
    user = _create_user(db_session)

    service = PasswordResetTokenService(
        session=db_session,
        repository=PasswordResetTokenRepository(db_session),
    )

    now = datetime(
        2026,
        8,
        26,
        8,
        30,
        tzinfo=UTC,
    )

    created = service.create(
        user_id=user.id,
        now=now,
    )

    consumed = service.consume(
        created.credential,
        now=now + timedelta(minutes=30),
    )

    assert consumed is None


def test_invalid_password_reset_token_returns_none(
    db_session: Session,
) -> None:
    service = PasswordResetTokenService(
        session=db_session,
        repository=PasswordResetTokenRepository(db_session),
    )

    assert service.consume("not-a-real-token") is None
    assert service.consume("   ") is None


def test_password_reset_expiration_must_be_positive(
    db_session: Session,
) -> None:
    repository = PasswordResetTokenRepository(
        db_session,
    )

    try:
        PasswordResetTokenService(
            session=db_session,
            repository=repository,
            expiration=timedelta(0),
        )
    except ValueError as error:
        assert str(error) == (
            "Password reset token expiration must be positive."
        )
    else:
        raise AssertionError(
            "Expected PasswordResetTokenService to reject "
            "a non-positive expiration."
        )