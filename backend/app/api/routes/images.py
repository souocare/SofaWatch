"""Routes for serving cached SofaWatch images."""

from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Path, status
from fastapi.responses import FileResponse

from app.api.dependencies import ImageServiceDependency
from app.core.exceptions import APIError
from app.services.image import (
    ImageNotAvailableError,
    ImageOwnerNotFoundError,
)
from app.services.image_cache import ImageCacheError

router = APIRouter(
    prefix="/images",
    tags=["Images"],
)


@router.get(
    "/shows/{show_id}/poster",
    response_class=FileResponse,
    summary="Get TV series poster",
)
def get_show_poster(
    show_id: Annotated[
        UUID,
        Path(
            description="Internal TV series identifier.",
        ),
    ],
    service: ImageServiceDependency,
) -> FileResponse:
    """Return the cached poster for a TV series."""

    try:
        path = service.resolve_show_poster(
            show_id,
        )
    except ImageOwnerNotFoundError as error:
        raise APIError(
            status_code=status.HTTP_404_NOT_FOUND,
            code="show_not_found",
            message="TV series not found.",
        ) from error
    except ImageNotAvailableError as error:
        raise _image_not_found_error() from error
    except ImageCacheError as error:
        raise _image_cache_error() from error

    return FileResponse(
        path,
    )


@router.get(
    "/shows/{show_id}/backdrop",
    response_class=FileResponse,
    summary="Get TV series backdrop",
)
def get_show_backdrop(
    show_id: Annotated[
        UUID,
        Path(
            description="Internal TV series identifier.",
        ),
    ],
    service: ImageServiceDependency,
) -> FileResponse:
    """Return the cached backdrop for a TV series."""

    try:
        path = service.resolve_show_backdrop(
            show_id,
        )
    except ImageOwnerNotFoundError as error:
        raise APIError(
            status_code=status.HTTP_404_NOT_FOUND,
            code="show_not_found",
            message="TV series not found.",
        ) from error
    except ImageNotAvailableError as error:
        raise _image_not_found_error() from error
    except ImageCacheError as error:
        raise _image_cache_error() from error

    return FileResponse(
        path,
    )


@router.get(
    "/seasons/{season_id}/poster",
    response_class=FileResponse,
    summary="Get TV season poster",
)
def get_season_poster(
    season_id: Annotated[
        UUID,
        Path(
            description="Internal TV season identifier.",
        ),
    ],
    service: ImageServiceDependency,
) -> FileResponse:
    """Return the cached poster for a TV season."""

    try:
        path = service.resolve_season_poster(
            season_id,
        )
    except ImageOwnerNotFoundError as error:
        raise APIError(
            status_code=status.HTTP_404_NOT_FOUND,
            code="season_not_found",
            message="TV season not found.",
        ) from error
    except ImageNotAvailableError as error:
        raise _image_not_found_error() from error
    except ImageCacheError as error:
        raise _image_cache_error() from error

    return FileResponse(
        path,
    )


@router.get(
    "/episodes/{episode_id}/still",
    response_class=FileResponse,
    summary="Get TV episode still",
)
def get_episode_still(
    episode_id: Annotated[
        UUID,
        Path(
            description="Internal TV episode identifier.",
        ),
    ],
    service: ImageServiceDependency,
) -> FileResponse:
    """Return the cached still image for a TV episode."""

    try:
        path = service.resolve_episode_still(
            episode_id,
        )
    except ImageOwnerNotFoundError as error:
        raise APIError(
            status_code=status.HTTP_404_NOT_FOUND,
            code="episode_not_found",
            message="TV episode not found.",
        ) from error
    except ImageNotAvailableError as error:
        raise _image_not_found_error() from error
    except ImageCacheError as error:
        raise _image_cache_error() from error

    return FileResponse(
        path,
    )


def _image_not_found_error() -> APIError:
    """Build the standard missing-image API error."""

    return APIError(
        status_code=status.HTTP_404_NOT_FOUND,
        code="image_not_found",
        message="The requested image is not available.",
    )


def _image_cache_error() -> APIError:
    """Build the standard provider image failure."""

    return APIError(
        status_code=status.HTTP_502_BAD_GATEWAY,
        code="image_download_failed",
        message="The requested image could not be retrieved.",
    )
