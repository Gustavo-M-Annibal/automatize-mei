from database.connection import Base
from sqlalchemy import Column, Integer, String, Numeric


class Produto(Base):
    __tablename__ = "produtos"

    id = Column(Integer, primary_key=True, index=True)
    nome = Column(String(30), nullable=False)
    preco = Column(Numeric(10, 2), nullable=False)
    estoque = Column(Integer, nullable=False, default=0)
