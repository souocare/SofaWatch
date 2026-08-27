"""add admin flag to users

Revision ID: bb784a0a2cdc
Revises: bff6998b9c5d
Create Date: 2026-08-20 02:37:46.153920

"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "bb784a0a2cdc"
down_revision: str | Sequence[str] | None = "bff6998b9c5d"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "users",
        sa.Column(
            "is_admin",
            sa.Boolean(),
            nullable=False,
            server_default=sa.false(),
        ),
    )

    # SofaWatch currently has one local application user.
    # Preserve administrative access for that existing user while keeping
    # is_local and is_admin as independent concepts.
    op.execute(
        sa.text(
            """
            UPDATE users
            SET is_admin = TRUE
            WHERE is_local = TRUE
            """
        )
    )


def downgrade() -> None:
    op.drop_column(
        "users",
        "is_admin",
    )
