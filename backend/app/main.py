import logging
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

# from backend.app.api.routes.genres import router as genres_router
from fastapi import FastAPI

from app.api.router import api_router
# from app.api.routes.search import router as search_router
from app.core.config import get_settings
from app.core.logging_config import configure_logging

configure_logging()

logger = logging.getLogger(__name__)
settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    logger.info("%s API starting", settings.app_name)

    yield

    logger.info("%s API stopping", settings.app_name)


app = FastAPI(
    title=f"{settings.app_name} API",
    description="Self-hosted API for tracking television shows and movies.",
    version="0.1.0",
    debug=settings.debug,
    lifespan=lifespan,
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
