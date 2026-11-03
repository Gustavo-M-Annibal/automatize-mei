
from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field, field_validator


class DespesaCreate(BaseModel):
    categoria: str = Field(min_length=1, max_length=50)
    valor: Decimal = Field(ge=0, max_digits=10, decimal_places=2)
    data: datetime
    da_gaveta: bool

    @field_validator("categoria")
    @classmethod
    def validar_categoria_texto(cls, valor):
        return valor.strip().lower()


class DespesaResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    categoria: str
    valor: Decimal
    data: datetime
    da_gaveta: bool