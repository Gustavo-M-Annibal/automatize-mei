from datetime import datetime
from decimal import Decimal
from typing import Optional

from pydantic import BaseModel, ConfigDict


class FechamentoCreate(BaseModel):
    data: datetime
    troco_inicial: Decimal
    contado_dinheiro: Decimal
    vendas_dinheiro: Optional[Decimal] = None
    saidas_gaveta: Optional[Decimal] = None
    total_cartao: Optional[Decimal] = None


class FechamentoResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    data: datetime
    troco_inicial: Decimal
    vendas_dinheiro: Decimal
    saidas_gaveta: Decimal
    contado_dinheiro: Decimal
    total_cartao: Decimal
