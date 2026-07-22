import logging
from collections.abc import Mapping
from typing import Any, TypeVar

import httpx
from pydantic import BaseModel, ValidationError

from app.core.config import Settings
from app.providers.tmdb.exceptions import (
    TMDBConfigurationError,
    TMDBNotFoundError,
    TMDBRequestError,
    TMDBResponseError,
)
from app.providers.tmdb.schemas import (
    TMDBTVDetails,
    TMDBTVSearchResponse,
)

logger = logging.getLogger(__name__)

ResponseModel = TypeVar("ResponseModel", bound=BaseModel)


class TMDBClient:
    """HTTP client responsible for communicating with the TMDB API."""

    def __init__(
        self,
        settings: Settings,
        http_client: httpx.Client | None = None,
    ) -> None:
        api_token = settings.tmdb_api_token

        if api_token is None:
            raise TMDBConfigurationError("TMDB API token is not configured.")

        self._settings = settings
        self._owns_http_client = http_client is None

        self._http_client = http_client or httpx.Client(
            base_url=settings.tmdb_base_url,
            headers={
                "Authorization": (f"Bearer {api_token.get_secret_value()}"),
                "Accept": "application/json",
            },
            timeout=settings.tmdb_timeout_seconds,
        )

    def get(
        self,
        path: str,
        *,
        response_model: type[ResponseModel],
        params: Mapping[str, Any] | None = None,
    ) -> ResponseModel:
        """Perform a GET request and validate the TMDB response."""

        try:
            response = self._http_client.get(
                path,
                params=params,
            )
            response.raise_for_status()

        except httpx.TimeoutException as error:
            raise TMDBRequestError("The request to TMDB timed out.") from error

        except httpx.HTTPStatusError as error:
            if error.response.status_code == httpx.codes.NOT_FOUND:
                raise TMDBNotFoundError("The requested TMDB resource was not found.") from error

            raise TMDBResponseError(
                "TMDB returned an unsuccessful response "
                f"with status code {error.response.status_code}."
            ) from error

        except httpx.RequestError as error:
            raise TMDBRequestError("TMDB could not be reached.") from error

        try:
            return response_model.model_validate(response.json())

        except (ValueError, ValidationError) as error:
            logger.exception(
                "TMDB response failed schema validation: %s",
                error,
            )
            raise TMDBResponseError("TMDB returned an invalid response.") from error

    def search_tv_shows(
        self,
        *,
        query: str,
        page: int = 1,
        language: str | None = None,
    ) -> TMDBTVSearchResponse:
        """Search for TV series by name in TMDB."""

        normalized_query = query.strip()

        if not normalized_query:
            raise ValueError("The search query cannot be empty.")

        if page < 1:
            raise ValueError("The page must be greater than or equal to 1.")

        request_language = language or self._settings.default_language

        return self.get(
            "/search/tv",
            response_model=TMDBTVSearchResponse,
            params={
                "query": normalized_query,
                "page": page,
                "language": request_language,
                "include_adult": False,
            },
        )

    def get_tv_show_details(
        self,
        *,
        tmdb_id: int,
        language: str | None = None,
    ) -> TMDBTVDetails:
        """Get detailed information about a TV series from TMDB."""

        if tmdb_id < 1:
            raise ValueError("The TMDB ID must be greater than or equal to 1.")

        request_language = language or self._settings.default_language

        return self.get(
            f"/tv/{tmdb_id}",
            response_model=TMDBTVDetails,
            params={
                "language": request_language,
            },
        )

    def close(self) -> None:
        """Close the internally managed HTTP client."""

        if self._owns_http_client:
            self._http_client.close()

    def __enter__(self) -> "TMDBClient":
        return self

    def __exit__(
        self,
        exc_type: type[BaseException] | None,
        exc_value: BaseException | None,
        traceback: object | None,
    ) -> None:
        self.close()
