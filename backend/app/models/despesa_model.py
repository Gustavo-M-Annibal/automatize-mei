from database.connection import Base
from sqlalchemy import Column, Integer, String, Numeric, DateTime, Boolean


class Despesa(Base):
    __tablename__ = "despesas"

    id = Column(Integer, primary_key=True, index=True)
    categoria = Column(String(50), nullable=False)
    valor = Column(Numeric(10, 2), nullable=False)
    data = Column(DateTime(timezone=True), nullable=False)
    da_gaveta = Column(Boolean, nullable=False, default=False)
