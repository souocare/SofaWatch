from datetime import UTC, datetime, timedelta
from uuid import uuid4

import jwt
import pytest

from app.core.security.tokens import (
    AccessTokenService,
    InvalidAccessTokenError,
)


_SECRET_KEY = "test-secret-key-that-is-long-enough-for-tests"
_OTHER_SECRET_KEY = "another-test-secret-key-long-enough-here"


@pytest.fixture
def token_service() -> AccessTokenService:
    return AccessTokenService(
        secret_key=_SECRET_KEY,
        expire_minutes=15,
    )


def test_create_and_validate_access_token(
    token_service: AccessTokenService,
) -> None:
    user_id = uuid4()
    now = datetime.now(UTC)

    token = token_service.create(
        user_id=user_id,
        now=now,
    )

    claims = token_service.validate(token)

    assert claims.user_id == user_id
    assert claims.issued_at == now.replace(microsecond=0)
    assert claims.expires_at == (
        now + timedelta(minutes=15)
    ).replace(microsecond=0)


def test_access_token_contains_expected_claims(
    token_service: AccessTokenService,
) -> None:
    user_id = uuid4()
    now = datetime.now(UTC)

    token = token_service.create(
        user_id=user_id,
        now=now,
    )

    payload = jwt.decode(
        token,
        _SECRET_KEY,
        algorithms=["HS256"],
    )

    assert payload["sub"] == str(user_id)
    assert payload["type"] == "access"
    assert payload["iat"] == int(now.timestamp())
    assert payload["exp"] == int(
        (now + timedelta(minutes=15)).timestamp()
    )


def test_validate_rejects_expired_access_token() -> None:
    service = AccessTokenService(
        secret_key=_SECRET_KEY,
        expire_minutes=15,
    )

    token = service.create(
        user_id=uuid4(),
        now=datetime.now(UTC) - timedelta(hours=1),
    )

    with pytest.raises(InvalidAccessTokenError):
        service.validate(token)


def test_validate_rejects_token_signed_with_another_secret(
    token_service: AccessTokenService,
) -> None:
    other_service = AccessTokenService(
        secret_key=_OTHER_SECRET_KEY,
        expire_minutes=15,
    )

    token = other_service.create(
        user_id=uuid4(),
    )

    with pytest.raises(InvalidAccessTokenError):
        token_service.validate(token)


def test_validate_rejects_malformed_token(
    token_service: AccessTokenService,
) -> None:
    with pytest.raises(InvalidAccessTokenError):
        token_service.validate("not-a-jwt")


def test_validate_rejects_empty_token(
    token_service: AccessTokenService,
) -> None:
    with pytest.raises(InvalidAccessTokenError):
        token_service.validate("   ")


def test_validate_rejects_token_without_subject(
    token_service: AccessTokenService,
) -> None:
    now = datetime.now(UTC)

    token = jwt.encode(
        {
            "type": "access",
            "iat": now,
            "exp": now + timedelta(minutes=15),
        },
        _SECRET_KEY,
        algorithm="HS256",
    )

    with pytest.raises(InvalidAccessTokenError):
        token_service.validate(token)


def test_validate_rejects_invalid_subject_uuid(
    token_service: AccessTokenService,
) -> None:
    now = datetime.now(UTC)

    token = jwt.encode(
        {
            "sub": "not-a-uuid",
            "type": "access",
            "iat": now,
            "exp": now + timedelta(minutes=15),
        },
        _SECRET_KEY,
        algorithm="HS256",
    )

    with pytest.raises(InvalidAccessTokenError):
        token_service.validate(token)


def test_validate_rejects_non_access_token(
    token_service: AccessTokenService,
) -> None:
    now = datetime.now(UTC)

    token = jwt.encode(
        {
            "sub": str(uuid4()),
            "type": "refresh",
            "iat": now,
            "exp": now + timedelta(minutes=15),
        },
        _SECRET_KEY,
        algorithm="HS256",
    )

    with pytest.raises(InvalidAccessTokenError):
        token_service.validate(token)


def test_service_rejects_empty_secret_key() -> None:
    with pytest.raises(ValueError):
        AccessTokenService(
            secret_key="",
            expire_minutes=15,
        )


def test_service_rejects_non_positive_expiration() -> None:
    with pytest.raises(ValueError):
        AccessTokenService(
            secret_key=_SECRET_KEY,
            expire_minutes=0,
        )