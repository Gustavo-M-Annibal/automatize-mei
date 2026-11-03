
from datetime import date
from decimal import Decimal

from sqlalchemy.orm import Session

from backend.app.core.timezone import (
    agora_negocio,
    get_business_day
)
from backend.app.repositories.despesa_repository import DespesaRepository
from backend.app.repositories import fechamento_repository
from backend.app.services.fechamento_service import DiaJaFechadoError
from backend.app.schemas.despesa_schema import DespesaCreate

CATEGORIAS_VALIDAS = {
    "ingredientes",
    "embalagem",
    "gas",
    "outros"
}

class CategoriaInvalidaError(Exception):
    pass


class DespesaNaoEncontradaError(Exception):
    pass


def verificar_categoria(categoria: str) -> None:
    if categoria not in CATEGORIAS_VALIDAS:
        raise CategoriaInvalidaError(
            f"Categoria '{categoria}' não é válida."
        )


def verificar_dia_aberto(db: Session, dia: date) -> None:
    fechamento = fechamento_repository.buscar_por_dia(db, dia)

    if fechamento:
        raise DiaJaFechadoError(
            f"O dia {dia} já está fechado. "
            "Não é possível alterar despesas da gaveta."
        )


def listar_despesas(db: Session):
    return DespesaRepository(db).listar_todas()


def criar_despesa(db: Session, dados: DespesaCreate):

    verificar_categoria(dados.categoria)

    dia_despesa = get_business_day(dados.data)

    if dados.da_gaveta:
        verificar_dia_aberto(db, dia_despesa)

    repo = DespesaRepository(db)

    return repo.criar(
        categoria=dados.categoria,
        valor=dados.valor,
        data=dados.data,
        da_gaveta=dados.da_gaveta
    )


def deletar_despesa(db: Session, despesa_id: int):

    repo = DespesaRepository(db)

    despesa = repo.buscar_por_id(despesa_id)

    if not despesa:
        raise DespesaNaoEncontradaError(
            f"Despesa {despesa_id} não encontrada."
        )

    if despesa.da_gaveta:
        dia_despesa = get_business_day(despesa.data)
        verificar_dia_aberto(db, dia_despesa)

    repo.deletar(despesa)