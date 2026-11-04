from sqlalchemy.orm import Session

from backend.app.models.perda_model import PerdaModel
from backend.app.models.produto_model import ProdutoModel
from backend.app.models.producao_model import ProducaoModel


class ProdutoNaoEncontradoError(Exception):
    def __init__(self, produto_id: int):
        self.produto_id = produto_id
        super().__init__(f"Produto {produto_id} não encontrado.")


def registrar(db: Session, produto_id: int, quantidade: int) -> ProducaoModel:
    produto = db.query(ProdutoModel).filter(ProdutoModel.id == produto_id).first()
    if not produto:
        raise ProdutoNaoEncontradoError(produto_id)
    produto.estoque += quantidade
    producao = ProducaoModel(produto_id=produto_id, quantidade=quantidade)
    db.add(producao)
    db.commit()
    db.refresh(producao)
    return producao
