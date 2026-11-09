"""Registro de venda + baixa de estoque na MESMA transação.

Usa SQL direto sobre as tabelas criadas pela migração 001 (produtos / vendas),
que é o esquema que o fechamento de caixa já usa.

"""
from decimal import Decimal
from typing import NoReturn

from sqlalchemy import text
from sqlalchemy.orm import Session

from backend.app.core.timezone import agora_negocio, get_business_day
from backend.app.repositories import fechamento_repository
from backend.app.services.fechamento_service import DiaJaFechadoError

TABELA_PRODUTOS = "produtos"
TABELA_VENDAS = "vendas"

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


def registrar_venda(db: Session, item_ou_itens, forma_pagamento: str | None = None) -> dict:
    """Registra uma venda simples por produto ou, por compatibilidade, uma lista de itens.

    O app atual envia um único produto por requisição; neste caso, o item já traz a
    forma de pagamento. A compatibilidade com a estrutura antiga é mantida para evitar
    quebrar o restante do backend.
    """
    if hasattr(item_ou_itens, "produto_id") and hasattr(item_ou_itens, "quantidade"):
        itens = [item_ou_itens]
        forma_pagamento = item_ou_itens.forma_pagamento if forma_pagamento is None else forma_pagamento
    else:
        itens = item_ou_itens
        if forma_pagamento is None:
            raise ValueError("forma_pagamento é obrigatório quando a venda vem em lista.")

    # Junta itens repetidos do mesmo produto (2 + 3 = 5) para validar o estoque pelo total.
    quantidades: dict[int, int] = {}
    for item in itens:
        quantidades[item.produto_id] = quantidades.get(item.produto_id, 0) + item.quantidade

    try:
        dia = get_business_day(agora_negocio())
        if fechamento_repository.buscar_por_dia(db, dia):
            raise DiaJaFechadoError(f"Dia {dia} já possui fechamento registrado.")

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


class VendaNaoEncontradaError(Exception):
    def __init__(self, venda_id: int):
        self.venda_id = venda_id
        super().__init__(f"Venda {venda_id} não encontrada.")


def listar_vendas(db: Session) -> list:
    from backend.app.models.venda_model import VendaModel
    return db.query(VendaModel).order_by(VendaModel.data).all()


def cancelar_venda(db: Session, venda_id: int) -> None:
    from backend.app.repositories.venda_repository import VendaRepository
    from backend.app.services.fechamento_service import DiaJaFechadoError

    repo = VendaRepository(db)
    venda = repo.buscar_por_id(venda_id)
    if not venda:
        raise VendaNaoEncontradaError(venda_id)
    db.execute(
        text(f"UPDATE {TABELA_PRODUTOS} SET estoque = estoque + :qtd WHERE id = :id"),
        {"qtd": venda.quantidade, "id": venda.produto_id},
    )
    try:
        repo.deletar(venda)
    except DiaJaFechadoError:
        db.rollback()
        raise