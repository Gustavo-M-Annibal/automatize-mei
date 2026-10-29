from database.connection import Base
from sqlalchemy import Column, Integer, DateTime, ForeignKey
from sqlalchemy.sql import func


class PerdaModel(Base):
    __tablename__ = "perdas"
    __table_args__ = {'extend_existing': True}

    id = Column(Integer, primary_key=True)
    produto_id = Column(Integer, ForeignKey("produto.id"), nullable=False)
    quantidade = Column(Integer, nullable=False)
    data = Column(DateTime(timezone=True), nullable=False, server_default=func.now())
