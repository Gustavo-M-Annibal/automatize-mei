from database.models import  FechamentoModel
from sqlalchemy.orm import Session


class FechamentoRepository:

  def __init__(self, db: Session):
    self.db = db

  def criar(self, produto_id: int, usuario_id: int, quantidade_atual: float):
    db_fechamento = FechamentoModel(fk_produto_id=produto_id, fk_usuario_id=usuario_id, quantidade_atual=quantidade_atual)
    self.db.add(db_fechamento)
    self.db.commit()
    self.db.refresh(db_fechamento)
    return db_fechamento

  def buscar_por_id(self, fk_usuario_id: int):
    return (
        self.db.query(FechamentoModel).filter(FechamentoModel.fk_usuario_id == fk_usuario_id).first()
    )

  def listar_todos(self):
    return self.db.query(FechamentoModel).all()

  def atualizar(self, produto_id: int, usuario_id: int, quantidade_atual: float):
    fechamento = self.buscar_por_id(usuario_id)
    if fechamento:
      fechamento.fk_produto_id = produto_id
      fechamento.quantidade_atual = quantidade_atual
      self.db.commit()
      self.db.refresh(fechamento)
    return fechamento

  def deletar(self, produto_id: int, usuario_id: int, quantidade_atual: float):
    fechamento = self.buscar_por_id(usuario_id)
    if fechamento:
      self.db.delete(fechamento)
      self.db.commit()
    return fechamento