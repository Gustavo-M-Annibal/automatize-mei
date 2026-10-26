from datetime import datetime
from decimal import Decimal
from typing import Literal

from pydantic import BaseModel, Field


class VendaCreate(BaseModel):
    produto_id: int = Field(gt=0)
    quantidade: int = Field(gt=0, le=1000)
    forma_pagamento: Literal["dinheiro", "pix"]


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