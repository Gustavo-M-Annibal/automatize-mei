from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from ..core.db import get_db
from ..schemas.venda_schema import VendaCreate, VendaRegistrarResposta
from ..services import venda_service

router = APIRouter(prefix="/vendas", tags=["Vendas"])


@router.post("/", response_model=VendaRegistrarResposta, status_code=status.HTTP_201_CREATED)
def registrar(
    dados: VendaCreate,
    db: Session = Depends(get_db),
):
    try:
        return venda_service.registrar_venda(db, dados)
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