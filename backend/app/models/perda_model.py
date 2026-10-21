from database.connection import Base
from sqlalchemy import Column, Integer, DateTime, ForeignKey
from sqlalchemy.sql import func


class Perda(Base):
    __tablename__ = "perdas"

    id = Column(Integer, primary_key=True, index=True)
    produto_id = Column(Integer, ForeignKey("produtos.id"), nullable=False)
    quantidade = Column(Integer, nullable=False)
    data = Column(DateTime(timezone=True), nullable=False, server_default=func.now())
