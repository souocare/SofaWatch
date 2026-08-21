"""add authenticatable identity to users

Revision ID: ad5b9bbd45d6
Revises: bb784a0a2cdc
Create Date: 2026-08-21 04:46:48.157015

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'ad5b9bbd45d6'
down_revision: Union[str, Sequence[str], None] = 'bb784a0a2cdc'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "users",
        sa.Column(
            "username",
            sa.String(length=32),
            nullable=True,
        ),
    )

    op.add_column(
        "users",
        sa.Column(
            "email",
            sa.String(length=320),
            nullable=True,
        ),
    )

    op.add_column(
        "users",
        sa.Column(
            "password_hash",
            sa.String(length=255),
            nullable=True,
        ),
    )

    op.add_column(
        "users",
        sa.Column(
            "is_active",
            sa.Boolean(),
            nullable=False,
            server_default=sa.true(),
        ),
    )

    op.create_index(
        "ix_users_username_unique",
        "users",
        ["username"],
        unique=True,
    )

    op.create_index(
        "ix_users_email_unique",
        "users",
        ["email"],
        unique=True,
    )


def downgrade() -> None:
    op.drop_index(
        "ix_users_email_unique",
        table_name="users",
    )

    op.drop_index(
        "ix_users_username_unique",
        table_name="users",
    )

    op.drop_column(
        "users",
        "is_active",
    )

    op.drop_column(
        "users",
        "password_hash",
    )

    op.drop_column(
        "users",
        "email",
    )

    op.drop_column(
        "users",
        "username",
    )
