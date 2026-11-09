from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from backend.app.core.db import get_db
from backend.app.core.deps import obter_usuario_atual
from backend.app.schemas.venda_schema import VendaCreate, VendaRegistrada
from backend.app.services import venda_service
from backend.app.services.fechamento_service import DiaJaFechadoError

router = APIRouter(
    prefix="/vendas",
    tags=["Vendas"],
    dependencies=[Depends(obter_usuario_atual)],
)


@router.get(
    "",
    response_model=list[VendaRegistrada],
    summary="Listar vendas",
    description="Retorna todas as vendas registradas em ordem cronológica, sem filtro de data.",
)
def listar(db: Session = Depends(get_db)):
    return venda_service.listar_vendas(db)


@router.post(
    "",
    status_code=status.HTTP_201_CREATED,
    summary="Registrar venda",
    description=(
        "Registra uma venda e baixa o estoque do produto atomicamente. "
        "O valor total é calculado pelo servidor com base no preço atual do produto. "
        "Aceita forma_pagamento: 'dinheiro' ou 'cartao'."
    ),
    responses={
        400: {"description": "Estoque insuficiente para a quantidade solicitada."},
        409: {"description": "O dia da venda já possui fechamento de caixa."},
        404: {"description": "Produto não encontrado."},
        422: {"description": "Dados inválidos (quantidade zero, forma_pagamento inválida, etc.)."},
    },
)
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
    except DiaJaFechadoError as exc:
        raise HTTPException(status_code=409, detail=str(exc)) from exc


@router.delete(
    "/{venda_id}",
    summary="Cancelar venda",
    description=(
        "Cancela uma venda pelo id e restaura o estoque do produto. "
        "Retorna 409 se o dia da venda já tiver fechamento de caixa registrado."
    ),
    responses={
        404: {"description": "Venda não encontrada."},
        409: {"description": "O dia da venda já possui fechamento de caixa e não pode ser alterado."},
    },
)
def cancelar(venda_id: int, db: Session = Depends(get_db)):
    try:
        venda_service.cancelar_venda(db, venda_id)
    except venda_service.VendaNaoEncontradaError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    except DiaJaFechadoError as exc:
        raise HTTPException(status_code=409, detail=str(exc)) from exc
    return {"detail": "Venda cancelada."}
