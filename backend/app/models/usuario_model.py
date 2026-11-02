from sqlalchemy import Boolean, Column, DateTime, Integer, String, true
from sqlalchemy.sql import func

from database.connection import Base


class UsuarioModel(Base):
    __tablename__ = "usuarios"

    id = Column(Integer, primary_key=True)
    nome = Column(String(100), nullable=False)
    # Usado como "login". Sempre salvo em minúsculas pelo service.
    email = Column(String(255), nullable=False, unique=True, index=True)
    # Somente o hash bcrypt. NÃO existe coluna com a senha em texto puro.
    senha_hash = Column(String(255), nullable=False) # Exigência de segurança (bcrypt)
    cargo = Column(String(20), nullable=False, default="funcionario", server_default="funcionario")
    ativo = Column(Boolean, nullable=False, default=True, server_default=true())
    criado_em = Column(DateTime(timezone=True), nullable=False, server_default=func.now())