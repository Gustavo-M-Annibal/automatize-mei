from backend.app.models.produto_sabor_model import ProdutoSaborModel
from sqlalchemy.orm import Session


class ProdutoSaborRepository:

  def __init__(self, db: Session):
    self.db = db

  def criar(self, produto_id: int, usuario_id: int, quantidade_atual: float):
    db_produto_sabor = ProdutoSaborModel(fk_produto_id=produto_id, fk_usuario_id=usuario_id, quantidade_atual=quantidade_atual)
    self.db.add(db_produto_sabor)
    self.db.commit()
    self.db.refresh(db_produto_sabor)
    return db_produto_sabor

  def buscar_por_id(self, fk_usuario_id: int):
    return (
        self.db.query(ProdutoSaborModel).filter(ProdutoSaborModel.fk_usuario_id == fk_usuario_id).first()
    )

  def listar_todos(self):
    return self.db.query(ProdutoSaborModel).all()

  def atualizar(self, produto_id: int, usuario_id: int, quantidade_atual: float):
    produto_sabor = self.buscar_por_id(usuario_id)
    if produto_sabor:
      produto_sabor.fk_produto_id = produto_id
      produto_sabor.quantidade_atual = quantidade_atual
      self.db.commit()
      self.db.refresh(produto_sabor)
    return produto_sabor

  def deletar(self, produto_id: int, usuario_id: int, quantidade_atual: float):
    produto_sabor = self.buscar_por_id(usuario_id)
    if produto_sabor:
      self.db.delete(produto_sabor)
      self.db.commit()
    return produto_sabor