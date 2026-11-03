from backend.app.services.despesa_service import CategoriaInvalidaError, DespesaNaoEncontradaError
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from backend.app.core.db import get_db
from backend.app.schemas.despesa_schema import DespesaCreate, DespesaResponse
from backend.app.services import despesa_service as service
from backend.app.services.fechamento_service import DiaJaFechadoError

router = APIRouter(prefix="/despesas", tags=["Despesas"])


@router.get("", response_model=list[DespesaResponse])
def listar_despesas(db: Session = Depends(get_db)):
    return service.listar_despesas(db)


@router.post("", response_model=DespesaResponse, status_code=status.HTTP_201_CREATED)
def criar_despesa(dados: DespesaCreate, db: Session = Depends(get_db)):
    try:
        return service.criar_despesa(db, dados)
    except CategoriaInvalidaError as exc:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail=str(exc)) from exc
    except DiaJaFechadoError as exc:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=str(exc)) from exc


@router.delete("/{despesa_id}")
def deletar_despesa(despesa_id: int, db: Session = Depends(get_db)):
    try:
        service.deletar_despesa(db, despesa_id)
        return {"detail": "Despesa removida com sucesso."}
    except DespesaNaoEncontradaError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc)) from exc
    except DiaJaFechadoError as exc:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=str(exc)) from exc
