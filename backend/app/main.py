import logging
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from datetime import UTC, datetime

from fastapi import FastAPI

from app.api.router import api_router

# from app.api.routes.search import router as search_router
from app.core.config import get_settings
from app.core.logging_config import configure_logging
from app.db.session import SessionLocal

# from backend.app.api.routes.genres import router as genres_router
from app.repositories.user import UserRepository
from app.services.local_user import LocalUserService
from fastapi.middleware.cors import CORSMiddleware
from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException as StarletteHTTPException

from app.api.error_handlers import (
    api_error_handler,
    http_exception_handler,
    validation_exception_handler,
)
from app.core.exceptions import APIError

configure_logging()

logger = logging.getLogger(__name__)
settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    app.state.started_at = datetime.now(UTC)

    logger.info("%s API starting", settings.app_name)

    with SessionLocal() as session:
        LocalUserService(
            session=session,
            user_repository=UserRepository(session),
        ).get_or_create()

    yield

    logger.info("%s API stopping", settings.app_name)


app = FastAPI(
    title=f"{settings.app_name} API",
    description="Self-hosted API for tracking television shows and movies.",
    version="0.1.0",
    debug=settings.debug,
    lifespan=lifespan,
)

cors_kwargs: dict[str, object] = {
    "allow_credentials": True,
    "allow_methods": ["*"],
    "allow_headers": ["*"],
}
if settings.is_development:
    cors_kwargs["allow_origin_regex"] = r"^http://(localhost|127\.0\.0\.1):\d+$"
else:
    cors_kwargs["allow_origins"] = settings.cors_origin_list
app.add_middleware(
    CORSMiddleware,
    **cors_kwargs,
)

app.add_exception_handler(
    APIError,
    api_error_handler,
)

app.add_exception_handler(
    StarletteHTTPException,
    http_exception_handler,
)

app.add_exception_handler(
    RequestValidationError,
    validation_exception_handler,
)

# app.include_router(genres_router)
# app.include_router(search_router)
app.include_router(api_router)


@app.get("/")
async def root() -> dict[str, str]:
    return {
        "name": f"{settings.app_name} API",
        "environment": settings.environment,
        "status": "running",
    }


@app.get("/api/v1/health")
async def health_check() -> dict[str, str | bool]:
    return {
        "status": "healthy",
        "debug": settings.debug,
    }
