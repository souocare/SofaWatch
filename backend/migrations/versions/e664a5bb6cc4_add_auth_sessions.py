"""add auth sessions

Revision ID: e664a5bb6cc4
Revises: ad5b9bbd45d6
Create Date: 2026-08-21 07:20:16.204313
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "e664a5bb6cc4"
down_revision: str | Sequence[str] | None = "ad5b9bbd45d6"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    """Create persistent authentication sessions."""

    op.create_table(
        "auth_sessions",
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
            "session_type",
            sa.Enum(
                "WEB",
                "MOBILE",
                name="authsessiontype",
                native_enum=False,
                length=16,
            ),
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
            "last_used_at",
            sa.DateTime(timezone=True),
            nullable=True,
        ),
        sa.Column(
            "revoked_at",
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
        "auth_sessions",
        schema=None,
    ) as batch_op:
        batch_op.create_index(
            batch_op.f("ix_auth_sessions_credential_hash"),
            ["credential_hash"],
            unique=True,
        )
        batch_op.create_index(
            batch_op.f("ix_auth_sessions_expires_at"),
            ["expires_at"],
            unique=False,
        )
        batch_op.create_index(
            batch_op.f("ix_auth_sessions_revoked_at"),
            ["revoked_at"],
            unique=False,
        )
        batch_op.create_index(
            batch_op.f("ix_auth_sessions_user_id"),
            ["user_id"],
            unique=False,
        )


def downgrade() -> None:
    """Remove persistent authentication sessions."""

    with op.batch_alter_table(
        "auth_sessions",
        schema=None,
    ) as batch_op:
        batch_op.drop_index(batch_op.f("ix_auth_sessions_user_id"))
        batch_op.drop_index(batch_op.f("ix_auth_sessions_revoked_at"))
        batch_op.drop_index(batch_op.f("ix_auth_sessions_expires_at"))
        batch_op.drop_index(batch_op.f("ix_auth_sessions_credential_hash"))

    op.drop_table(
        "auth_sessions",
    )
