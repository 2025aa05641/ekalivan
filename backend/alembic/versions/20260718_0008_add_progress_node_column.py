"""Add progress_node column to video_jobs.

Revision ID: 20260718_0008
Revises: 20260719_0007
Create Date: 2026-07-18
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "20260718_0008"
down_revision: str | None = "20260719_0007"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    """Add the column that tracks which pipeline node is currently running."""
    op.add_column("video_jobs", sa.Column("progress_node", sa.String(length=64), nullable=True))


def downgrade() -> None:
    """Remove the progress_node column."""
    op.drop_column("video_jobs", "progress_node")
