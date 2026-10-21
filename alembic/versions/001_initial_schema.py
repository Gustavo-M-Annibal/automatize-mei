"""schema inicial

Revision ID: 001
Revises:
Create Date: 2026-10-21 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "001"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "produtos",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("nome", sa.String(30), nullable=False),
        sa.Column("preco", sa.Numeric(10, 2), nullable=False),
        sa.Column("estoque", sa.Integer(), nullable=False, server_default="0"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_produtos_id", "produtos", ["id"])

    op.create_table(
        "vendas",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("produto_id", sa.Integer(), nullable=False),
        sa.Column("quantidade", sa.Integer(), nullable=False),
        sa.Column("valor", sa.Numeric(10, 2), nullable=False),
        sa.Column(
            "data",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.text("now()"),
        ),
        sa.Column("forma_pagamento", sa.String(20), nullable=False),
        sa.ForeignKeyConstraint(["produto_id"], ["produtos.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_vendas_id", "vendas", ["id"])

    op.create_table(
        "despesas",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("categoria", sa.String(50), nullable=False),
        sa.Column("valor", sa.Numeric(10, 2), nullable=False),
        sa.Column("data", sa.DateTime(timezone=True), nullable=False),
        sa.Column("da_gaveta", sa.Boolean(), nullable=False, server_default="false"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_despesas_id", "despesas", ["id"])

    op.create_table(
        "fechamentos",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("data", sa.DateTime(timezone=True), nullable=False),
        sa.Column("data_dia", sa.Date(), nullable=False),
        sa.Column("troco_inicial", sa.Numeric(10, 2), nullable=False, server_default="0"),
        sa.Column("vendas_dinheiro", sa.Numeric(10, 2), nullable=False, server_default="0"),
        sa.Column("saidas_gaveta", sa.Numeric(10, 2), nullable=False, server_default="0"),
        sa.Column("contado_dinheiro", sa.Numeric(10, 2), nullable=False, server_default="0"),
        sa.Column("total_cartao", sa.Numeric(10, 2), nullable=False, server_default="0"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("data_dia"),
    )
    op.create_index("ix_fechamentos_id", "fechamentos", ["id"])

    op.create_table(
        "producoes",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("produto_id", sa.Integer(), nullable=False),
        sa.Column("quantidade", sa.Integer(), nullable=False),
        sa.Column(
            "data",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.text("now()"),
        ),
        sa.ForeignKeyConstraint(["produto_id"], ["produtos.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_producoes_id", "producoes", ["id"])

    op.create_table(
        "perdas",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("produto_id", sa.Integer(), nullable=False),
        sa.Column("quantidade", sa.Integer(), nullable=False),
        sa.Column(
            "data",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.text("now()"),
        ),
        sa.ForeignKeyConstraint(["produto_id"], ["produtos.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_perdas_id", "perdas", ["id"])


def downgrade() -> None:
    op.drop_index("ix_perdas_id", table_name="perdas")
    op.drop_table("perdas")
    op.drop_index("ix_producoes_id", table_name="producoes")
    op.drop_table("producoes")
    op.drop_index("ix_fechamentos_id", table_name="fechamentos")
    op.drop_table("fechamentos")
    op.drop_index("ix_despesas_id", table_name="despesas")
    op.drop_table("despesas")
    op.drop_index("ix_vendas_id", table_name="vendas")
    op.drop_table("vendas")
    op.drop_index("ix_produtos_id", table_name="produtos")
    op.drop_table("produtos")
