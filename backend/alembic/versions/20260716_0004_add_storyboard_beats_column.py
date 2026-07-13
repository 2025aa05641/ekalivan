"""Add the Storyboard-stage storyboard_beats column to video_jobs.

Revision ID: 20260716_0004
Revises: 20260714_0003
Create Date: 2026-07-16
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "20260716_0004"
down_revision: str | None = "20260714_0003"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    """Add the JSON column storing Storyboard-stage scene beats."""
    op.add_column("video_jobs", sa.Column("storyboard_beats", sa.JSON(), nullable=True))


def downgrade() -> None:
    """Remove the Storyboard-stage scene beats column."""
    op.drop_column("video_jobs", "storyboard_beats")
