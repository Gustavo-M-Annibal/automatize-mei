from database.connection import Base
from sqlalchemy import Column, Integer, Numeric, DateTime, Date


class Fechamento(Base):
    __tablename__ = "fechamentos"

    id = Column(Integer, primary_key=True, index=True)
    data = Column(DateTime(timezone=True), nullable=False)
    data_dia = Column(Date, nullable=False, unique=True)
    troco_inicial = Column(Numeric(10, 2), nullable=False, default=0)
    vendas_dinheiro = Column(Numeric(10, 2), nullable=False, default=0)
    saidas_gaveta = Column(Numeric(10, 2), nullable=False, default=0)
    contado_dinheiro = Column(Numeric(10, 2), nullable=False, default=0)
    total_cartao = Column(Numeric(10, 2), nullable=False, default=0)
