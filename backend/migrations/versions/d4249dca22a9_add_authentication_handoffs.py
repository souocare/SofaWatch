"""add authentication handoffs

Revision ID: d4249dca22a9
Revises: e664a5bb6cc4
Create Date: 2026-08-24 11:20:17.133695
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "d4249dca22a9"
down_revision: str | Sequence[str] | None = "e664a5bb6cc4"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    """Create short-lived authentication handoffs."""

    op.create_table(
        "auth_handoffs",
        sa.Column(
            "id",
            sa.Uuid(),
            nullable=False,
        ),
        sa.Column(
            "user_id",
            sa.Uuid(),
            nullable=False,
        ),
        sa.Column(
            "credential_hash",
            sa.String(length=64),
            nullable=False,
        ),
        sa.Column(
            "expires_at",
            sa.DateTime(timezone=True),
            nullable=False,
        ),
        sa.Column(
            "used_at",
            sa.DateTime(timezone=True),
            nullable=True,
        ),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("(CURRENT_TIMESTAMP)"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("(CURRENT_TIMESTAMP)"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(
            ["user_id"],
            ["users.id"],
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id"),
    )

    with op.batch_alter_table(
        "auth_handoffs",
        schema=None,
    ) as batch_op:
        batch_op.create_index(
            batch_op.f("ix_auth_handoffs_credential_hash"),
            ["credential_hash"],
            unique=True,
        )
        batch_op.create_index(
            batch_op.f("ix_auth_handoffs_expires_at"),
            ["expires_at"],
            unique=False,
        )
        batch_op.create_index(
            batch_op.f("ix_auth_handoffs_used_at"),
            ["used_at"],
            unique=False,
        )
        batch_op.create_index(
            batch_op.f("ix_auth_handoffs_user_id"),
            ["user_id"],
            unique=False,
        )


def downgrade() -> None:
    """Remove short-lived authentication handoffs."""

    with op.batch_alter_table(
        "auth_handoffs",
        schema=None,
    ) as batch_op:
        batch_op.drop_index(batch_op.f("ix_auth_handoffs_user_id"))
        batch_op.drop_index(batch_op.f("ix_auth_handoffs_used_at"))
        batch_op.drop_index(batch_op.f("ix_auth_handoffs_expires_at"))
        batch_op.drop_index(batch_op.f("ix_auth_handoffs_credential_hash"))

    op.drop_table(
        "auth_handoffs",
    )
