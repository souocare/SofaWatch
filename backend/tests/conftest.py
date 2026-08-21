from collections.abc import Generator
from sqlite3 import Connection as SQLite3Connection

import pytest
from fastapi.testclient import TestClient
from pydantic import SecretStr
from sqlalchemy import create_engine, event, select
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool


import app.models  # noqa: F401
from app.core.config import Settings
from app.db.base import Base
from app.db.dependencies import get_db_session
from app.main import app
from app.api.dependencies import get_current_user
from app.models.user import User


TEST_DATABASE_URL = "sqlite://"


test_engine = create_engine(
    TEST_DATABASE_URL,
    connect_args={
        "check_same_thread": False,
    },
    poolclass=StaticPool,
)


@event.listens_for(test_engine, "connect")
def enable_sqlite_foreign_keys(
    dbapi_connection,
    _connection_record,
) -> None:
    """Enable foreign key enforcement for the SQLite test database."""

    if isinstance(
        dbapi_connection,
        SQLite3Connection,
    ):
        cursor = dbapi_connection.cursor()
        cursor.execute("PRAGMA foreign_keys=ON")
        cursor.close()


TestSessionLocal = sessionmaker(
    bind=test_engine,
    autocommit=False,
    autoflush=False,
    expire_on_commit=False,
)


@pytest.fixture
def settings() -> Settings:
    """Provide application settings suitable for tests."""

    return Settings.model_construct(
        app_name="SofaWatch Test",
        environment="test",
        debug=False,
        api_host="127.0.0.1",
        api_port=8000,
        database_url=TEST_DATABASE_URL,
        secret_key=SecretStr("test-secret-key"),
        default_language="en-US",
        supported_languages="en-US,pt-PT",
        tmdb_api_token=SecretStr("test-tmdb-token"),
        tmdb_base_url="https://api.themoviedb.org/3",
        tmdb_image_base_url="https://image.tmdb.org/t/p",
        tmdb_timeout_seconds=10.0,
        tvdb_api_key=None,
        tvdb_pin=None,
        tvdb_base_url="https://api4.thetvdb.com/v4",
        metadata_refresh_days=7,
    )


@pytest.fixture
def db_session() -> Generator[Session, None, None]:
    """Provide an isolated database session for a test."""

    Base.metadata.create_all(
        bind=test_engine,
    )

    with TestSessionLocal() as session:
        yield session

    Base.metadata.drop_all(
        bind=test_engine,
    )


@pytest.fixture
def client(
    db_session: Session,
) -> Generator[TestClient, None, None]:
    """Provide an authenticated test client using the test database.

    Route tests are authenticated by default so they can focus on their
    endpoint behaviour rather than access-token plumbing.

    Authentication itself is tested separately by the authentication and
    dependency test suites.
    """

    def override_get_db_session() -> Generator[Session, None, None]:
        yield db_session

    def override_get_current_user() -> User:
        # Preserve compatibility with route tests that explicitly create
        # the legacy local user as their current-user fixture.
        user = db_session.scalar(
            select(User)
            .where(User.is_local.is_(True))
            .limit(1)
        )

        if user is None:
            # Multi-user tests may create an authenticated user without
            # marking it as legacy/local. In those cases, use the first
            # explicitly-created user.
            user = db_session.scalar(
                select(User)
                .order_by(User.created_at)
                .limit(1)
            )

        if user is not None:
            return user

        # Most older route tests do not care about User persistence at all.
        # Lazily create an authenticated regular user only when a protected
        # endpoint actually resolves CurrentUserDependency.
        #
        # This is deliberately lazy so public bootstrap tests can still
        # observe a truly empty users table.
        user = User(
            display_name="Test User",
            is_active=True,
            is_local=False,
            is_admin=False,
        )

        db_session.add(user)
        db_session.flush()

        return user

    app.dependency_overrides[get_db_session] = override_get_db_session
    app.dependency_overrides[get_current_user] = override_get_current_user

    with TestClient(app) as test_client:
        yield test_client

    app.dependency_overrides.clear()



@pytest.fixture
def unauthenticated_client(
    db_session: Session,
) -> Generator[TestClient, None, None]:
    """Provide a test client without an authenticated current-user override."""

    def override_get_db_session() -> Generator[Session, None, None]:
        yield db_session

    app.dependency_overrides[get_db_session] = override_get_db_session

    with TestClient(app) as test_client:
        yield test_client

    app.dependency_overrides.clear()