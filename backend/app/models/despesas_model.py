from database.conection import Base
from sqlalchemy import Boolean, Column, DateTime, Float, Integer, String


class DespesaModel(Base):
  __tablename__ = "despesas"

  id = Column(Integer, primary_key=True, index=True)
  categoria = Column(String, nullable=False)
  valor = Column(Float, nullable=False)
  data = Column(String, nullable=False)
  da_gaveta = Column(Boolean, default=True)