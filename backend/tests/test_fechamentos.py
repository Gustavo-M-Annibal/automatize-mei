"""Testes de integração dos endpoints de fechamento."""

from datetime import datetime

import pytest

from backend.app.core.security import criar_access_token
from backend.app.services import venda_service


@pytest.fixture(autouse=True)
def autenticar_cliente(client):
    token = criar_access_token(data={"sub": "teste@exemplo.com"})
    client.headers.update({"Authorization": f"Bearer {token}"})


FECHAMENTO_PAYLOAD = {
    "data": "2026-10-20T19:00:00-03:00",
    "troco_inicial": 20.0,
    "contado_dinheiro": 94.5,
}


def test_listar_fechamentos_vazio(client):
    resp = client.get("/fechamentos")
    assert resp.status_code == 200
    assert resp.json() == []


def test_criar_fechamento_retorna_objeto_com_id(client):
    resp = client.post("/fechamentos", json=FECHAMENTO_PAYLOAD)
    assert resp.status_code == 201
    data = resp.json()
    assert "id" in data
    assert data["troco_inicial"] == "20.00"
    assert data["contado_dinheiro"] == "94.50"
    assert "vendas_dinheiro" in data
    assert "saidas_gaveta" in data
    assert "total_cartao" in data
    assert data["total_pix"] == "0.00"


def test_criar_fechamento_duplicado_retorna_409(client):
    client.post("/fechamentos", json=FECHAMENTO_PAYLOAD)
    resp = client.post("/fechamentos", json=FECHAMENTO_PAYLOAD)
    assert resp.status_code == 409
    assert "detail" in resp.json()
    assert isinstance(resp.json()["detail"], str)


def test_registrar_venda_em_dia_fechado_retorna_409(client, monkeypatch):
    monkeypatch.setattr(
        venda_service,
        "agora_negocio",
        lambda: datetime.fromisoformat("2026-10-20T15:00:00-03:00"),
    )
    client.post("/fechamentos", json=FECHAMENTO_PAYLOAD)

    resp = client.post(
        "/vendas",
        json={"produto_id": 999, "quantidade": 1, "forma_pagamento": "dinheiro"},
    )

    assert resp.status_code == 409
    assert "já possui fechamento" in resp.json()["detail"]


def test_deletar_fechamento_existente(client):
    criado = client.post("/fechamentos", json=FECHAMENTO_PAYLOAD)
    fechamento_id = criado.json()["id"]
    resp = client.delete(f"/fechamentos/{fechamento_id}")
    assert resp.status_code == 200
    assert resp.json()["detail"] == "Fechamento removido."


def test_deletar_fechamento_inexistente_retorna_404(client):
    resp = client.delete("/fechamentos/999")
    assert resp.status_code == 404
    assert isinstance(resp.json()["detail"], str)


def test_listar_fechamentos_apos_criar(client):
    client.post("/fechamentos", json=FECHAMENTO_PAYLOAD)
    resp = client.get("/fechamentos")
    assert resp.status_code == 200
    items = resp.json()
    assert len(items) == 1
    assert items[0]["troco_inicial"] == "20.00"


def test_reabrir_caixa_permite_novo_fechamento(client):
    criado = client.post("/fechamentos", json=FECHAMENTO_PAYLOAD)
    fechamento_id = criado.json()["id"]
    client.delete(f"/fechamentos/{fechamento_id}")
    resp = client.post("/fechamentos", json=FECHAMENTO_PAYLOAD)
    assert resp.status_code == 201
