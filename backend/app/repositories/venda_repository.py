from datetime import date
from decimal import Decimal

from sqlalchemy.orm import Session

from backend.app.core.timezone import agora_negocio, get_business_day, get_day_utc_bounds
from backend.app.models.venda_model import VendaModel
from backend.app.repositories import fechamento_repository
from backend.app.services.fechamento_service import DiaJaFechadoError


class VendaRepository:

  def __init__(self, db: Session):
    self.db = db

  def _garantir_dia_aberto(self, dia: date) -> None:
    """Regra de negócio: não se mexe em venda de um dia que já tem fechamento de caixa."""
    if fechamento_repository.buscar_por_dia(self.db, dia):
      raise DiaJaFechadoError(f"Dia {dia} já possui fechamento registrado.")

  def criar(
      self,
      produto_id: int,
      quantidade: int,
      valor: Decimal,
      forma_pagamento: str,
      commit: bool = True,
  ) -> VendaModel:
    agora = agora_negocio()  # data/hora atual no fuso America/Sao_Paulo (com fuso)
    self._garantir_dia_aberto(get_business_day(agora))

    venda = VendaModel(
        produto_id=produto_id,
        quantidade=quantidade,
        valor=valor,
        forma_pagamento=forma_pagamento,
        data=agora,
    )
    self.db.add(venda)
    if commit:
      self.db.commit()
      self.db.refresh(venda)
    else:
      self.db.flush()
    return venda

  def buscar_por_id(self, venda_id: int) -> VendaModel | None:
    return self.db.query(VendaModel).filter(VendaModel.id == venda_id).first()

  def listar_do_dia(self, dia: date | None = None) -> list[VendaModel]:
    dia = dia or get_business_day(agora_negocio())
    inicio, fim = get_day_utc_bounds(dia)  # 00:00 até 23:59:59 do dia, convertidos para UTC
    return (
        self.db.query(VendaModel)
        .filter(VendaModel.data >= inicio, VendaModel.data <= fim)
        .order_by(VendaModel.data, VendaModel.id)
        .all()
    )

  def deletar(self, venda: VendaModel, commit: bool = True) -> None:
    self._garantir_dia_aberto(get_business_day(venda.data))
    self.db.delete(venda)
    if commit:
      self.db.commit()
    else:
      self.db.flush()