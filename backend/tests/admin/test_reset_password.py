from __future__ import annotations

from contextlib import nullcontext

import pytest

from app.admin import reset_password
from app.models.user import User


class _FakeSession:
    pass


class _FakeUserRepository:
    def __init__(
        self,
        session,
        *,
        user: User | None = None,
    ) -> None:
        del session
        self._user = user

    def get_by_username(
        self,
        username: str,
    ) -> User | None:
        del username
        return self._user

    def get_by_email(
        self,
        email: str,
    ) -> User | None:
        del email
        return self._user


class _RecordingRecoveryService:
    def __init__(
        self,
        *,
        session,
        auth_session_repository,
    ) -> None:
        del session
        del auth_session_repository

        self.user: User | None = None
        self.new_password: str | None = None

    def reset_password(
        self,
        *,
        user: User,
        new_password: str,
    ) -> User:
        self.user = user
        self.new_password = new_password

        return user


def _admin_user(
    *,
    username: str = "administrator",
    email: str | None = "admin@example.com",
    is_active: bool = True,
) -> User:
    return User(
        username=username,
        email=email,
        display_name="Administrator",
        is_active=is_active,
        is_admin=True,
    )


def _regular_user() -> User:
    return User(
        username="regular-user",
        display_name="Regular User",
        is_active=True,
        is_admin=False,
    )


def _install_common_fakes(
    monkeypatch: pytest.MonkeyPatch,
    *,
    user: User | None,
) -> _RecordingRecoveryService:
    fake_session = _FakeSession()

    monkeypatch.setattr(
        reset_password,
        "SessionLocal",
        lambda: nullcontext(fake_session),
    )

    monkeypatch.setattr(
        reset_password,
        "UserRepository",
        lambda session: _FakeUserRepository(
            session,
            user=user,
        ),
    )

    monkeypatch.setattr(
        reset_password,
        "AuthSessionRepository",
        lambda session: object(),
    )

    recording_service = _RecordingRecoveryService(
        session=fake_session,
        auth_session_repository=object(),
    )

    monkeypatch.setattr(
        reset_password,
        "AdministratorPasswordRecoveryService",
        lambda **kwargs: recording_service,
    )

    return recording_service


def test_reset_password_accepts_administrator_username(
    monkeypatch: pytest.MonkeyPatch,
    capsys: pytest.CaptureFixture[str],
) -> None:
    user = _admin_user()

    service = _install_common_fakes(
        monkeypatch,
        user=user,
    )

    monkeypatch.setattr(
        reset_password.sys,
        "argv",
        [
            "reset_password",
            "administrator",
        ],
    )

    passwords = iter(
        [
            "new-password",
            "new-password",
        ]
    )

    monkeypatch.setattr(
        reset_password.getpass,
        "getpass",
        lambda prompt: next(passwords),
    )

    reset_password.main()

    assert service.user is user
    assert service.new_password == "new-password"

    output = capsys.readouterr().out

    assert "Administrator password updated successfully." in output
    assert "Existing sessions have been revoked." in output


def test_reset_password_accepts_administrator_email(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    user = _admin_user()

    service = _install_common_fakes(
        monkeypatch,
        user=user,
    )

    monkeypatch.setattr(
        reset_password.sys,
        "argv",
        [
            "reset_password",
            "ADMIN@EXAMPLE.COM",
        ],
    )

    passwords = iter(
        [
            "new-password",
            "new-password",
        ]
    )

    monkeypatch.setattr(
        reset_password.getpass,
        "getpass",
        lambda prompt: next(passwords),
    )

    reset_password.main()

    assert service.user is user
    assert service.new_password == "new-password"


def test_reset_password_rejects_missing_identifier(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    monkeypatch.setattr(
        reset_password.sys,
        "argv",
        [
            "reset_password",
        ],
    )

    with pytest.raises(
        SystemExit,
        match="Usage:",
    ):
        reset_password.main()


def test_reset_password_rejects_password_argument(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    monkeypatch.setattr(
        reset_password.sys,
        "argv",
        [
            "reset_password",
            "administrator",
            "plaintext-password",
        ],
    )

    with pytest.raises(
        SystemExit,
        match="Usage:",
    ):
        reset_password.main()


def test_reset_password_rejects_missing_administrator(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    _install_common_fakes(
        monkeypatch,
        user=None,
    )

    monkeypatch.setattr(
        reset_password.sys,
        "argv",
        [
            "reset_password",
            "missing",
        ],
    )

    with pytest.raises(
        SystemExit,
        match="Administrator account could not be found.",
    ):
        reset_password.main()


def test_reset_password_rejects_regular_user(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    _install_common_fakes(
        monkeypatch,
        user=_regular_user(),
    )

    monkeypatch.setattr(
        reset_password.sys,
        "argv",
        [
            "reset_password",
            "regular-user",
        ],
    )

    with pytest.raises(
        SystemExit,
        match="Password recovery is only available for administrators.",
    ):
        reset_password.main()


def test_reset_password_rejects_inactive_administrator(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    _install_common_fakes(
        monkeypatch,
        user=_admin_user(
            is_active=False,
        ),
    )

    monkeypatch.setattr(
        reset_password.sys,
        "argv",
        [
            "reset_password",
            "administrator",
        ],
    )

    with pytest.raises(
        SystemExit,
        match="Password recovery is unavailable for an inactive administrator.",
    ):
        reset_password.main()


def test_reset_password_rejects_mismatched_passwords(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    _install_common_fakes(
        monkeypatch,
        user=_admin_user(),
    )

    monkeypatch.setattr(
        reset_password.sys,
        "argv",
        [
            "reset_password",
            "administrator",
        ],
    )

    passwords = iter(
        [
            "new-password",
            "different-password",
        ]
    )

    monkeypatch.setattr(
        reset_password.getpass,
        "getpass",
        lambda prompt: next(passwords),
    )

    with pytest.raises(
        SystemExit,
        match="Passwords do not match.",
    ):
        reset_password.main()


def test_reset_password_rejects_short_password(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    _install_common_fakes(
        monkeypatch,
        user=_admin_user(),
    )

    monkeypatch.setattr(
        reset_password.sys,
        "argv",
        [
            "reset_password",
            "administrator",
        ],
    )

    passwords = iter(
        [
            "short",
            "short",
        ]
    )

    monkeypatch.setattr(
        reset_password.getpass,
        "getpass",
        lambda prompt: next(passwords),
    )

    with pytest.raises(
        SystemExit,
        match="Password must be at least 8 characters.",
    ):
        reset_password.main()


def test_reset_password_rejects_long_password(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    _install_common_fakes(
        monkeypatch,
        user=_admin_user(),
    )

    monkeypatch.setattr(
        reset_password.sys,
        "argv",
        [
            "reset_password",
            "administrator",
        ],
    )

    password = "x" * 129

    passwords = iter(
        [
            password,
            password,
        ]
    )

    monkeypatch.setattr(
        reset_password.getpass,
        "getpass",
        lambda prompt: next(passwords),
    )

    with pytest.raises(
        SystemExit,
        match="Password must be 128 characters or fewer.",
    ):
        reset_password.main()


def test_reset_password_does_not_expose_password_in_output(
    monkeypatch: pytest.MonkeyPatch,
    capsys: pytest.CaptureFixture[str],
) -> None:
    _install_common_fakes(
        monkeypatch,
        user=_admin_user(),
    )

    monkeypatch.setattr(
        reset_password.sys,
        "argv",
        [
            "reset_password",
            "administrator",
        ],
    )

    secret_password = "very-secret-password"

    passwords = iter(
        [
            secret_password,
            secret_password,
        ]
    )

    prompts: list[str] = []

    def fake_getpass(
        prompt: str,
    ) -> str:
        prompts.append(prompt)

        return next(passwords)

    monkeypatch.setattr(
        reset_password.getpass,
        "getpass",
        fake_getpass,
    )

    reset_password.main()

    captured = capsys.readouterr()

    assert secret_password not in captured.out
    assert secret_password not in captured.err

    assert prompts == [
        "New password: ",
        "Confirm new password: ",
    ]


def test_reset_password_never_accepts_password_from_argv(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    secret_password = "very-secret-password"

    monkeypatch.setattr(
        reset_password.sys,
        "argv",
        [
            "reset_password",
            "administrator",
            secret_password,
        ],
    )

    getpass_called = False

    def fake_getpass(
        prompt: str,
    ) -> str:
        del prompt

        nonlocal getpass_called
        getpass_called = True

        return secret_password

    monkeypatch.setattr(
        reset_password.getpass,
        "getpass",
        fake_getpass,
    )

    with pytest.raises(
        SystemExit,
        match="Usage:",
    ):
        reset_password.main()

    assert getpass_called is False
