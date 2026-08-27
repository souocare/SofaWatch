"""add episode watch events

Revision ID: 1fcb1074a10c
Revises: 9c5224fb40cc
Create Date: 2026-08-14 11:29:12.072904
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "1fcb1074a10c"
down_revision: str | Sequence[str] | None = "9c5224fb40cc"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    """Upgrade schema."""

    op.create_table(
        "episode_watch_events",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("user_id", sa.Uuid(), nullable=False),
        sa.Column("episode_id", sa.Uuid(), nullable=False),
        sa.Column(
            "watched_at",
            sa.DateTime(timezone=True),
            nullable=False,
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
            ["episode_id"],
            ["episodes.id"],
            ondelete="CASCADE",
        ),
        sa.ForeignKeyConstraint(
            ["user_id"],
            ["users.id"],
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id"),
    )

    with op.batch_alter_table(
        "episode_watch_events",
        schema=None,
    ) as batch_op:
        batch_op.create_index(
            "ix_episode_watch_events_episode_id",
            ["episode_id"],
            unique=False,
        )

        batch_op.create_index(
            "ix_episode_watch_events_user_id_episode_id",
            ["user_id", "episode_id"],
            unique=False,
        )

        batch_op.create_index(
            "ix_episode_watch_events_user_id_watched_at",
            ["user_id", "watched_at"],
            unique=False,
        )


def downgrade() -> None:
    """Downgrade schema."""

    with op.batch_alter_table(
        "episode_watch_events",
        schema=None,
    ) as batch_op:
        batch_op.drop_index(
            "ix_episode_watch_events_user_id_watched_at",
        )

        batch_op.drop_index(
            "ix_episode_watch_events_user_id_episode_id",
        )

        batch_op.drop_index(
            "ix_episode_watch_events_episode_id",
        )

    op.drop_table("episode_watch_events")
