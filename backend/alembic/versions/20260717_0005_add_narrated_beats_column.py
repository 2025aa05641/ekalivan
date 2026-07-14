"""Add the Narration-stage narrated_beats column to video_jobs.

Revision ID: 20260717_0005
Revises: 20260716_0004
Create Date: 2026-07-17
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "20260717_0005"
down_revision: str | None = "20260716_0004"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    """Add the JSON column storing Narration-stage audio paths and word timing."""
    op.add_column("video_jobs", sa.Column("narrated_beats", sa.JSON(), nullable=True))


def downgrade() -> None:
    """Remove the Narration-stage narrated_beats column."""
    op.drop_column("video_jobs", "narrated_beats")
