from datetime import UTC, datetime, timedelta

import pytest
from sqlalchemy.orm import Session

from app.models.user import User
from app.repositories.auth_handoff import AuthHandoffRepository
from app.services.auth_handoff import AuthHandoffService


@pytest.fixture
def user(
    db_session: Session,
) -> User:
    user = User(
        username="souocare",
        display_name="Gonçalo",
        is_active=True,
    )

    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)

    return user


@pytest.fixture
def service(
    db_session: Session,
) -> AuthHandoffService:
    return AuthHandoffService(
        session=db_session,
        repository=AuthHandoffRepository(db_session),
    )


def test_create_returns_plaintext_credential_without_storing_it(
    service: AuthHandoffService,
    user: User,
) -> None:
    created = service.create(
        user_id=user.id,
        now=datetime(2026, 8, 24, 10, 0, tzinfo=UTC),
    )

    assert created.credential
    assert created.handoff.user_id == user.id

    assert created.handoff.credential_hash != created.credential


def test_create_uses_short_expiration(
    service: AuthHandoffService,
    user: User,
) -> None:
    now = datetime(2026, 8, 24, 10, 0, tzinfo=UTC)

    created = service.create(
        user_id=user.id,
        now=now,
    )

    assert created.handoff.expires_at == now + timedelta(minutes=2)


def test_consume_returns_valid_handoff(
    service: AuthHandoffService,
    user: User,
) -> None:
    now = datetime(2026, 8, 24, 10, 0, tzinfo=UTC)

    created = service.create(
        user_id=user.id,
        now=now,
    )

    consumed = service.consume(
        created.credential,
        now=now + timedelta(seconds=30),
    )

    assert consumed is not None
    assert consumed.id == created.handoff.id
    assert consumed.used_at is not None


def test_consume_rejects_second_use(
    service: AuthHandoffService,
    user: User,
) -> None:
    now = datetime(2026, 8, 24, 10, 0, tzinfo=UTC)

    created = service.create(
        user_id=user.id,
        now=now,
    )

    first = service.consume(
        created.credential,
        now=now + timedelta(seconds=10),
    )

    second = service.consume(
        created.credential,
        now=now + timedelta(seconds=20),
    )

    assert first is not None
    assert second is None


def test_consume_rejects_expired_handoff(
    service: AuthHandoffService,
    user: User,
) -> None:
    now = datetime(2026, 8, 24, 10, 0, tzinfo=UTC)

    created = service.create(
        user_id=user.id,
        now=now,
    )

    result = service.consume(
        created.credential,
        now=now + timedelta(minutes=2),
    )

    assert result is None


def test_consume_rejects_unknown_credential(
    service: AuthHandoffService,
) -> None:
    result = service.consume(
        "unknown-handoff-credential",
    )

    assert result is None


def test_consume_rejects_blank_credential(
    service: AuthHandoffService,
) -> None:
    result = service.consume("   ")

    assert result is None


def test_rejects_non_positive_expiration(
    db_session: Session,
) -> None:
    with pytest.raises(
        ValueError,
        match="Authentication handoff expiration must be positive",
    ):
        AuthHandoffService(
            session=db_session,
            repository=AuthHandoffRepository(db_session),
            expiration=timedelta(0),
        )


def test_exposes_configured_expiration(
    db_session: Session,
) -> None:
    service = AuthHandoffService(
        session=db_session,
        repository=AuthHandoffRepository(db_session),
        expiration=timedelta(seconds=45),
    )

    assert service.expiration == timedelta(seconds=45)