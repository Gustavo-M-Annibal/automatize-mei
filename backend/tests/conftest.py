import os

os.environ.setdefault("SECRET_KEY", "chave-somente-para-testes-0123456789-abcdefghij")

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, event
from sqlalchemy.orm import sessionmaker

from database.connection import Base
from backend.app.main import app
from backend.app.core.db import get_db
import backend.app.models  # noqa: F401 — registra todos os modelos

SQLALCHEMY_TEST_URL = "sqlite:///:memory:"

engine = create_engine(
    SQLALCHEMY_TEST_URL,
    connect_args={"check_same_thread": False},
)

# Habilita suporte a chaves estrangeiras no SQLite
@event.listens_for(engine, "connect")
def set_sqlite_pragma(dbapi_conn, connection_record):
    cursor = dbapi_conn.cursor()
    cursor.execute("PRAGMA foreign_keys=ON")
    cursor.close()

TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


@pytest.fixture(scope="function")
def client():
    Base.metadata.create_all(bind=engine)
    try:
        def override_get_db():
            db = TestingSessionLocal()
            try:
                yield db
            finally:
                db.close()

        app.dependency_overrides[get_db] = override_get_db
        with TestClient(app) as c:
            yield c
    finally:
        Base.metadata.drop_all(bind=engine)
        app.dependency_overrides.clear()
