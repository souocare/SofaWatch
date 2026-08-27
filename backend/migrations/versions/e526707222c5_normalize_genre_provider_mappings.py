"""normalize genre provider mappings

Revision ID: e526707222c5
Revises: 3a60c4e4f349
Create Date: 2026-08-09 17:43:59.491024

"""

from collections.abc import Sequence

# revision identifiers, used by Alembic.
revision: str = "e526707222c5"
down_revision: str | Sequence[str] | None = "3a60c4e4f349"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    """Upgrade schema."""
    pass


def downgrade() -> None:
    """Downgrade schema."""
    pass
