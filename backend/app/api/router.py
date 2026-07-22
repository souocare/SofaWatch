from fastapi import APIRouter

from app.api.routes.genres import router as genres_router
from app.api.routes.search import router as search_router
from app.api.routes.shows import router as shows_router

api_router = APIRouter()

api_router.include_router(genres_router)
api_router.include_router(search_router)
api_router.include_router(shows_router)
