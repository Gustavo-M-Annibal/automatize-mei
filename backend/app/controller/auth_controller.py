from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

from backend.app.core.db import get_db
from backend.app.core.security import criar_access_token
from backend.app.schemas.usuario_schema import TokenResponse, UsuarioCreate, UsuarioResponse
from backend.app.services import usuario_service

router = APIRouter(prefix="/auth", tags=["Autenticação"])


@router.post(
    "/register",
    response_model=UsuarioResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Cadastrar usuário",
    description=(
        "Cria um novo usuário armazenando apenas o hash bcrypt da senha. "
        "A senha nunca é retornada na resposta."
    ),
    responses={
        409: {"description": "E-mail já cadastrado."},
        422: {"description": "Dados inválidos (e-mail malformado, senha muito curta, etc.)."},
    },
)
def registrar(dados: UsuarioCreate, db: Session = Depends(get_db)):
    try:
        return usuario_service.cadastrar_usuario(
            db, nome=dados.nome, email=dados.email, senha=dados.senha.get_secret_value()
        )
    except usuario_service.EmailJaCadastradoError as exc:
        raise HTTPException(status_code=409, detail="E-mail já cadastrado.") from exc


@router.post(
    "/login",
    response_model=TokenResponse,
    summary="Autenticar usuário",
    description=(
        "Autentica o usuário com e-mail (campo username) e senha. "
        "Retorna um access token JWT do tipo Bearer válido para uso nos headers das requisições protegidas."
    ),
    responses={
        400: {"description": "E-mail ou senha incorretos."},
    },
)
def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    try:
        usuario = usuario_service.autenticar(db, form_data.username, form_data.password)
    except usuario_service.CredenciaisInvalidasError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Credenciais incorretas",
        ) from exc

    access_token = criar_access_token(data={"sub": usuario.email})
    return {"access_token": access_token, "token_type": "bearer"}