from backend.app.schemas.produto_schema import ProdutoCreate, ProdutoMovimentacaoEstoque, ProdutoUpdate
from backend.app.services.produto_service import EstoqueInsuficienteError, ProdutoNaoEncontradoError, ProdutoService
from fastapi import Depends, FastAPI, HTTPException, status
from sqlalchemy.orm import Session

<<<<<<< HEAD
from app.core.deps import obter_usuario_atual
from app.models.produto_model import ProdutoModel
from app.models.fechamento_model import FechamentoModel
from app.repositories.usuario_repository import UsuarioRepository
=======
from backend.app.core.deps import obter_usuario_atual
from backend.app.models.produto_model import ProdutoModel as Produto
from backend.app.models.fechamento_model import FechamentoModel
from backend.app.repositories.usuario_repository import UsuarioRepository
>>>>>>> 05c938183e50b46cab343d842890547ca7aae7ed
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
    return db.query(ProdutoModel).all()

#Criação de produtos (Estoque)
@app.post("/produtos/")
def criar_produto(dados: ProdutoCreate, db: Session = Depends(get_db)):
    service = ProdutoService(db)
    return service.criar(dados)

#Atualização de produtos (Estoque)
@app.put("/produtos/{produto_id}")
def atualizar_produto(id: int, dados: ProdutoUpdate, db: Session = Depends(get_db)):
    service = ProdutoService(db)
    try:
        return service.atualizar(id, dados)
    except ProdutoNaoEncontradoError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))
    
# Deleção de produtos (Estoque)
@app.delete("/produtos/{produto_id}")
def deletar_produto(id: int, db: Session = Depends(get_db)):
    service = ProdutoService(db)
    try:
        service.deletar(id)
    except ProdutoNaoEncontradoError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=str(e))
    
# post para movimentação de estoque (Estoque)
@app.post("/produtos/{produto_id}/movimentar_estoque/")
def registrar_producao(produto_id: int, dados: ProdutoMovimentacaoEstoque, db: Session = Depends(get_db)):
    service = ProdutoService(db)
    try:
        return service.incrementar_producao(produto_id, dados.quantidade)
    except ProdutoNaoEncontradoError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))
    
# post para movimentação de estoque (Estoque)
@app.post("/produtos/{produto_id}/perder_estoque/")
def registrar_perda(produto_id: int, dados: ProdutoMovimentacaoEstoque, db: Session = Depends(get_db)):
    service = ProdutoService(db)
    try:
        return service.decrementar_perda(produto_id, dados.quantidade)
    except ProdutoNaoEncontradoError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))
    except EstoqueInsuficienteError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))    
    
    
    
    

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