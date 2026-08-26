from uuid import uuid4

from sqlalchemy.orm import Session

from app.models.user import User
from app.repositories.user import UserRepository


def make_user(
    *,
    display_name: str = "Local User",
) -> User:
    """Create a user for repository tests."""

    return User(
        display_name=display_name,
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




def test_get_by_username_returns_user(
    db_session,
) -> None:
    user = User(
        username="souocare",
        email="goncalo@example.com",
        display_name="Gonçalo",
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


def test_exists_any_returns_false_when_no_users_exist(
    db_session,
) -> None:
    repository = UserRepository(db_session)

    assert repository.exists_any() is False


def test_exists_any_returns_true_when_user_exists(
    db_session,
) -> None:
    user = User(
        username="souocare",
        display_name="Gonçalo",
    )

    db_session.add(user)
    db_session.commit()

    repository = UserRepository(db_session)

    assert repository.exists_any() is True


def test_list_all_returns_users_ordered_by_display_name(
    db_session: Session,
) -> None:
    repository = UserRepository(db_session)

    charlie = User(
        username="charlie",
        display_name="Charlie",
    )

    alice = User(
        username="alice",
        display_name="Alice",
    )

    bob = User(
        username="bob",
        display_name="Bob",
    )

    db_session.add_all(
        [
            charlie,
            alice,
            bob,
        ]
    )
    db_session.commit()

    result = repository.list_all()

    assert [
        user.display_name
        for user in result
    ] == [
        "Alice",
        "Bob",
        "Charlie",
    ]


def test_list_all_returns_empty_list_when_no_users_exist(
    db_session: Session,
) -> None:
    repository = UserRepository(db_session)

    assert repository.list_all() == []


