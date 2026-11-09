from datetime import datetime
from decimal import Decimal
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field


class FechamentoCreate(BaseModel):
    data: datetime = Field(
        description="Data e hora do fechamento em ISO-8601 com offset (ex.: 2026-10-20T19:00:00-03:00)."
    )
    troco_inicial: Decimal = Field(
        description="Valor em reais do troco colocado na gaveta no início do dia."
    )
    contado_dinheiro: Decimal = Field(
        description="Valor em reais contado fisicamente na gaveta ao fechar."
    )
    vendas_dinheiro: Optional[Decimal] = Field(
        default=None,
        description="Ignorado — o servidor recalcula a partir dos lançamentos.",
    )
    saidas_gaveta: Optional[Decimal] = Field(
        default=None,
        description="Ignorado — o servidor recalcula a partir dos lançamentos.",
    )
    total_cartao: Optional[Decimal] = Field(
        default=None,
        description="Ignorado — o servidor recalcula a partir dos lançamentos.",
    )
    total_pix: Optional[Decimal] = Field(
        default=None,
        description="Ignorado — o servidor recalcula a partir dos lançamentos.",
    )


class FechamentoResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int = Field(description="Identificador único do fechamento.")
    data: datetime = Field(description="Data e hora do fechamento com offset de fuso.")
    troco_inicial: Decimal = Field(description="Troco inicial informado pelo operador.")
    vendas_dinheiro: Decimal = Field(description="Total em dinheiro calculado pelo servidor.")
    saidas_gaveta: Decimal = Field(description="Total de saídas da gaveta calculado pelo servidor.")
    contado_dinheiro: Decimal = Field(description="Valor contado fisicamente informado pelo operador.")
    total_cartao: Decimal = Field(description="Total no cartão calculado pelo servidor.")
    total_pix: Decimal = Field(description="Total no Pix calculado pelo servidor.")
