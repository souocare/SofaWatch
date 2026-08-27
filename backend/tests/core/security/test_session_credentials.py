from app.core.security.session_credentials import (
    generate_session_credential,
    hash_session_credential,
)


def test_generate_session_credential_returns_value_and_hash() -> None:
    """Generate an opaque credential together with its hash."""

    credential = generate_session_credential()

    assert credential.value
    assert credential.hash == hash_session_credential(
        credential.value,
    )
    assert credential.hash != credential.value


def test_generate_session_credential_returns_unique_values() -> None:
    """Generate a different credential for each session."""

    first = generate_session_credential()
    second = generate_session_credential()

    assert first.value != second.value
    assert first.hash != second.hash


def test_hash_session_credential_is_deterministic() -> None:
    """Return the same hash for the same credential."""

    credential = "test-session-credential"

    assert hash_session_credential(
        credential,
    ) == hash_session_credential(
        credential,
    )
