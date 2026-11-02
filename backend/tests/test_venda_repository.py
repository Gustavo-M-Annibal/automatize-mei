"""Testes do VendaRepository (SQLite em memória; não precisa do PostgreSQL)."""
from datetime import date, datetime
from decimal import Decimal

import pytest
import pytz
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from database.connection import Base
import backend.app.models  # noqa: F401 — registra os modelos no metadata
from backend.app.core.timezone import get_business_day
from backend.app.models.venda_model import VendaModel
from backend.app.repositories import fechamento_repository
from backend.app.repositories import venda_repository as vr
from backend.app.repositories.venda_repository import VendaRepository
from backend.app.schemas.venda_schema import VendaRegistrada
from backend.app.services.fechamento_service import DiaJaFechadoError

BRT = pytz.timezone("America/Sao_Paulo")
DIA = date(2026, 10, 20)


def _brt(dia: date, hora: int) -> datetime:
    return BRT.localize(datetime(dia.year, dia.month, dia.day, hora, 0))


@pytest.fixture
def db():
    engine = create_engine("sqlite://", connect_args={"check_same_thread": False}, poolclass=StaticPool)
    Base.metadata.create_all(bind=engine)
    sessao = sessionmaker(bind=engine, autoflush=False)()
    try:
        yield sessao
    finally:
        sessao.close()
        Base.metadata.drop_all(bind=engine)
        engine.dispose()


def _agora(monkeypatch, dia: date, hora: int = 15):
    """Congela o 'agora' que o repositório usa."""
    monkeypatch.setattr(vr, "agora_negocio", lambda: _brt(dia, hora))


def _fechar(db, dia: date):
    fechamento_repository.criar(
        db=db, data=_brt(dia, 19), data_dia=dia,
        troco_inicial=Decimal("0"), vendas_dinheiro=Decimal("0"), saidas_gaveta=Decimal("0"),
        contado_dinheiro=Decimal("0"), total_cartao=Decimal("0"),
    )


def test_criar_registra_venda_no_dia_de_negocio(db, monkeypatch):
    _agora(monkeypatch, DIA)
    venda = VendaRepository(db).criar(produto_id=1, quantidade=2, valor=Decimal("5.00"), forma_pagamento="pix")
    assert venda.id is not None
    assert get_business_day(venda.data) == DIA
    assert venda.valor == Decimal("5.00")


def test_criar_em_dia_fechado_levanta_erro_e_nao_grava(db, monkeypatch):
    _fechar(db, DIA)
    _agora(monkeypatch, DIA)
    with pytest.raises(DiaJaFechadoError):
        VendaRepository(db).criar(1, 2, Decimal("5.00"), "dinheiro")
    assert db.query(VendaModel).count() == 0


def test_fechamento_de_outro_dia_nao_bloqueia(db, monkeypatch):
    _fechar(db, date(2026, 10, 19))
    _agora(monkeypatch, DIA)
    venda = VendaRepository(db).criar(1, 1, Decimal("2.50"), "dinheiro")
    assert venda.id is not None


def test_listar_do_dia_traz_so_vendas_do_dia(db, monkeypatch):
    db.add_all([
        VendaModel(produto_id=1, quantidade=1, valor=Decimal("2.50"), forma_pagamento="pix", data=_brt(DIA, 8)),
        VendaModel(produto_id=1, quantidade=2, valor=Decimal("5.00"), forma_pagamento="dinheiro", data=_brt(DIA, 15)),
        VendaModel(produto_id=1, quantidade=1, valor=Decimal("2.50"), forma_pagamento="pix", data=_brt(date(2026, 10, 19), 15)),
    ])
    db.commit()
    repo = VendaRepository(db)

    do_dia = repo.listar_do_dia(DIA)
    assert [v.quantidade for v in do_dia] == [1, 2]      # ordenadas por horário; a de ontem ficou fora

    _agora(monkeypatch, DIA)
    assert len(repo.listar_do_dia()) == 2                # sem argumento = hoje (fuso de negócio)


def test_deletar_remove_a_venda(db, monkeypatch):
    _agora(monkeypatch, DIA)
    repo = VendaRepository(db)
    venda = repo.criar(1, 1, Decimal("2.50"), "pix")
    repo.deletar(repo.buscar_por_id(venda.id))
    assert repo.buscar_por_id(venda.id) is None


def test_deletar_em_dia_fechado_levanta_erro_e_mantem_a_venda(db, monkeypatch):
    _agora(monkeypatch, DIA)
    repo = VendaRepository(db)
    venda = repo.criar(1, 1, Decimal("2.50"), "pix")
    _fechar(db, DIA)
    with pytest.raises(DiaJaFechadoError):
        repo.deletar(repo.buscar_por_id(venda.id))
    assert repo.buscar_por_id(venda.id) is not None


def test_buscar_por_id_inexistente_retorna_none(db):
    assert VendaRepository(db).buscar_por_id(999) is None


def test_schema_serializa_objeto_do_banco(db, monkeypatch):
    _agora(monkeypatch, DIA)
    venda = VendaRepository(db).criar(1, 2, Decimal("5.00"), "pix")
    resposta = VendaRegistrada.model_validate(venda)
    assert resposta.valor == Decimal("5.00") and resposta.forma_pagamento == "pix"