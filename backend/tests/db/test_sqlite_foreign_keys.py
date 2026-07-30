from sqlalchemy import text
from sqlalchemy.orm import Session


def test_sqlite_foreign_keys_are_enabled(
    db_session: Session,
) -> None:
    """Ensure SQLite enforces foreign key constraints."""

    enabled = db_session.scalar(
        text("PRAGMA foreign_keys")
    )

    assert enabled == 1