# Onde ficam os modelos ORM (ex: UsuarioModel)

from database.conection import Base
from sqlalchemy import Column , Integer , String


class UsuarioModel(Base):
    __tablename__ = "usuarios"

    id = Column(Integer, primary_key= True, index= True)
    nome = Column(String, nullable= False)
    email = Column(String, unique= True, index= True)