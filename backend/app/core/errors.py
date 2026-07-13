"""Domain errors and centralized FastAPI error handlers."""

from fastapi import FastAPI, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse


class ApplicationError(Exception):
    """Base error that carries a safe API response message and status code."""

    def __init__(self, message: str, status_code: int = status.HTTP_500_INTERNAL_SERVER_ERROR) -> None:
        """Initialize an application error."""
        super().__init__(message)
        self.message = message
        self.status_code = status_code


class TaskNotFoundError(ApplicationError):
    """Raised when a requested video task does not exist."""

    def __init__(self, task_id: str) -> None:
        """Initialize the missing-task error."""
        super().__init__(f"Video generation task '{task_id}' was not found.", status.HTTP_404_NOT_FOUND)


async def application_error_handler(_: Request, exc: Exception) -> JSONResponse:
    """Convert known application errors into a consistent JSON response.

    Returns:
        JSON response containing a safe error message and status code.
    """
    error = exc if isinstance(exc, ApplicationError) else ApplicationError("An unexpected error occurred.")
    return JSONResponse(status_code=error.status_code, content={"detail": error.message})


async def validation_error_handler(_: Request, exc: Exception) -> JSONResponse:
    """Return request validation errors without leaking implementation details."""
    validation_error = exc if isinstance(exc, RequestValidationError) else None
    errors: object = validation_error.errors() if validation_error else []
    return JSONResponse(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, content={"detail": errors})


def register_exception_handlers(app: FastAPI) -> None:
    """Register centralized exception handling for the application."""
    app.add_exception_handler(ApplicationError, application_error_handler)
    app.add_exception_handler(RequestValidationError, validation_error_handler)
