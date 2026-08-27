from app.core.security.passwords import hash_password, verify_password


def test_hash_password_does_not_store_plaintext() -> None:
    password = "Correct-Horse-Battery-Staple-42"

    password_hash = hash_password(password)

    assert password_hash != password


def test_hash_password_uses_argon2() -> None:
    password_hash = hash_password(
        "Correct-Horse-Battery-Staple-42",
    )

    assert password_hash.startswith("$argon2")


def test_hash_password_uses_unique_salt() -> None:
    password = "Correct-Horse-Battery-Staple-42"

    first_hash = hash_password(password)
    second_hash = hash_password(password)

    assert first_hash != second_hash


def test_verify_password_accepts_matching_password() -> None:
    password = "Correct-Horse-Battery-Staple-42"
    password_hash = hash_password(password)

    assert (
        verify_password(
            password,
            password_hash,
        )
        is True
    )


def test_verify_password_rejects_wrong_password() -> None:
    password_hash = hash_password(
        "Correct-Horse-Battery-Staple-42",
    )

    assert (
        verify_password(
            "Wrong-Password",
            password_hash,
        )
        is False
    )


def test_verify_password_rejects_missing_hash() -> None:
    assert (
        verify_password(
            "Correct-Horse-Battery-Staple-42",
            None,
        )
        is False
    )
