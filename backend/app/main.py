from fastapi import Depends, FastAPI, HTTPException, status
from sqlalchemy.orm import Session

from backend.app.core.deps import obter_usuario_atual
from backend.app.models.produto_model import ProdutoModel as Produto
from backend.app.models.fechamento_model import FechamentoModel
from backend.app.repositories.usuario_repository import UsuarioRepository
from database.connection import Base, SessionLocal, engine

# Cria as tabelas automaticamente caso não use Alembic
Base.metadata.create_all(bind=engine)

app = FastAPI(title="Automatize MEI API", version="1.0.0")


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


# Listagem de produtos (Estoque)
@app.get("/produtos/")
def listar_produtos(db: Session = Depends(get_db), usuario_atual: str = Depends(obter_usuario_atual)):
    return db.query(Produto).all()


# Registro em Vendas
@app.post("/vendas/", status_code=status.HTTP_201_CREATED)
def registrar_venda(dados: dict, db: Session = Depends(get_db), usuario: str = Depends(obter_usuario_atual)):
    return {'mensagem': 'Venda registrada com sucesso', 'dados': dados, 'usuario': usuario}


# Registro em Despesas
@app.post("/despesas/")
def registrar_despesa(dados: dict, db: Session = Depends(get_db), usuario: str = Depends(obter_usuario_atual)):
    return {'mensagem': 'Despesa registrada com sucesso', 'dados': dados, 'usuario': usuario}


# Listagem de Fechamentos
@app.get("/fechamentos/")
def listar_fechamentos(db: Session = Depends(get_db), usuario: str = Depends(obter_usuario_atual)):
    return db.query(FechamentoModel).all()