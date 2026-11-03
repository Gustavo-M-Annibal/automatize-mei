from datetime import datetime, timedelta, timezone
from decimal import Decimal

import pytz
import pytest
from pydantic import ValidationError

from backend.app.schemas.despesa_schema import DespesaCreate


def criar_dados(data: datetime, valor: Decimal = Decimal("10.00")) -> dict:
    return {
        "categoria": " ingredientes ",
        "valor": valor,
        "data": data,
        "da_gaveta": True,
    }


def test_data_sem_fuso_e_interpretada_com_fuso_de_sao_paulo():
    despesa = DespesaCreate(**criar_dados(datetime(2026, 1, 15, 12, 0)))

    assert despesa.data.tzinfo.zone == "America/Sao_Paulo"
    assert despesa.data.utcoffset() == timedelta(hours=-3)


def test_data_com_fuso_e_convertida_para_sao_paulo():
    data_utc = datetime(2026, 1, 15, 15, 0, tzinfo=timezone.utc)

    despesa = DespesaCreate(**criar_dados(data_utc))

    assert despesa.data.hour == 12
    assert despesa.data.tzinfo.zone == "America/Sao_Paulo"


def test_valor_deve_ser_positivo():
    with pytest.raises(ValidationError):
        DespesaCreate(**criar_dados(datetime(2026, 1, 15, 12, 0), Decimal("0")))