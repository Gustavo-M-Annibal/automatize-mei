from database.connection import SessionLocal, engine
from database.models import Base
from fastapi import Depends, FastAPI, HTTPException # pyright: ignore[reportMissingImports]
from repositories.usuario_repository import UsuarioRepository
from sqlalchemy.orm import Session # type: ignore

# Cria as tabelas automaticamente caso não use Alembic
Base.metadata.create_all(bind=engine)

app = FastAPI()


# Dependência para abrir e fechar a sessão com o banco a cada requisição
def get_db():
  db = SessionLocal()
  try:
    yield db
  finally:
    db.close()


# C (Create - Inclusão)
@app.post("/usuarios/")
def criar_usuario(nome: str, email: str, db: Session = Depends(get_db)):
  repo = UsuarioRepository(db)
  return repo.criar(nome, email)


# R (Read - Consulta)
@app.get("/usuarios/{usuario_id}")
def buscar_usuario(usuario_id: int, db: Session = Depends(get_db)):
  repo = UsuarioRepository(db)
  usuario = repo.buscar_por_id(usuario_id)
  if not usuario:
    raise HTTPException(status_code=404, detail="Usuário não encontrado")
  return usuario


# U (Update - Alteração)
@app.put("/usuarios/{usuario_id}")
def atualizar_usuario(
    usuario_id: int, nome: str, email: str, db: Session = Depends(get_db)
):
  repo = UsuarioRepository(db)
  usuario = repo.atualizar(usuario_id, nome, email)
  if not usuario:
    raise HTTPException(status_code=404, detail="Usuário não encontrado")
  return usuario


# D (Delete - Exclusão)
@app.delete("/usuarios/{usuario_id}")
def deletar_usuario(usuario_id: int, db: Session = Depends(get_db)):
  repo = UsuarioRepository(db)
  usuario = repo.deletar(usuario_id)
  if not usuario:
    raise HTTPException(status_code=404, detail="Usuário não encontrado")
  return {"mensagem": "Usuário deletado com sucesso"}