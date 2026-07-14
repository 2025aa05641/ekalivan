"""Add the Assembly-stage output_video_path column to video_jobs.

Revision ID: 20260718_0006
Revises: 20260717_0005
Create Date: 2026-07-18
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "20260718_0006"
down_revision: str | None = "20260717_0005"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    """Add the column storing the final rendered video's file path."""
    op.add_column("video_jobs", sa.Column("output_video_path", sa.String(length=1024), nullable=True))


def downgrade() -> None:
    """Remove the Assembly-stage output_video_path column."""
    op.drop_column("video_jobs", "output_video_path")
