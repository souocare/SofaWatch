from sqlalchemy.orm import Session

from app.models.user import User
from app.repositories.user import UserRepository
from app.services.local_user import LocalUserService


def test_get_or_create_returns_existing_local_user(
    db_session: Session,
) -> None:
    """Return the existing local user without creating another one."""

    existing_user = User(
        display_name="Existing Local User",
        is_local=True,
    )

    db_session.add(existing_user)
    db_session.commit()
    db_session.refresh(existing_user)

    repository = UserRepository(db_session)

    service = LocalUserService(
        session=db_session,
        user_repository=repository,
    )

    result = service.get_or_create()

    assert result.id == existing_user.id
    assert result.display_name == "Existing Local User"
    assert result.is_local is True


def test_get_or_create_creates_local_user_when_missing(
    db_session: Session,
) -> None:
    """Create the local user when none exists."""

    repository = UserRepository(db_session)

    service = LocalUserService(
        session=db_session,
        user_repository=repository,
    )

    result = service.get_or_create()

    assert result.id is not None
    assert result.display_name == "Local User"
    assert result.is_local is True

    stored_user = repository.get_local()

    assert stored_user is not None
    assert stored_user.id == result.id


def test_get_or_create_is_idempotent(
    db_session: Session,
) -> None:
    """Reuse the same local user across repeated calls."""

    repository = UserRepository(db_session)

    service = LocalUserService(
        session=db_session,
        user_repository=repository,
    )

    first_user = service.get_or_create()
    second_user = service.get_or_create()

    assert first_user.id == second_user.id

    users = db_session.query(User).all()

    assert len(users) == 1
