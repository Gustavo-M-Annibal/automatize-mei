from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy import text
from sqlalchemy.orm import Session

from backend.app.core.db import get_db
from backend.app.models.perda_model import PerdaModel

router = APIRouter(prefix="/perdas", tags=["Perdas"])


class PerdaCreate(BaseModel):
    produto_id: int = Field(gt=0)
    quantidade: int = Field(gt=0)


@router.post("", status_code=status.HTTP_201_CREATED)
def registrar_perda(dados: PerdaCreate, db: Session = Depends(get_db)):
    row = db.execute(
        text("SELECT id, estoque FROM produtos WHERE id = :id"), {"id": dados.produto_id}
    ).fetchone()
    if not row:
        raise HTTPException(status_code=404, detail=f"Produto {dados.produto_id} não encontrado.")
    if row.estoque < dados.quantidade:
        raise HTTPException(
            status_code=400,
            detail=f"Estoque insuficiente: disponível {row.estoque}, solicitado {dados.quantidade}.",
        )

    db.execute(
        text("UPDATE produtos SET estoque = estoque - :qtd WHERE id = :id"),
        {"qtd": dados.quantidade, "id": dados.produto_id},
    )

    perda = PerdaModel(produto_id=dados.produto_id, quantidade=dados.quantidade)
    db.add(perda)
    db.commit()
    db.refresh(perda)

    return {
        "id": perda.id,
        "produto_id": perda.produto_id,
        "quantidade": perda.quantidade,
        "data": perda.data,
    }
