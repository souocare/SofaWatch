from app.core.security.passwords import verify_password
from app.models.user import User
from app.repositories.user import UserRepository


class AuthenticationService:
    """Authenticate SofaWatch users using local credentials."""

    def __init__(
        self,
        *,
        user_repository: UserRepository,
    ) -> None:
        self._user_repository = user_repository

    def authenticate(
        self,
        *,
        username: str,
        password: str,
    ) -> User | None:
        """Return the authenticated user when credentials are valid."""

        normalized_username = username.strip().lower()

        if not normalized_username or not password:
            return None

        user = self._user_repository.get_by_username(
            normalized_username,
        )

        if user is None:
            return None

        if not verify_password(
            password,
            user.password_hash,
        ):
            return None

        if not user.is_active:
            return None

        return user