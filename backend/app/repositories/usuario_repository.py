from backend.app.models.produto_model import UsuarioModel
from sqlalchemy.orm import Session


class UsuarioRepository:

  def __init__(self, db: Session):
    self.db = db

  def criar(self, nome: str, email: str):
    db_usuario = UsuarioModel(nome=nome, email=email)
    self.db.add(db_usuario)
    self.db.commit()
    self.db.refresh(db_usuario)
    return db_usuario

  def buscar_por_id(self, usuario_id: int):
    return (
        self.db.query(UsuarioModel).filter(UsuarioModel.id == usuario_id).first()
    )

  def listar_todos(self):
    return self.db.query(UsuarioModel).all()

  def atualizar(self, usuario_id: int, novo_nome: str, novo_email: str):
    usuario = self.buscar_por_id(usuario_id)
    if usuario:
      usuario.nome = novo_nome
      usuario.email = novo_email
      self.db.commit()
      self.db.refresh(usuario)
    return usuario

  def deletar(self, usuario_id: int):
    usuario = self.buscar_por_id(usuario_id)
    if usuario:
      self.db.delete(usuario)
      self.db.commit()
    return usuario