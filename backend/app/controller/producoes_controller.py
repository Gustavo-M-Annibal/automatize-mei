from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from backend.app.core.db import get_db
from backend.app.core.deps import obter_usuario_atual
from backend.app.services import producao_service

router = APIRouter(
    prefix="/producoes",
    tags=["Produções"],
    dependencies=[Depends(obter_usuario_atual)],
)


class ProducaoCreate(BaseModel):
    produto_id: int = Field(gt=0)
    quantidade: int = Field(gt=0)


@router.post(
    "",
    status_code=status.HTTP_201_CREATED,
    summary="Registrar produção",
    description=(
        "Registra uma entrada de produção para um produto e incrementa seu estoque pela quantidade informada. "
        "Retorna o registro criado com id, produto_id, quantidade e data."
    ),
    responses={
        404: {"description": "Produto não encontrado."},
        422: {"description": "Dados inválidos (produto_id ou quantidade inválidos)."},
    },
)
def registrar_producao(dados: ProducaoCreate, db: Session = Depends(get_db)):
    try:
        producao = producao_service.registrar(db, dados.produto_id, dados.quantidade)
    except producao_service.ProdutoNaoEncontradoError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    return {
        "id": producao.id,
        "produto_id": producao.produto_id,
        "quantidade": producao.quantidade,
        "data": producao.data,
    }
