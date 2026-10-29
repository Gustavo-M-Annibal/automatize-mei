from database.connection import Base
from sqlalchemy import Column, Float, Integer, String


class FechamentoModel(Base):
  __tablename__ = "fechamento"
  __table_args__ = {'extend_existing': True}

  id = Column(Integer, primary_key=True)
  mes = Column(Integer, nullable=False)
  ano = Column(Integer, nullable=False)
  valor_total = Column(Float, nullable=False, default=0.0)
  status = Column(String, nullable=False, default="aberto")