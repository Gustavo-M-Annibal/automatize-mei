from database.connection import Base
from sqlalchemy import Boolean, Column, DateTime, Float, Integer, String


class ProdutoModel(Base):
  __tablename__ = "produto"
  __table_args__ = {'extend_existing': True}

  id = Column(Integer, primary_key=True)
  nome = Column(String, nullable=False)
  preco = Column(Float, nullable=False)
  estoque = Column(Integer, default=0)