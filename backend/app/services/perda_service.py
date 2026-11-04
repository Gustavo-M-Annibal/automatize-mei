from sqlalchemy.orm import Session

from backend.app.models.perda_model import PerdaModel
from backend.app.models.produto_model import ProdutoModel


class ProdutoNaoEncontradoError(Exception):
    def __init__(self, produto_id: int):
        self.produto_id = produto_id
        super().__init__(f"Produto {produto_id} não encontrado.")


class EstoqueInsuficienteError(Exception):
    def __init__(self, disponivel: int, solicitado: int):
        self.disponivel = disponivel
        self.solicitado = solicitado
        super().__init__(f"Estoque insuficiente: disponível {disponivel}, solicitado {solicitado}.")


def registrar(db: Session, produto_id: int, quantidade: int) -> PerdaModel:
    produto = db.query(ProdutoModel).filter(ProdutoModel.id == produto_id).first()
    if not produto:
        raise ProdutoNaoEncontradoError(produto_id)
    if produto.estoque < quantidade:
        raise EstoqueInsuficienteError(disponivel=produto.estoque, solicitado=quantidade)
    produto.estoque -= quantidade
    perda = PerdaModel(produto_id=produto_id, quantidade=quantidade)
    db.add(perda)
    db.commit()
    db.refresh(perda)
    return perda
