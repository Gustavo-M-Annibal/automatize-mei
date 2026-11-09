from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from backend.app.core.db import get_db
from backend.app.core.deps import obter_usuario_atual
from backend.app.schemas.produto_schema import ProdutoCreate, ProdutoResponse, ProdutoUpdate
from backend.app.services.produto_service import ProdutoNaoEncontradoError, ProdutoService

router = APIRouter(
    prefix="/produtos",
    tags=["Produtos"],
    dependencies=[Depends(obter_usuario_atual)],
)


@router.get(
    "",
    response_model=list[ProdutoResponse],
    summary="Listar produtos",
    description="Retorna todos os produtos cadastrados com id, nome, preço e estoque atual.",
)
def listar(db: Session = Depends(get_db)):
    return ProdutoService(db).listar_produtos()


@router.post(
    "",
    response_model=ProdutoResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Criar produto",
    description="Cadastra um novo produto. O estoque inicial pode ser zero.",
    responses={422: {"description": "Dados inválidos (nome vazio, preço negativo, etc.)."}},
)
def criar(dados: ProdutoCreate, db: Session = Depends(get_db)):
    return ProdutoService(db).criar_produto(dados)


@router.put(
    "/{produto_id}",
    response_model=ProdutoResponse,
    summary="Atualizar produto",
    description="Atualiza nome, preço ou estoque de um produto existente. Apenas os campos enviados são alterados.",
    responses={
        404: {"description": "Produto não encontrado."},
        422: {"description": "Dados inválidos."},
    },
)
def atualizar(produto_id: int, dados: ProdutoUpdate, db: Session = Depends(get_db)):
    try:
        return ProdutoService(db).atualizar_produto(produto_id, dados)
    except ProdutoNaoEncontradoError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc


@router.delete(
    "/{produto_id}",
    summary="Remover produto",
    description="Remove um produto pelo id. Retorna 409 se o produto possuir histórico de vendas associado.",
    responses={
        404: {"description": "Produto não encontrado."},
        409: {"description": "Produto possui histórico de vendas e não pode ser removido."},
    },
)
def deletar(produto_id: int, db: Session = Depends(get_db)):
    try:
        ProdutoService(db).deletar_produto(produto_id)
        return {"detail": "Produto removido."}
    except ProdutoNaoEncontradoError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    except ValueError as exc:
        raise HTTPException(status_code=409, detail=str(exc)) from exc
