from database.connection import Base
from sqlalchemy import Column, Float, Integer, String



class VendaModel(Base):
        __tablename__ = "venda"
        __table_args__ = {'extend_existing': True}

        id = Column(Integer, primary_key= True)
        fk_usuario_id = Column(Integer, nullable= False)
        fk_fechamento_id = Column(Integer, nullable= False)
        valor_total = Column(Float, nullable= False, default=0.0)