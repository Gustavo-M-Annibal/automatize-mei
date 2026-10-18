from database.conection import Base
from math import integer
from sqlalchemy import Column , Integer , String


class FechamentoModel(Base):
        __tablename__ = "fechamento"

        id = Column(Integer, primary_key= True, index= True)
        fk_usuario_id = Column(Integer, nullable= False)
        data_fechamento = Column(String, nullable= False)
        valor_total =  Column(float, nullable= False, default=0.0)
        status= Column(String, nullable= False, default="aberto")