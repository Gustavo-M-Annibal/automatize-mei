from backend.app.models.produto_sabor_model import ItemVendaModel
from sqlalchemy.orm import Session


class ItemVendaRepository:

  def __init__(self, db: Session):
    self.db = db

  def criar(self, produto_id: int, usuario_id: int, quantidade_atual: float):
    db_item_venda = ItemVendaModel(fk_produto_id=produto_id, fk_usuario_id=usuario_id, quantidade_atual=quantidade_atual)
    self.db.add(db_item_venda)
    self.db.commit()
    self.db.refresh(db_item_venda)
    return db_item_venda

  def buscar_por_id(self, fk_usuario_id: int):
    return (
        self.db.query(ItemVendaModel).filter(ItemVendaModel.fk_usuario_id == fk_usuario_id).first()
    )

  def listar_todos(self):
    return self.db.query(ItemVendaModel).all()

  def atualizar(self, produto_id: int, usuario_id: int, quantidade_atual: float):
    item_venda = self.buscar_por_id(usuario_id)
    if item_venda:
      item_venda.fk_produto_id = produto_id
      item_venda.quantidade_atual = quantidade_atual
      self.db.commit()
      self.db.refresh(item_venda)
    return item_venda

  def deletar(self, produto_id: int, usuario_id: int, quantidade_atual: float):
    item_venda = self.buscar_por_id(usuario_id)
    if item_venda:
      self.db.delete(item_venda)
      self.db.commit()
    return item_venda