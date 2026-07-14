"""Add the Publishing-stage video_url column to video_jobs.

Revision ID: 20260719_0007
Revises: 20260718_0006
Create Date: 2026-07-19
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "20260719_0007"
down_revision: str | None = "20260718_0006"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    """Add the column storing the video's public, servable URL."""
    op.add_column("video_jobs", sa.Column("video_url", sa.String(length=1024), nullable=True))


def downgrade() -> None:
    """Remove the Publishing-stage video_url column."""
    op.drop_column("video_jobs", "video_url")
