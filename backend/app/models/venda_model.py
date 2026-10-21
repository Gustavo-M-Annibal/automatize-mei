from database.connection import Base
from sqlalchemy import Column, Integer, String, Numeric, DateTime, ForeignKey
from sqlalchemy.sql import func


class Venda(Base):
    __tablename__ = "vendas"

    id = Column(Integer, primary_key=True, index=True)
    produto_id = Column(Integer, ForeignKey("produtos.id"), nullable=False)
    quantidade = Column(Integer, nullable=False)
    valor = Column(Numeric(10, 2), nullable=False)
    data = Column(DateTime(timezone=True), nullable=False, server_default=func.now())
    forma_pagamento = Column(String(20), nullable=False)
