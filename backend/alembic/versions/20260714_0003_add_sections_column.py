"""Add the Curriculum-stage sections column to video_jobs.

Revision ID: 20260714_0003
Revises: 20260713_0002
Create Date: 2026-07-14
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "20260714_0003"
down_revision: str | None = "20260713_0002"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    """Add the JSON column storing Curriculum-stage concept sections."""
    op.add_column("video_jobs", sa.Column("sections", sa.JSON(), nullable=True))


def downgrade() -> None:
    """Remove the Curriculum-stage sections column."""
    op.drop_column("video_jobs", "sections")
