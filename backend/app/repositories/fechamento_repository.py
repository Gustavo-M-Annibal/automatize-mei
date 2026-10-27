from datetime import date, datetime
from decimal import Decimal

from sqlalchemy import func
from sqlalchemy.orm import Session

from backend.app.core.timezone import get_day_utc_bounds
from backend.app.models.despesa_model import Despesa
from backend.app.models.fechamento_model import Fechamento
from backend.app.models.venda_model import Venda


def listar_todos(db: Session) -> list[Fechamento]:
  return db.query(Fechamento).order_by(Fechamento.data).all()


def buscar_por_dia(db: Session, data_dia: date) -> Fechamento | None:
  return db.query(Fechamento).filter(Fechamento.data_dia == data_dia).first()


def buscar_por_id(db: Session, fechamento_id: int) -> Fechamento | None:
  return db.query(Fechamento).filter(Fechamento.id == fechamento_id).first()


def calcular_totais_dia(db: Session, data_dia: date) -> dict:
  """Recalcula vendas_dinheiro, total_cartao e saidas_gaveta do dia a partir dos registros."""
  inicio, fim = get_day_utc_bounds(data_dia)

  vendas_dinheiro = (
      db.query(func.coalesce(func.sum(Venda.valor), 0))
      .filter(
          Venda.data >= inicio,
          Venda.data <= fim,
          Venda.forma_pagamento == "dinheiro",
      )
      .scalar()
  )

  total_cartao = (
      db.query(func.coalesce(func.sum(Venda.valor), 0))
      .filter(
          Venda.data >= inicio,
          Venda.data <= fim,
          Venda.forma_pagamento == "cartao",
      )
      .scalar()
  )

  saidas_gaveta = (
      db.query(func.coalesce(func.sum(Despesa.valor), 0))
      .filter(
          Despesa.data >= inicio, Despesa.data <= fim, Despesa.da_gaveta.is_(True)
      )
      .scalar()
  )

  return {
      "vendas_dinheiro": Decimal(str(vendas_dinheiro)),
      "total_cartao": Decimal(str(total_cartao)),
      "saidas_gaveta": Decimal(str(saidas_gaveta)),
  }


def criar(
    db: Session,
    data: datetime,
    data_dia: date,
    troco_inicial: Decimal,
    vendas_dinheiro: Decimal,
    saidas_gaveta: Decimal,
    contado_dinheiro: Decimal,
    total_cartao: Decimal,
) -> Fechamento:
  fechamento = Fechamento(
      data=data,
      data_dia=data_dia,
      troco_inicial=troco_inicial,
      vendas_dinheiro=vendas_dinheiro,
      saidas_gaveta=saidas_gaveta,
      contado_dinheiro=contado_dinheiro,
      total_cartao=total_cartao,
  )
  db.add(fechamento)
  db.commit()
  db.refresh(fechamento)
  return fechamento


def deletar(db: Session, fechamento: Fechamento) -> None:
  db.delete(fechamento)
  db.commit()