from database.connection import Base
from sqlalchemy import Column, Float , Integer , String


class UsuarioModel(Base):
    __tablename__ = "usuarios"

    id = Column(Integer, primary_key= True)
    nome = Column(String, nullable= False)
    fk_usuario_id = Column(Integer, nullable= False)
    email = Column(String, unique= True)
    valor = Column(Float, nullable= False, default=0.0)
    cargo = Column(String, nullable= False, default="funcionario")