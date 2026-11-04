from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from backend.app.core.db import get_db
from backend.app.services import producao_service

router = APIRouter(prefix="/producoes", tags=["Produções"])


class ProducaoCreate(BaseModel):
    produto_id: int = Field(gt=0)
    quantidade: int = Field(gt=0)


@router.post("", status_code=status.HTTP_201_CREATED)
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
