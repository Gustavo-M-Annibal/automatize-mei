from database.connection import Base
from sqlalchemy import Column, DateTime, Integer, Numeric, String
from sqlalchemy.sql import func


class VendaModel(Base):
    __tablename__ = "vendas"
    __table_args__ = {'extend_existing': True}

    id = Column(Integer, primary_key=True, index=True)
    produto_id = Column(Integer, nullable=False)
    quantidade = Column(Integer, nullable=False)
    valor = Column(Numeric(10, 2), nullable=False)
    data = Column(DateTime(timezone=True), nullable=False, server_default=func.now())
    forma_pagamento = Column(String(20), nullable=False)


Venda = VendaModel