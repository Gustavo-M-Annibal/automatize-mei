from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from backend.app.core.db import get_db
from backend.app.core.timezone import get_business_day
from backend.app.repositories import fechamento_repository as repo
from backend.app.schemas.fechamento_schema import FechamentoCreate, FechamentoResponse

router = APIRouter(tags=["fechamentos"])


@router.get("/fechamentos", response_model=list[FechamentoResponse])
def listar_fechamentos(db: Session = Depends(get_db)):
    return repo.listar_todos(db)


@router.post("/fechamentos", response_model=FechamentoResponse, status_code=201)
def criar_fechamento(body: FechamentoCreate, db: Session = Depends(get_db)):
    data_dia = get_business_day(body.data)

    if repo.buscar_por_dia(db, data_dia):
        raise HTTPException(status_code=409, detail="Já existe um fechamento para este dia.")

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


@router.delete("/fechamentos/{fechamento_id}")
def deletar_fechamento(fechamento_id: int, db: Session = Depends(get_db)):
    fechamento = repo.buscar_por_id(db, fechamento_id)
    if not fechamento:
        raise HTTPException(status_code=404, detail="Fechamento não encontrado.")
    repo.deletar(db, fechamento)
    return {"detail": "Fechamento removido."}
