"""remove legacy local user flag

Revision ID: 3bf29b95c63a
Revises: 3d2e5ddca103
Create Date: 2026-08-26 11:10:44.078571

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '3bf29b95c63a'
down_revision: Union[str, Sequence[str], None] = '3d2e5ddca103'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    with op.batch_alter_table("users") as batch_op:
        batch_op.drop_column("is_local")


def downgrade() -> None:
    with op.batch_alter_table("users") as batch_op:
        batch_op.add_column(
            sa.Column(
                "is_local",
                sa.Boolean(),
                nullable=False,
                server_default=sa.false(),
            )
        )

    op.execute(
        sa.text(
            """
            UPDATE users
            SET is_local = TRUE
            WHERE username IS NULL
              AND password_hash IS NULL
            """
        )
    )
