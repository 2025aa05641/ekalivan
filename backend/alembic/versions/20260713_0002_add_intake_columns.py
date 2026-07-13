"""Add Intake-stage columns to video_jobs.

Revision ID: 20260713_0002
Revises: 20260712_0001
Create Date: 2026-07-13
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "20260713_0002"
down_revision: str | None = "20260712_0001"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    """Add the source file path and Intake-stage result columns."""
    op.add_column(
        "video_jobs", sa.Column("file_storage_path", sa.String(length=512), nullable=False, server_default="")
    )
    op.alter_column("video_jobs", "file_storage_path", server_default=None)
    op.add_column("video_jobs", sa.Column("markdown_content", sa.Text(), nullable=True))
    op.add_column("video_jobs", sa.Column("error_message", sa.Text(), nullable=True))


def downgrade() -> None:
    """Remove the Intake-stage columns."""
    op.drop_column("video_jobs", "error_message")
    op.drop_column("video_jobs", "markdown_content")
    op.drop_column("video_jobs", "file_storage_path")
