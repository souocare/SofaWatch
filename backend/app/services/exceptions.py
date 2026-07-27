class GenreAlreadyExistsError(Exception):
    """Raised when a genre name or slug already exists."""

class LibraryEntryAlreadyExistsError(Exception):
    """Raised when a TV series already exists in a user's library."""