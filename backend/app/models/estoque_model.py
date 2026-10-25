
from database.connection import Base
from math import integer
from sqlalchemy import Column, Float , Integer , String




class EstoqueModel(Base):
        __tablename__ = "estoque"

        id = Column(Integer, primary_key= True)
        fk_produto_id = Column(Integer, nullable= False)
        quantidade_atual = Column(Float, nullable= False, default=0.0)