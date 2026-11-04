from backend.app.services.despesa_service import CategoriaInvalidaError, DespesaNaoEncontradaError
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from backend.app.core.db import get_db
from backend.app.schemas.despesa_schema import DespesaCreate, DespesaResponse
from backend.app.services import despesa_service as service
from backend.app.services.fechamento_service import DiaJaFechadoError

router = APIRouter(prefix="/despesas", tags=["Despesas"])


@router.get(
    "",
    response_model=list[DespesaResponse],
    summary="Listar despesas",
    description="Retorna todas as despesas cadastradas em ordem cronológica, sem filtro de data.",
)
def listar_despesas(db: Session = Depends(get_db)):
    return service.listar_despesas(db)


@router.post(
    "",
    response_model=DespesaResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Registrar despesa",
    description=(
        "Registra uma despesa com categoria, valor, data e indicação se saiu da gaveta. "
        "Retorna 409 se a despesa for da gaveta e o dia já estiver com caixa fechado."
    ),
    responses={
        409: {"description": "O caixa do dia já foi fechado; despesas da gaveta não são permitidas."},
        422: {"description": "Dados inválidos (categoria desconhecida, valor negativo, etc.)."},
    },
)
def criar_despesa(dados: DespesaCreate, db: Session = Depends(get_db)):
    try:
        return service.criar_despesa(db, dados)
    except CategoriaInvalidaError as exc:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail=str(exc)) from exc
    except DiaJaFechadoError as exc:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=str(exc)) from exc


@router.delete(
    "/{despesa_id}",
    summary="Remover despesa",
    description=(
        "Remove uma despesa pelo id. "
        "Retorna 409 se a despesa for da gaveta e o dia já tiver fechamento de caixa."
    ),
    responses={
        404: {"description": "Despesa não encontrada."},
        409: {"description": "O caixa do dia já foi fechado; a despesa da gaveta não pode ser removida."},
    },
)
def deletar_despesa(despesa_id: int, db: Session = Depends(get_db)):
    try:
        service.deletar_despesa(db, despesa_id)
        return {"detail": "Despesa removida com sucesso."}
    except DespesaNaoEncontradaError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc)) from exc
    except DiaJaFechadoError as exc:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=str(exc)) from exc
