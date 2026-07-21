from collections.abc import Generator

import pytest
from fastapi.testclient import TestClient
from pydantic import SecretStr
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool

import app.models  # noqa: F401
from app.core.config import Settings
from app.db.base import Base
from app.db.dependencies import get_db_session
from app.main import app

TEST_DATABASE_URL = "sqlite://"


test_engine = create_engine(
    TEST_DATABASE_URL,
    connect_args={
        "check_same_thread": False,
    },
    poolclass=StaticPool,
)


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
    )


@pytest.fixture
def db_session() -> Generator[Session, None, None]:
    """Provide an isolated database session for a test."""

    Base.metadata.create_all(bind=test_engine)

    with TestSessionLocal() as session:
        yield session

    Base.metadata.drop_all(bind=test_engine)


@pytest.fixture
def client(
    db_session: Session,
) -> Generator[TestClient, None, None]:
    """Provide a test client using the test database."""

    def override_get_db_session() -> Generator[Session, None, None]:
        yield db_session

    app.dependency_overrides[get_db_session] = override_get_db_session

    with TestClient(app) as test_client:
        yield test_client

    app.dependency_overrides.clear()
