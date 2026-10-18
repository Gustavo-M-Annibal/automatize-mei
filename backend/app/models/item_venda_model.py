from database.conection import Base
from math import integer
from sqlalchemy import Column , Integer , String




class ItemVendaModel(Base):
        __tablename__ = "item_venda"

        id = Column(Integer, primary_key= True, index= True)
        fk_venda_id = Column(Integer, nullable= False)
        fk_produto_id = Column(Integer, nullable= False)
        quantidade = Column(float, nullable= False, default=0.0)
        valor_unitario = Column(float, nullable= False, default=0.0)