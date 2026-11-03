from backend.app.services.despesa_service import (
    CategoriaInvalidaError,
    DespesaNaoEncontradaError
)

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from backend.app.core.deps import obter_usuario_atual
from backend.app.core.db import get_db
from backend.app.schemas.despesa_schema import (
    DespesaCreate,
    DespesaResponse
)
from backend.app.services import despesa_service as service
from backend.app.services.fechamento_service import DiaJaFechadoError


router = APIRouter(
    prefix="/despesas",
    tags=["Despesas"],
    dependencies=[Depends(obter_usuario_atual)]
)


@router.get(
    "",
    response_model=list[DespesaResponse],
    summary="Listar despesas do dia",
    description=(
        "Retorna todas as despesas registradas no dia atual, "
        "considerando o fuso horário America/Sao_Paulo. "
        "Retorna uma lista vazia quando não existem despesas."
    ),
    responses={
        200: {"description": "Lista de despesas retornada com sucesso."}
    }
)
def listar_despesas(db: Session = Depends(get_db)):
    return service.listar_despesas(db)


@router.post(
    "",
    response_model=DespesaResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Registrar nova despesa",
    description=(
        "Registra uma despesa com categoria, valor, data e indicação "
        "se o pagamento saiu da gaveta. "
        "Despesas da gaveta não podem ser registradas em dias fechados."
    ),
    responses={
        201: {"description": "Despesa registrada com sucesso."},
        409: {"description": "O dia da despesa já está fechado."},
        422: {"description": "Categoria ou dados informados são inválidos."}
    }
)
def criar_despesa(
    dados: DespesaCreate,
    db: Session = Depends(get_db)
):
    try:
        return service.criar_despesa(db, dados)

    except CategoriaInvalidaError as exc:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=str(exc)
        ) from exc

    except DiaJaFechadoError as exc:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=str(exc)
        ) from exc


@router.delete(
    "/{despesa_id}",
    summary="Excluir despesa",
    description=(
        "Remove uma despesa pelo seu identificador. "
        "Despesas da gaveta não podem ser excluídas se o dia "
        "correspondente já estiver fechado."
    ),
    responses={
        200: {"description": "Despesa removida com sucesso."},
        404: {"description": "Despesa não encontrada."},
        409: {"description": "O dia da despesa já está fechado."}
    }
)
def deletar_despesa(
    despesa_id: int,
    db: Session = Depends(get_db)
):
    try:
        service.deletar_despesa(db, despesa_id)

        return {
            "detail": "Despesa removida com sucesso."
        }

    except DespesaNaoEncontradaError as exc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(exc)
        ) from exc

    except DiaJaFechadoError as exc:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=str(exc)
        ) from exc
