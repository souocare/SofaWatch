from uuid import uuid4

from sqlalchemy.orm import Session

from app.models.user import User
from app.repositories.user import UserRepository


def make_user(
    *,
    display_name: str = "Local User",
    is_local: bool = True,
) -> User:
    """Create a user for repository tests."""

    return User(
        display_name=display_name,
        is_local=is_local,
    )


def test_add_persists_user(
    db_session: Session,
) -> None:
    """Persist a user added through the repository."""

    repository = UserRepository(db_session)

    user = make_user()

    repository.add(user)

    db_session.commit()
    db_session.refresh(user)

    assert user.id is not None
    assert user.display_name == "Local User"
    assert user.is_local is True


def test_get_by_id_returns_user(
    db_session: Session,
) -> None:
    """Return a user by its internal identifier."""

    user = make_user()

    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)

    repository = UserRepository(db_session)

    result = repository.get_by_id(user.id)

    assert result is not None
    assert result.id == user.id
    assert result.display_name == "Local User"


def test_get_by_id_returns_none_when_missing(
    db_session: Session,
) -> None:
    """Return None when the user identifier does not exist."""

    repository = UserRepository(db_session)

    result = repository.get_by_id(uuid4())

    assert result is None


def test_get_local_returns_local_user(
    db_session: Session,
) -> None:
    """Return the locally configured SofaWatch user."""

    local_user = make_user(
        display_name="Local User",
        is_local=True,
    )

    other_user = make_user(
        display_name="Other User",
        is_local=False,
    )

    db_session.add_all(
        [
            local_user,
            other_user,
        ]
    )
    db_session.commit()

    repository = UserRepository(db_session)

    result = repository.get_local()

    assert result is not None
    assert result.id == local_user.id
    assert result.is_local is True


def test_get_local_returns_none_when_missing(
    db_session: Session,
) -> None:
    """Return None when no local user exists."""

    db_session.add(
        make_user(
            display_name="Other User",
            is_local=False,
        )
    )
    db_session.commit()

    repository = UserRepository(db_session)

    result = repository.get_local()

    assert result is None

def test_get_by_username_returns_user(
    db_session,
) -> None:
    user = User(
        username="souocare",
        email="goncalo@example.com",
        display_name="Gonçalo",
        is_local=False,
    )

    db_session.add(user)
    db_session.commit()

    repository = UserRepository(db_session)

    result = repository.get_by_username("souocare")

    assert result is not None
    assert result.id == user.id
    assert result.username == "souocare"


def test_get_by_username_returns_none_when_missing(
    db_session,
) -> None:
    repository = UserRepository(db_session)

    assert repository.get_by_username("missing") is None


def test_get_by_email_returns_user(
    db_session,
) -> None:
    user = User(
        username="souocare",
        email="goncalo@example.com",
        display_name="Gonçalo",
        is_local=False,
    )

    db_session.add(user)
    db_session.commit()

    repository = UserRepository(db_session)

    result = repository.get_by_email("goncalo@example.com")

    assert result is not None
    assert result.id == user.id
    assert result.email == "goncalo@example.com"


def test_get_by_email_returns_none_when_missing(
    db_session,
) -> None:
    repository = UserRepository(db_session)

    assert repository.get_by_email("missing@example.com") is None