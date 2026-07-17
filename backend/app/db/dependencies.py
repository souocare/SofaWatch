from collections.abc import Generator
from sqlalchemy.orm import Session
from app.db.session import SessionLocal


def get_db_session() -> Generator[Session, None, None]:
    """Provide a database session for a single request."""

    with SessionLocal() as session:
        yield session