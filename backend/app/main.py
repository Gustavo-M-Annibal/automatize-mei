from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from backend.app.api.auth import router as auth_router
from backend.app.api.produtos import router as produtos_router
from backend.app.api.vendas import router as vendas_router
from backend.app.api.despesas import router as despesas_router
from backend.app.api.fechamentos import router as fechamentos_router
from backend.app.api.producoes import router as producoes_router
from backend.app.api.perdas import router as perdas_router

app = FastAPI(title="Automatize MEI API", version="2.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router)
app.include_router(produtos_router)
app.include_router(vendas_router)
app.include_router(despesas_router)
app.include_router(fechamentos_router)
app.include_router(producoes_router)
app.include_router(perdas_router)
