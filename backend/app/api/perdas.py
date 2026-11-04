from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from backend.app.core.db import get_db
from backend.app.services import perda_service

router = APIRouter(prefix="/perdas", tags=["Perdas"])


class PerdaCreate(BaseModel):
    produto_id: int = Field(gt=0)
    quantidade: int = Field(gt=0)


@router.post("", status_code=status.HTTP_201_CREATED)
def registrar_perda(dados: PerdaCreate, db: Session = Depends(get_db)):
    try:
        perda = perda_service.registrar(db, dados.produto_id, dados.quantidade)
    except perda_service.ProdutoNaoEncontradoError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    except perda_service.EstoqueInsuficienteError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    return {
        "id": perda.id,
        "produto_id": perda.produto_id,
        "quantidade": perda.quantidade,
        "data": perda.data,
    }
