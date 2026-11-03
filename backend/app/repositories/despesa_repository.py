
from datetime import date

from sqlalchemy.orm import Session

from backend.app.core.timezone import get_day_utc_bounds
from backend.app.models.despesa_model import DespesaModel


class DespesaRepository:

    def __init__(self, db: Session):
        self.db = db

    def listar_do_dia(self, dia: date) -> list[DespesaModel]:
        inicio, fim = get_day_utc_bounds(dia)

        return (
            self.db.query(DespesaModel)
            .filter(
                DespesaModel.data >= inicio,
                DespesaModel.data <= fim
            )
            .order_by(DespesaModel.data, DespesaModel.id)
            .all()
        )

    def criar(
        self,
        categoria: str,
        valor,
        data,
        da_gaveta: bool
    ) -> DespesaModel:

        despesa = DespesaModel(
            categoria=categoria,
            valor=valor,
            data=data,
            da_gaveta=da_gaveta
        )

        self.db.add(despesa)
        self.db.commit()
        self.db.refresh(despesa)

        return despesa

    def buscar_por_id(self, despesa_id: int) -> DespesaModel | None:
        return (
            self.db.query(DespesaModel)
            .filter(DespesaModel.id == despesa_id)
            .first()
        )

    def deletar(self, despesa: DespesaModel) -> None:
        self.db.delete(despesa)
        self.db.commit()