from fastapi import APIRouter

from app.api.routes.background_jobs import router as background_jobs_router
from app.api.routes.episodes import router as episodes_router
from app.api.routes.genres import router as genres_router
from app.api.routes.library import router as library_router
from app.api.routes.search import router as search_router
from app.api.routes.seasons import router as seasons_router
from app.api.routes.shows import router as shows_router

api_router = APIRouter(
    prefix="/api/v1",
)

api_router.include_router(genres_router)
api_router.include_router(search_router)
api_router.include_router(shows_router)
api_router.include_router(seasons_router)
api_router.include_router(episodes_router)
api_router.include_router(library_router)
api_router.include_router(background_jobs_router)
