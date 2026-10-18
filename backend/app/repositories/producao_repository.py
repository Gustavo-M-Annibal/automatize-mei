from backend.app.models.produto_sabor_model import ProducaoModel

from sqlalchemy.orm import Session


class ProducaoRepository:

  def __init__(self, db: Session):
    self.db = db

  def criar(self, produto_id: int, usuario_id: int, quantidade: float):
    db_producao = ProducaoModel(fk_produto_id=produto_id, fk_usuario_id=usuario_id, quantidade=quantidade)
    self.db.add(db_producao)
    self.db.commit()
    self.db.refresh(db_producao)
    return db_producao

  def buscar_por_id(self, fk_usuario_id: int):
    return (
        self.db.query(ProducaoModel).filter(ProducaoModel.fk_usuario_id == fk_usuario_id).first()
    )

  def listar_todos(self):
    return self.db.query(ProducaoModel).all()

  def atualizar(self, produto_id: int, usuario_id: int, quantidade: float):
    producao = self.buscar_por_id(usuario_id)
    if producao:
      producao.fk_produto_id = produto_id
      producao.quantidade = quantidade
      self.db.commit()
      self.db.refresh(producao)
    return producao

  def deletar(self, produto_id: int, usuario_id: int, quantidade: float):
    producao = self.buscar_por_id(usuario_id)
    if producao:
      self.db.delete(producao)
      self.db.commit()
    return producao