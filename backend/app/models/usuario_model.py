from database.conection import Base
from math import integer
from sqlalchemy import Column , Integer , String


class UsuarioModel(Base):
    __tablename__ = "usuarios"

    id = Column(Integer, primary_key= True, index= True)
    nome = Column(String, nullable= False)
    fk_usuario_id = Column(Integer, nullable= False)
    email = Column(String, unique= True, index= True)
    valor = Column(float, nullable= False, default=0.0)
    cargo = Column(String, nullable= False, default="funcionario")