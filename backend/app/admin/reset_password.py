import getpass
import sys

from app.db.session import SessionLocal
from app.repositories.auth_session import AuthSessionRepository
from app.repositories.user import UserRepository
from app.services.administrator_password_recovery import (
    AdministratorPasswordRecoveryService,
    AdministratorRecoveryUnavailableError,
)

_USAGE = "Usage: python -m app.admin.reset_password <administrator_username_or_email>"


def main() -> None:
    """Recover an administrator password from the server console."""

    if len(sys.argv) != 2:
        raise SystemExit(_USAGE)

    identifier = sys.argv[1].strip().lower()

    if not identifier:
        raise SystemExit(_USAGE)

    with SessionLocal() as session:
        user_repository = UserRepository(session)

        user = (
            user_repository.get_by_email(identifier)
            if "@" in identifier
            else user_repository.get_by_username(identifier)
        )

        if user is None:
            raise SystemExit("Administrator account could not be found.")

        if not user.is_admin:
            raise SystemExit("Password recovery is only available for administrators.")

        if not user.is_active:
            raise SystemExit("Password recovery is unavailable for an inactive administrator.")

        new_password = getpass.getpass(
            "New password: ",
        )

        confirm_password = getpass.getpass(
            "Confirm new password: ",
        )

        if new_password != confirm_password:
            raise SystemExit("Passwords do not match.")

        if len(new_password) < 8:
            raise SystemExit("Password must be at least 8 characters.")

        if len(new_password) > 128:
            raise SystemExit("Password must be 128 characters or fewer.")

        service = AdministratorPasswordRecoveryService(
            session=session,
            auth_session_repository=AuthSessionRepository(session),
        )

        try:
            service.reset_password(
                user=user,
                new_password=new_password,
            )
        except AdministratorRecoveryUnavailableError as error:
            raise SystemExit("Administrator password recovery is unavailable.") from error

    print("Administrator password updated successfully.")
    print("Existing sessions have been revoked.")


if __name__ == "__main__":
    main()
