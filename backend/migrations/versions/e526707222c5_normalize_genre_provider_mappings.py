"""normalize genre provider mappings

Revision ID: e526707222c5
Revises: 3a60c4e4f349
Create Date: 2026-08-09 17:43:59.491024

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'e526707222c5'
down_revision: Union[str, Sequence[str], None] = '3a60c4e4f349'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    pass


def downgrade() -> None:
    """Downgrade schema."""
    pass
