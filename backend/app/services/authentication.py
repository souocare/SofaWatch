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
        identifier: str,
        password: str,
    ) -> User | None:
        """Authenticate a user by username or email address."""

        normalized_identifier = identifier.strip().lower()

        if not normalized_identifier or not password:
            return None

        user = self._find_user(
            normalized_identifier,
        )

        if user is None:
            return None

        if user.password_hash is None:
            return None

        if not verify_password(
            password,
            user.password_hash,
        ):
            return None

        if not user.is_active:
            return None

        return user

    def _find_user(
        self,
        identifier: str,
    ) -> User | None:
        """Resolve an authentication identifier to a SofaWatch user."""

        user = self._user_repository.get_by_username(
            identifier,
        )

        if user is not None:
            return user

        return self._user_repository.get_by_email(
            identifier,
        )
