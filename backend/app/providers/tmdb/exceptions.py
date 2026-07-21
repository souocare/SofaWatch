class TMDBError(Exception):
    """Base exception for all TMDB provider errors."""


class TMDBConfigurationError(TMDBError):
    """Raised when the TMDB provider is not correctly configured."""


class TMDBRequestError(TMDBError):
    """Raised when a request to TMDB cannot be completed."""


class TMDBResponseError(TMDBError):
    """Raised when TMDB returns an unsuccessful or invalid response."""


class TMDBNotFoundError(TMDBResponseError):
    """Raised when the requested resource does not exist in TMDB."""
