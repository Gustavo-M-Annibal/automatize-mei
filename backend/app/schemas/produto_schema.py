from decimal import Decimal
from typing import Optional
from pydantic import BaseModel, ConfigDict, Field, field_validator


class ProdutoCreate(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    
    nome: str = Field(description="Nome do produto.")
    preco: Decimal = Field(description="Preço do produto em reais.")
    estoque: Optional[int] = Field(
        default=None,
        description="Quantidade em estoque do produto. Se não informado, o estoque será considerado infinito.",
    )

    @field_validator("estoque")
    @classmethod
    def validar_estoque_nao_negativo(cls, v: Optional[int]) -> Optional[int]:
        if v is not None and v < 0:
            raise ValueError("O estoque não pode ficar negativo.")
        return v


class ProdutoUpdate(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    
    nome: Optional[str] = Field(default=None, description="Nome do produto.")
    preco: Optional[Decimal] = Field(default=None, description="Preço do produto em reais.")
    estoque: Optional[int] = Field(default=None, description="Quantidade em estoque do produto.")

    @field_validator("estoque")
    @classmethod
    def validar_estoque_nao_negativo(cls, v: Optional[int]) -> Optional[int]:
        if v is not None and v < 0:
            raise ValueError("O estoque não pode ficar negativo.")
        return v


class ProdutoMovimentacaoEstoque(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    
    quantidade: int = Field(gt=0, description="Quantidade a ser movimentada (deve ser maior que zero).")


class ProdutoResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    
    id: int
    nome: str
    preco: Decimal
    estoque: Optional[int]