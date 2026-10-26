"""Registro de venda + baixa de estoque na MESMA transação.

Usa SQL direto sobre as tabelas criadas pela migração 001 (produtos / vendas),
que é o esquema que o fechamento de caixa já usa.

"""
from decimal import Decimal
from typing import NoReturn

from sqlalchemy import text
from sqlalchemy.orm import Session

TABELA_PRODUTOS = "produto"
TABELA_VENDAS = "venda"

# Verifica E baixa em um único comando. Se não há estoque suficiente, o WHERE não
# casa, nenhuma linha é alterada e nada é devolvido. O PostgreSQL trava a linha
# durante o UPDATE: uma segunda venda simultânea espera e reavalia o WHERE já
# com o estoque atualizado (por isso o estoque não fica negativo).
_BAIXAR_ESTOQUE = text(
    f"UPDATE {TABELA_PRODUTOS} SET estoque = estoque - :qtd "
    f"WHERE id = :id AND estoque >= :qtd RETURNING preco"
)
_ESTOQUE_ATUAL = text(f"SELECT estoque FROM {TABELA_PRODUTOS} WHERE id = :id")
_INSERIR_VENDA = text(
    f"INSERT INTO {TABELA_VENDAS} (produto_id, quantidade, valor, forma_pagamento) "
    f"VALUES (:produto_id, :quantidade, CAST(:valor AS NUMERIC(10,2)), :forma) "
    f"RETURNING id, data"
)


class ProdutoNaoEncontradoError(Exception):
    def __init__(self, produto_id: int):
        self.produto_id = produto_id


class EstoqueInsuficienteError(Exception):
    def __init__(self, produto_id: int, solicitado: int, disponivel: int):
        self.produto_id = produto_id
        self.solicitado = solicitado
        self.disponivel = disponivel


def registrar_venda(db: Session, itens, forma_pagamento: str) -> dict:
    """`itens`: lista de objetos com .produto_id e .quantidade.

    Cria uma linha em `vendas` por produto (o esquema atual guarda 1 produto por
    linha) e baixa o estoque de cada um. Se QUALQUER passo falhar, nada é gravado.
    """
    # Junta itens repetidos do mesmo produto (2 + 3 = 5) para validar o estoque pelo total.
    quantidades: dict[int, int] = {}
    for item in itens:
        quantidades[item.produto_id] = quantidades.get(item.produto_id, 0) + item.quantidade

    try:
        vendas = []
        total = Decimal("0.00")
        # Ordem fixa por id: evita deadlock entre duas vendas com os mesmos produtos.
        for produto_id in sorted(quantidades):
            qtd = quantidades[produto_id]

            preco = db.execute(_BAIXAR_ESTOQUE, {"qtd": qtd, "id": produto_id}).scalar_one_or_none()
            if preco is None:
                _explicar_falha(db, produto_id, qtd)  # sempre levanta uma exceção

            valor = (Decimal(str(preco)) * qtd).quantize(Decimal("0.01"))
            linha = db.execute(
                _INSERIR_VENDA,
                {"produto_id": produto_id, "quantidade": qtd, "valor": str(valor), "forma": forma_pagamento},
            ).one()
            total += valor
            vendas.append(
                {
                    "id": linha[0],
                    "produto_id": produto_id,
                    "quantidade": qtd,
                    "valor": valor,
                    "data": linha[1],
                    "forma_pagamento": forma_pagamento,
                }
            )
        db.commit()  # só aqui tudo é confirmado, de uma vez
    except Exception:
        db.rollback()  # desfaz as baixas já feitas e os INSERTs pendentes
        raise  # `raise` puro preserva a causa original do erro
    return {"vendas": vendas, "total": total}


def _explicar_falha(db: Session, produto_id: int, solicitado: int) -> NoReturn:
    estoque = db.execute(_ESTOQUE_ATUAL, {"id": produto_id}).scalar_one_or_none()
    if estoque is None:
        raise ProdutoNaoEncontradoError(produto_id)
    raise EstoqueInsuficienteError(produto_id, solicitado, estoque)