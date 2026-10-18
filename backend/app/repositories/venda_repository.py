from backend.app.models.produto_sabor_model import VendaModel
from sqlalchemy.orm import Session


class VendaRepository:

  def __init__(self, db: Session):
    self.db = db

  def criar(self, produto_id: int, usuario_id: int, quantidade_atual: float):
    db_venda = VendaModel(fk_produto_id=produto_id, fk_usuario_id=usuario_id, quantidade_atual=quantidade_atual)
    self.db.add(db_venda)
    self.db.commit()
    self.db.refresh(db_venda)
    return db_venda

  def buscar_por_id(self, fk_usuario_id: int):
    return (
        self.db.query(VendaModel).filter(VendaModel.fk_usuario_id == fk_usuario_id).first()
    )

  def listar_todos(self):
    return self.db.query(VendaModel).all()

  def atualizar(self, produto_id: int, usuario_id: int, quantidade_atual: float):
    venda = self.buscar_por_id(usuario_id)
    if venda:
      venda.fk_produto_id = produto_id
      venda.quantidade_atual = quantidade_atual
      self.db.commit()
      self.db.refresh(venda)
    return venda

  def deletar(self, produto_id: int, usuario_id: int, quantidade_atual: float):
    venda = self.buscar_por_id(usuario_id)
    if venda:
      self.db.delete(venda)
      self.db.commit()
    return venda