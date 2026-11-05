"""Testes do login (POST /auth/login) e do JWT gerado.

Usa SQLite em memória só com a tabela de usuários. Não depende do PostgreSQL.
"""
from datetime import datetime, timedelta, timezone

import pytest
from fastapi import Depends, FastAPI
from fastapi.testclient import TestClient
from jose import jwt
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from backend.app.core import security
from backend.app.core.db import get_db
from backend.app.core.deps import obter_usuario_atual
from backend.app.main import app
from backend.app.models.usuario_model import UsuarioModel
from database.connection import Base

EMAIL = "maria@exemplo.com"
SENHA = "Senha#Forte123"


@pytest.fixture
def ctx():
    """Entrega (cliente HTTP, fábrica de sessões) com um banco limpo por teste."""
    # StaticPool: o SQLite em memória só existe dentro de UMA conexão; sem isso as
    # rotas (que rodam em outra thread) enxergariam um banco vazio.
    engine = create_engine("sqlite://", connect_args={"check_same_thread": False}, poolclass=StaticPool)
    UsuarioModel.__table__.create(bind=engine)
    Sessao = sessionmaker(bind=engine, autoflush=False)

    def override_get_db():
        db = Sessao()
        try:
            yield db
        finally:
            db.close()

    app.dependency_overrides[get_db] = override_get_db
    try:
        with TestClient(app) as client:
            client.post("/auth/register", json={"nome": "Maria", "email": EMAIL, "senha": SENHA})
            yield client, Sessao
    finally:
        app.dependency_overrides.clear()
        engine.dispose()


def _login(client, email=EMAIL, senha=SENHA):
    # O login usa formulário (OAuth2), NÃO JSON: campos "username" e "password".
    return client.post("/auth/login", data={"username": email, "password": senha})


def _app_com_rota_protegida() -> TestClient:
    """Mini-app só para provar que o token funciona numa rota protegida de verdade."""
    mini = FastAPI()

    @mini.get("/protegida")
    def protegida(usuario: str = Depends(obter_usuario_atual)):
        return {"usuario": usuario}

    return TestClient(mini)


def test_login_valido_retorna_access_token_e_bearer(ctx):
    client, _ = ctx
    resp = _login(client)
    assert resp.status_code == 200
    corpo = resp.json()
    assert set(corpo) == {"access_token", "token_type"}
    assert corpo["token_type"] == "bearer"
    assert corpo["access_token"]


def test_token_identifica_o_usuario_e_expira_no_prazo(ctx):
    client, _ = ctx
    token = _login(client).json()["access_token"]
    payload = jwt.decode(token, security.SECRET_KEY, algorithms=[security.ALGORITHM])

    assert payload["sub"] == EMAIL
    agora = datetime.now(timezone.utc).timestamp()
    prazo = security.ACCESS_TOKEN_EXPIRE_MINUTES * 60
    assert agora < payload["exp"] <= agora + prazo + 5


def test_token_funciona_em_rota_protegida(ctx):
    client, _ = ctx
    token = _login(client).json()["access_token"]
    protegida = _app_com_rota_protegida()

    ok = protegida.get("/protegida", headers={"Authorization": f"Bearer {token}"})
    assert ok.status_code == 200 and ok.json() == {"usuario": EMAIL}

    assert protegida.get("/protegida").status_code == 401
    assert protegida.get("/protegida", headers={"Authorization": "Bearer lixo"}).status_code == 401


def test_token_expirado_e_rejeitado(ctx):
    expirado = jwt.encode(
        {"sub": EMAIL, "exp": datetime.now(timezone.utc) - timedelta(minutes=1)},
        security.SECRET_KEY,
        algorithm=security.ALGORITHM,
    )
    resp = _app_com_rota_protegida().get("/protegida", headers={"Authorization": f"Bearer {expirado}"})
    assert resp.status_code == 401


def test_token_assinado_com_outra_chave_e_rejeitado(ctx):
    falso = jwt.encode(
        {"sub": EMAIL, "exp": datetime.now(timezone.utc) + timedelta(minutes=5)},
        "uma-chave-diferente-" * 3,
        algorithm=security.ALGORITHM,
    )
    resp = _app_com_rota_protegida().get("/protegida", headers={"Authorization": f"Bearer {falso}"})
    assert resp.status_code == 401


def test_senha_incorreta_retorna_400(ctx):
    client, _ = ctx
    resp = _login(client, senha="senha-errada-123")
    assert resp.status_code == 400
    assert resp.json()["detail"] == "Credenciais incorretas"


def test_email_inexistente_da_a_mesma_resposta_que_senha_errada(ctx):
    client, _ = ctx
    errada = _login(client, senha="senha-errada-123")
    inexistente = _login(client, email="ninguem@exemplo.com")
    assert inexistente.status_code == errada.status_code == 400
    assert inexistente.json() == errada.json()  # não revela se o e-mail existe


def test_email_nao_diferencia_maiusculas(ctx):
    client, _ = ctx
    assert _login(client, email="MARIA@Exemplo.COM").status_code == 200


def test_usuario_inativo_nao_consegue_logar(ctx):
    client, Sessao = ctx
    with Sessao() as db:
        usuario = db.query(UsuarioModel).filter(UsuarioModel.email == EMAIL).one()
        usuario.ativo = False
        db.commit()
    assert _login(client).status_code == 400


def test_login_sem_campos_retorna_422(ctx):
    client, _ = ctx
    assert client.post("/auth/login", data={}).status_code == 422


def test_resposta_do_login_nao_vaza_senha_nem_hash(ctx):
    client, Sessao = ctx
    resp = _login(client)
    with Sessao() as db:
        senha_hash = db.query(UsuarioModel).one().senha_hash
    assert SENHA not in resp.text
    assert senha_hash not in resp.text


def test_segredo_vem_do_ambiente_e_nao_e_o_valor_antigo():
    assert security.SECRET_KEY != "sua_chave_secreta_super_segura_aqui"
    assert len(security.SECRET_KEY) >= 32