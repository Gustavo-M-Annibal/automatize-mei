from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from backend.app.core.db import get_db
from backend.app.core.deps import obter_usuario_atual
from backend.app.schemas.fechamento_schema import FechamentoCreate, FechamentoResponse
from backend.app.services import fechamento_service as service
from backend.app.services.fechamento_service import (
    DiaJaFechadoError,
    FechamentoNaoEncontradoError,
)

router = APIRouter(
    tags=["Fechamentos"],
    dependencies=[Depends(obter_usuario_atual)],
)


@router.get(
    "/fechamentos",
    response_model=list[FechamentoResponse],
    summary="Listar fechamentos",
    description=(
        "Retorna o histórico completo de fechamentos de caixa em ordem cronológica. "
        "Responde com array vazio quando não há nenhum fechamento registrado."
    ),
)
def listar_fechamentos(db: Session = Depends(get_db)):
    return service.listar_fechamentos(db)


@router.post(
    "/fechamentos",
    response_model=FechamentoResponse,
    status_code=201,
    summary="Fechar o caixa do dia",
    description=(
        "Registra o fechamento do dia civil informado em `data` (fuso America/Sao_Paulo). "
        "Os totais de `vendas_dinheiro`, `saidas_gaveta`, `total_cartao` e `total_pix` são recalculados "
        "pelo servidor a partir dos lançamentos existentes — os valores enviados pelo app são "
        "ignorados para esses campos. "
        "Após o fechamento, vendas, cancelamentos e despesas da gaveta daquele dia ficam bloqueados."
    ),
    responses={
        409: {"description": "O dia já possui um fechamento registrado."},
        422: {"description": "Dados inválidos no corpo da requisição."},
    },
)
def criar_fechamento(body: FechamentoCreate, db: Session = Depends(get_db)):
    try:
        return service.criar_fechamento(db, body)
    except DiaJaFechadoError as exc:
        raise HTTPException(status_code=409, detail=str(exc))


@router.delete(
    "/fechamentos/{fechamento_id}",
    summary="Reabrir / remover fechamento",
    description=(
        "Remove o fechamento pelo ID, reabrindo o caixa do dia correspondente. "
        "Após a reabertura, vendas, cancelamentos e despesas da gaveta voltam a ser permitidos. "
        "Retorna `404` se o fechamento não existir."
    ),
    responses={
        200: {"description": "Fechamento removido com sucesso."},
        404: {"description": "Fechamento não encontrado."},
    },
)
def deletar_fechamento(fechamento_id: int, db: Session = Depends(get_db)):
    try:
        service.deletar_fechamento(db, fechamento_id)
    except FechamentoNaoEncontradoError as exc:
        raise HTTPException(status_code=404, detail=str(exc))
    return {"detail": "Fechamento removido."}
