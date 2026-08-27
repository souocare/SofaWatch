from dataclasses import dataclass
from hashlib import sha256
from secrets import token_urlsafe

_SESSION_CREDENTIAL_BYTES = 32


@dataclass(frozen=True, slots=True)
class SessionCredential:
    """Newly generated opaque authentication session credential."""

    value: str
    hash: str


def generate_session_credential() -> SessionCredential:
    """Generate a cryptographically secure opaque session credential."""

    value = token_urlsafe(
        _SESSION_CREDENTIAL_BYTES,
    )

    return SessionCredential(
        value=value,
        hash=hash_session_credential(value),
    )


def hash_session_credential(
    credential: str,
) -> str:
    """Return the stable SHA-256 hash of an opaque session credential."""

    return sha256(
        credential.encode("utf-8"),
    ).hexdigest()
