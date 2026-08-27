from pwdlib import PasswordHash

_password_hash = PasswordHash.recommended()


def hash_password(password: str) -> str:
    """Hash a plaintext password using the configured secure password hasher."""

    return _password_hash.hash(password)


def verify_password(
    password: str,
    password_hash: str | None,
) -> bool:
    """Return whether a plaintext password matches the stored password hash."""

    if password_hash is None:
        return False

    return _password_hash.verify(
        password,
        password_hash,
    )
