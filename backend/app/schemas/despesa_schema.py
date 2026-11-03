
from datetime import datetime
from decimal import Decimal

import pytz
from pydantic import BaseModel, ConfigDict, Field, field_validator

from backend.app.core.config import BUSINESS_TZ


class DespesaCreate(BaseModel):
    categoria: str = Field(min_length=1, max_length=50)
    valor: Decimal = Field(gt=0, max_digits=10, decimal_places=2)
    data: datetime
    da_gaveta: bool

    @field_validator("categoria")
    @classmethod
    def validar_categoria_texto(cls, valor):
        return valor.strip().lower()

    @field_validator("data")
    @classmethod
    def normalizar_fuso_horario(cls, valor: datetime) -> datetime:
        fuso_negocio = pytz.timezone(BUSINESS_TZ)
        if valor.tzinfo is None:
            return fuso_negocio.localize(valor)
        return valor.astimezone(fuso_negocio)


class DespesaResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    categoria: str
    valor: Decimal
    data: datetime
    da_gaveta: bool