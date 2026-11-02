from decimal import Decimal
from typing import List, Optional
from sqlalchemy.orm import Session

from app.models.produto_model import ProdutoModel
from app.schemas.produto_schema import ProdutoCreate, ProdutoUpdate

# Exceções de Domínio

class ProdutoNaoEncontradoError(ValueError):
    def __init__(self, mensagem: str = 'Produto não encontrado.'):
        super().__init__(mensagem)
        
        
class EstoqueInsuficienteError(Exception):
    def __init__(self, mensagem: str = 'Estoque insuficiente para a quantidade de perda informada.'):
        super().__init__(mensagem)
        
class ProdutoService:
    def __init__(self, db: Session):
        self.db = db

    def criar_produto(self, dados: ProdutoCreate) -> ProdutoModel:
        produto = ProdutoModel(
            nome=dados.nome,
            preco=dados.preco,
            estoque=dados.estoque 
        )
        self.db.add(produto)
        self.db.commit()
        self.db.refresh(produto)
        return produto

    def buscar_por_id(self, produto_id: int) -> ProdutoModel:
        produto = self.db.query(ProdutoModel).filter(ProdutoModel.id == produto_id).first()
        if not produto:
            raise ProdutoNaoEncontradoError()
        return produto

    def listar_produtos(self) -> List[ProdutoModel]:
        return self.db.query(ProdutoModel).all()

    def atualizar_produto(self, produto_id: int, dados: ProdutoUpdate) -> ProdutoModel:
        produto = self.buscar_por_id(produto_id)
        
        update_data = dados.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            setattr(produto, key, value)
            
        self.db.commit()
        self.db.refresh(produto)
        return produto

    def deletar_produto(self, produto_id: int) -> None:
        produto = self.buscar_por_id(produto_id)
        
        if hasattr(produto, "vendas") and produto.vendas:
            raise ValueError("Não é possível excluir este produto pois ele possui histórico de vendas associado.")
        
        self.db.delete(produto)
        self.db.commit()

    def registrar_producao(self, produto_id: int, quantidade: int) -> ProdutoModel:
        produto = self.buscar_por_id(produto_id)
        
        if produto.estoque is not None:
            produto.estoque += quantidade
            self.db.commit()
            self.db.refresh(produto)
        return produto

    def registrar_perda(self, produto_id: int, quantidade: int) -> ProdutoModel:
        produto = self.buscar_por_id(produto_id)
        
        if produto.estoque is not None:
            if produto.estoque < quantidade:
                raise EstoqueInsuficienteError()
            
            produto.estoque -= quantidade
            self.db.commit()
            self.db.refresh(produto)
        return produto

    def calcular_preco_total(self, produto_id: int, quantidade: int) -> Decimal:
        produto = self.buscar_por_id(produto_id)
        return produto.preco * Decimal(quantidade)