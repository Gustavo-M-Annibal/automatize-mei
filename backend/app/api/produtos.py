from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from backend.app.core.db import get_db
from backend.app.schemas.produto_schema import ProdutoCreate, ProdutoResponse, ProdutoUpdate
from backend.app.services.produto_service import EstoqueInsuficienteError, ProdutoNaoEncontradoError, ProdutoService

router = APIRouter(prefix="/produtos", tags=["Produtos"])


@router.get("", response_model=list[ProdutoResponse])
def listar(db: Session = Depends(get_db)):
    return ProdutoService(db).listar_produtos()


@router.post("", response_model=ProdutoResponse, status_code=status.HTTP_201_CREATED)
def criar(dados: ProdutoCreate, db: Session = Depends(get_db)):
    return ProdutoService(db).criar_produto(dados)


@router.put("/{produto_id}", response_model=ProdutoResponse)
def atualizar(produto_id: int, dados: ProdutoUpdate, db: Session = Depends(get_db)):
    try:
        return ProdutoService(db).atualizar_produto(produto_id, dados)
    except ProdutoNaoEncontradoError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc


@router.delete("/{produto_id}")
def deletar(produto_id: int, db: Session = Depends(get_db)):
    try:
        ProdutoService(db).deletar_produto(produto_id)
        return {"detail": "Produto removido."}
    except ProdutoNaoEncontradoError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    except ValueError as exc:
        raise HTTPException(status_code=409, detail=str(exc)) from exc
