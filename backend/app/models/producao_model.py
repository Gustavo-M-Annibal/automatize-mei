from database.connection import Base
from sqlalchemy import Column, Float, Integer, String


class ProducaoModel(Base):
  __tablename__ = "producao"

  id = Column(Integer, primary_key=True)
  fk_produto_id = Column(Integer, nullable=False)
  fk_usuario_id = Column(Integer, nullable=False)
  quantidade = Column(Float, nullable=False, default=0.0)  
  valor_total = Column(Float, nullable=False, default=0.0)  