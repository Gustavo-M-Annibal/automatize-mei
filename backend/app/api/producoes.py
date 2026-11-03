from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy import text
from sqlalchemy.orm import Session

from backend.app.core.db import get_db
from backend.app.models.producao_model import ProducaoModel

router = APIRouter(prefix="/producoes", tags=["Produções"])


class ProducaoCreate(BaseModel):
    produto_id: int = Field(gt=0)
    quantidade: int = Field(gt=0)


@router.post("", status_code=status.HTTP_201_CREATED)
def registrar_producao(dados: ProducaoCreate, db: Session = Depends(get_db)):
    existe = db.execute(
        text("SELECT id FROM produtos WHERE id = :id"), {"id": dados.produto_id}
    ).fetchone()
    if not existe:
        raise HTTPException(status_code=404, detail=f"Produto {dados.produto_id} não encontrado.")

    db.execute(
        text("UPDATE produtos SET estoque = estoque + :qtd WHERE id = :id"),
        {"qtd": dados.quantidade, "id": dados.produto_id},
    )

    producao = ProducaoModel(produto_id=dados.produto_id, quantidade=dados.quantidade)
    db.add(producao)
    db.commit()
    db.refresh(producao)

    return {
        "id": producao.id,
        "produto_id": producao.produto_id,
        "quantidade": producao.quantidade,
        "data": producao.data,
    }
