from uuid import UUID, uuid4

from sqlalchemy import Boolean, Uuid
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base
from app.db.mixins import TimestampMixin


class AuthenticationSettings(TimestampMixin, Base):
    """Global authentication settings for this SofaWatch installation."""

    __tablename__ = "authentication_settings"

    id: Mapped[UUID] = mapped_column(
        Uuid(as_uuid=True),
        primary_key=True,
        default=uuid4,
    )

    open_registration: Mapped[bool] = mapped_column(
        Boolean,
        nullable=False,
        default=False,
    )

    def __repr__(self) -> str:
        return (
            f"AuthenticationSettings(id={self.id!r}, open_registration={self.open_registration!r})"
        )
