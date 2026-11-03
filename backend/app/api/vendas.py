from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import text
from sqlalchemy.orm import Session

from backend.app.core.db import get_db
from backend.app.models.venda_model import VendaModel
from backend.app.repositories.venda_repository import VendaRepository
from backend.app.schemas.venda_schema import VendaCreate, VendaRegistrada
from backend.app.services import venda_service
from backend.app.services.fechamento_service import DiaJaFechadoError

router = APIRouter(prefix="/vendas", tags=["Vendas"])


@router.get("", response_model=list[VendaRegistrada])
def listar(db: Session = Depends(get_db)):
    return db.query(VendaModel).order_by(VendaModel.data).all()


@router.post("", status_code=status.HTTP_201_CREATED)
def registrar(dados: VendaCreate, db: Session = Depends(get_db)):
    try:
        result = venda_service.registrar_venda(db, dados)
        return result["vendas"][0]
    except venda_service.ProdutoNaoEncontradoError as exc:
        raise HTTPException(status_code=404, detail=f"Produto {exc.produto_id} não encontrado.") from exc
    except venda_service.EstoqueInsuficienteError as exc:
        raise HTTPException(
            status_code=400,
            detail=(
                f"Estoque insuficiente para o produto {exc.produto_id}: "
                f"pedido {exc.solicitado}, disponível {exc.disponivel}."
            ),
        ) from exc


@router.delete("/{venda_id}")
def cancelar(venda_id: int, db: Session = Depends(get_db)):
    repo = VendaRepository(db)
    venda = repo.buscar_por_id(venda_id)
    if not venda:
        raise HTTPException(status_code=404, detail="Venda não encontrada.")
    try:
        db.execute(
            text("UPDATE produtos SET estoque = estoque + :qtd WHERE id = :id"),
            {"qtd": venda.quantidade, "id": venda.produto_id},
        )
        repo.deletar(venda)
    except DiaJaFechadoError as exc:
        db.rollback()
        raise HTTPException(status_code=409, detail=str(exc)) from exc
    return {"detail": "Venda cancelada."}
