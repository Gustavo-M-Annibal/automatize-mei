from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

from ..core.db import get_db
from ..core.security import criar_access_token
from ..schemas.usuario_schema import UsuarioCreate, UsuarioResponse
from ..services import usuario_service

router = APIRouter(prefix="/auth", tags=["Autenticação"])


@router.post("/register", response_model=UsuarioResponse, status_code=status.HTTP_201_CREATED)
def registrar(dados: UsuarioCreate, db: Session = Depends(get_db)):
    """Cadastra o usuário salvando só o hash bcrypt. A resposta nunca traz senha/hash."""
    try:
        return usuario_service.cadastrar_usuario(
            db, nome=dados.nome, email=dados.email, senha=dados.senha.get_secret_value()
        )
    except usuario_service.EmailJaCadastradoError as exc:
        raise HTTPException(status_code=409, detail="E-mail já cadastrado.") from exc


@router.post("/login")
def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    """`username` do formulário = e-mail cadastrado. Confere a senha contra o hash do banco."""
    try:
        usuario = usuario_service.autenticar(db, form_data.username, form_data.password)
    except usuario_service.CredenciaisInvalidasError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,  # mesmo código que o login antigo usava
            detail="Credenciais incorretas",
        ) from exc

    access_token = criar_access_token(data={"sub": usuario.email})
    return {"access_token": access_token, "token_type": "bearer"}