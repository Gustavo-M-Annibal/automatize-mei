# Onde ficam os modelos ORM (ex: UsuarioModel)

from database.conection import Base
from math import integer
from sqlalchemy import Column , Integer , String



class ProdutoSaborModel(Base):
        __tablename__ = "produto_sabor"

        id = Column(Integer, primary_key= True, index= True)
        name = Column(String, unique= True, index= True)
        preco_venda = Column(float, nullable= False, default= 0.0)
        