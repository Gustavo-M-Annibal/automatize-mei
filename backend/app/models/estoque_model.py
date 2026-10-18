
from database.conection import Base
from math import integer
from sqlalchemy import Column , Integer , String




class EstoqueModel(Base):
        __tablename__ = "estoque"

        id = Column(Integer, primary_key= True, index= True)
        fk_produto_id = Column(Integer, nullable= False)
        quantidade_atual = Column(float, nullable= False, default=0.0)