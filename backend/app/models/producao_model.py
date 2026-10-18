from database.conection import Base
from math import integer
from sqlalchemy import Column , Integer , String




class ProducaoModel(Base):
    __tablename__ = "producao"

    id = Column(Integer, primary_key= True, index= True)
    fk_produto_id = Column(Integer, nullable= False)
    fk_usuario_id = Column(Integer, nullable= False)
    quantidade =  Column(float, nullable= False, default=0.0)
