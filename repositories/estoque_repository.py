from database.models import  EstoqueModel

from sqlalchemy.orm import Session


class EstoqueRepository:

  def __init__(self, db: Session):
    self.db = db

  def criar(self, produto_id: int, usuario_id: int, quantidade_atual: float):
    db_estoque = EstoqueModel(fk_produto_id=produto_id, fk_usuario_id=usuario_id, quantidade_atual=quantidade_atual)
    self.db.add(db_estoque)
    self.db.commit()
    self.db.refresh(db_estoque)
    return db_estoque

  def buscar_por_id(self, fk_usuario_id: int):
    return (
        self.db.query(EstoqueModel).filter(EstoqueModel.fk_usuario_id == fk_usuario_id).first()
    )

  def listar_todos(self):
    return self.db.query(EstoqueModel).all()

  def atualizar(self, produto_id: int, usuario_id: int, quantidade_atual: float):
    estocagem = self.buscar_por_id(usuario_id)
    if estocagem:
      estocagem.fk_produto_id = produto_id
      estocagem.quantidade_atual = quantidade_atual
      self.db.commit()
      self.db.refresh(estocagem)
    return estocagem

  def deletar(self, produto_id: int, usuario_id: int, quantidade_atual: float):
    estocagem = self.buscar_por_id(usuario_id)
    if estocagem:
      self.db.delete(estocagem)
      self.db.commit()
    return estocagem