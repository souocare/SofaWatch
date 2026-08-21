from fastapi import APIRouter, Depends

from app.api.dependencies import get_current_user
from app.api.routes.auth import router as auth_router
from app.api.routes.background_jobs import router as background_jobs_router
from app.api.routes.episodes import router as episodes_router
from app.api.routes.explore import router as explore_router
from app.api.routes.genres import router as genres_router
from app.api.routes.images import router as images_router
from app.api.routes.library import router as library_router
from app.api.routes.movies import router as movies_router
from app.api.routes.search import router as search_router
from app.api.routes.seasons import router as seasons_router
from app.api.routes.server import router as server_router
from app.api.routes.shows import router as shows_router
from app.api.routes.statistics import router as statistics_router
from app.api.routes.users import router as users_router


api_router = APIRouter(
    prefix="/api/v1",
)

private_router = APIRouter(
    dependencies=[
        Depends(get_current_user),
    ],
)

private_router.include_router(genres_router)
private_router.include_router(search_router)
private_router.include_router(shows_router)
private_router.include_router(seasons_router)
private_router.include_router(episodes_router)
private_router.include_router(library_router)
private_router.include_router(background_jobs_router)
private_router.include_router(images_router)
private_router.include_router(movies_router)
private_router.include_router(explore_router)
private_router.include_router(statistics_router)
private_router.include_router(users_router)
private_router.include_router(server_router)

api_router.include_router(private_router)

# Authentication/bootstrap endpoints must remain public.
api_router.include_router(auth_router)