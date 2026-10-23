from datetime import datetime
from decimal import Decimal

from sqlalchemy.orm import Session

from backend.app.core.timezone import get_business_day
from backend.app.models.fechamento_model import Fechamento
from backend.app.repositories import fechamento_repository as repo
from backend.app.schemas.fechamento_schema import FechamentoCreate


class DiaJaFechadoError(Exception):
    pass


class FechamentoNaoEncontradoError(Exception):
    pass


def listar_fechamentos(db: Session) -> list[Fechamento]:
    return repo.listar_todos(db)


def criar_fechamento(db: Session, body: FechamentoCreate) -> Fechamento:
    data_dia = get_business_day(body.data)

    if repo.buscar_por_dia(db, data_dia):
        raise DiaJaFechadoError(f"Dia {data_dia} já possui fechamento registrado.")

    totais = repo.calcular_totais_dia(db, data_dia)

    return repo.criar(
        db=db,
        data=body.data,
        data_dia=data_dia,
        troco_inicial=body.troco_inicial,
        vendas_dinheiro=totais["vendas_dinheiro"],
        saidas_gaveta=totais["saidas_gaveta"],
        contado_dinheiro=body.contado_dinheiro,
        total_cartao=totais["total_cartao"],
    )


def deletar_fechamento(db: Session, fechamento_id: int) -> None:
    fechamento = repo.buscar_por_id(db, fechamento_id)
    if not fechamento:
        raise FechamentoNaoEncontradoError(f"Fechamento {fechamento_id} não encontrado.")
    repo.deletar(db, fechamento)
