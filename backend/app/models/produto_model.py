from database.connection import Base
from sqlalchemy import Column, Integer, Numeric, String


class ProdutoModel(Base):
    __tablename__ = "produtos"
    __table_args__ = {"extend_existing": True}

    id = Column(Integer, primary_key=True, index=True)
    nome = Column(String(30), nullable=False)
    preco = Column(Numeric(10, 2), nullable=False)
    estoque = Column(Integer, nullable=False, default=0)
