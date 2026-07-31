"""Global API exception handlers."""

from typing import Any

from fastapi import Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException

from app.core.exceptions import APIError


def api_error_handler(
    request: Request,
    error: APIError,
) -> JSONResponse:
    """Return the standard response for an application API error."""

    del request

    content: dict[str, Any] = {
        "error": {
            "code": error.code,
            "message": error.message,
        }
    }

    if error.details is not None:
        content["error"]["details"] = error.details

    return JSONResponse(
        status_code=error.status_code,
        content=content,
    )


def http_exception_handler(
    request: Request,
    error: StarletteHTTPException,
) -> JSONResponse:
    """Normalize FastAPI and Starlette HTTP errors."""

    del request

    message = (
        error.detail
        if isinstance(error.detail, str)
        else "The request could not be completed."
    )

    return JSONResponse(
        status_code=error.status_code,
        content={
            "error": {
                "code": "http_error",
                "message": message,
            }
        },
        headers=error.headers,
    )


def validation_exception_handler(
    request: Request,
    error: RequestValidationError,
) -> JSONResponse:
    """Normalize request validation errors."""

    del request

    details: list[dict[str, Any]] = []

    for validation_error in error.errors():
        location = validation_error.get(
            "loc",
            (),
        )

        field_parts = [
            str(part)
            for part in location
            if part not in {
                "body",
                "path",
                "query",
                "header",
                "cookie",
            }
        ]

        detail: dict[str, Any] = {
            "field": ".".join(field_parts) or None,
            "message": validation_error.get(
                "msg",
                "Invalid value.",
            ),
        }

        context = validation_error.get("ctx")

        if context:
            detail["context"] = {
                key: value
                for key, value in context.items()
                if isinstance(
                    value,
                    (
                        str,
                        int,
                        float,
                        bool,
                        type(None),
                    ),
                )
            }

        details.append(detail)

    return JSONResponse(
        status_code=422,
        content={
            "error": {
                "code": "validation_error",
                "message": "The request contains invalid data.",
                "details": details,
            }
        },
    )