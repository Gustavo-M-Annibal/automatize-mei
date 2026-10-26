"""tabela usuarios (com senha_hash) e CHECKs de integridade

Revision ID: 002
Revises: 001

Só ADICIONA: não altera colunas nem renomeia nada. Se encontrar dados que
violariam uma restrição, ABORTA sem mudar nada e diz quantos registros são.
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "002"
down_revision: Union[str, None] = "001"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def _abortar_se_existir(conn, sql: str, mensagem: str) -> None:
    qtd = conn.execute(sa.text(sql)).scalar()
    if qtd:
        raise RuntimeError(f"{mensagem} ({qtd} registro(s)). Corrija os dados antes de migrar.")


def upgrade() -> None:
    conn = op.get_bind()
    insp = sa.inspect(conn)

    # ---- usuarios ----
    if not insp.has_table("usuarios"):
        op.create_table(
            "usuarios",
            sa.Column("id", sa.Integer(), nullable=False),
            sa.Column("nome", sa.String(100), nullable=False),
            sa.Column("email", sa.String(255), nullable=False),
            sa.Column("senha_hash", sa.String(255), nullable=False),
            sa.Column("cargo", sa.String(20), nullable=False, server_default="funcionario"),
            sa.Column("ativo", sa.Boolean(), nullable=False, server_default=sa.true()),
            sa.Column("criado_em", sa.DateTime(timezone=True), nullable=False, server_default=sa.text("now()")),
            sa.PrimaryKeyConstraint("id"),
        )
        op.create_index("ix_usuarios_email", "usuarios", ["email"], unique=True)
    elif "senha_hash" not in {c["name"] for c in insp.get_columns("usuarios")}:
        # Tabela criada antes (ex.: pelo create_all). Linhas antigas ficam sem senha => não conseguem logar.
        op.add_column("usuarios", sa.Column("senha_hash", sa.String(255), nullable=True))

    # ---- pré-validação ----
    _abortar_se_existir(conn, "SELECT COUNT(*) FROM produtos WHERE preco < 0 OR estoque < 0",
                        "produtos com preço ou estoque negativo")
    _abortar_se_existir(conn, "SELECT COUNT(*) FROM vendas WHERE valor < 0 OR quantidade <= 0",
                        "vendas com valor negativo ou quantidade <= 0")
    _abortar_se_existir(conn, "SELECT COUNT(*) FROM despesas WHERE valor < 0", "despesas com valor negativo")

    # ---- CHECKs ----
    op.create_check_constraint("ck_produtos_preco_nao_negativo", "produtos", "preco >= 0")
    op.create_check_constraint("ck_produtos_estoque_nao_negativo", "produtos", "estoque >= 0")
    op.create_check_constraint("ck_vendas_valor_nao_negativo", "vendas", "valor >= 0")
    op.create_check_constraint("ck_vendas_quantidade_positiva", "vendas", "quantidade > 0")
    op.create_check_constraint("ck_despesas_valor_nao_negativo", "despesas", "valor >= 0")


def downgrade() -> None:
    op.drop_constraint("ck_despesas_valor_nao_negativo", "despesas", type_="check")
    op.drop_constraint("ck_vendas_quantidade_positiva", "vendas", type_="check")
    op.drop_constraint("ck_vendas_valor_nao_negativo", "vendas", type_="check")
    op.drop_constraint("ck_produtos_estoque_nao_negativo", "produtos", type_="check")
    op.drop_constraint("ck_produtos_preco_nao_negativo", "produtos", type_="check")