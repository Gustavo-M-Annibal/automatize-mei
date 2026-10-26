from datetime import datetime
from decimal import Decimal
from typing import Literal

from pydantic import BaseModel, Field


class ItemVendaCreate(BaseModel):
    produto_id: int = Field(gt=0)
    quantidade: int = Field(gt=0, le=1000)


class VendaRegistrar(BaseModel):
    forma_pagamento: Literal["dinheiro", "pix"]
    itens: list[ItemVendaCreate] = Field(min_length=1, max_length=50)


class VendaRegistrada(BaseModel):
    id: int
    produto_id: int
    quantidade: int
    valor: Decimal
    data: datetime
    forma_pagamento: str


class VendaRegistrarResposta(BaseModel):
    vendas: list[VendaRegistrada]
    total: Decimal