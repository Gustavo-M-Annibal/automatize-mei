from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

from backend.app.core.db import get_db
from backend.app.core.security import criar_access_token
from backend.app.core.email_service import enviar_codigo_reset
from backend.app.core.reset_tokens import gerar_codigo, verificar_codigo
from backend.app.schemas.usuario_schema import (
    RedefinirSenhaRequest,
    SolicitarResetRequest,
    TokenResponse,
    UsuarioCreate,
    UsuarioResponse,
)
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


@router.post(
    "/solicitar-reset",
    status_code=200,
    summary="Solicitar redefinição de senha",
    description="Envia um código de 6 dígitos por e-mail. Válido por 15 minutos.",
    responses={404: {"description": "E-mail não encontrado."}},
)
def solicitar_reset(dados: SolicitarResetRequest, db: Session = Depends(get_db)):
    encontrado = usuario_service.buscar_por_email(db, dados.email)
    if not encontrado:
        raise HTTPException(status_code=404, detail="E-mail não encontrado.")
    codigo = gerar_codigo(dados.email)
    try:
        enviar_codigo_reset(dados.email, codigo)
    except Exception:
        raise HTTPException(status_code=503, detail="Falha ao enviar e-mail. Tente novamente.")
    return {"detail": "Código enviado por e-mail."}


@router.post(
    "/redefinir-senha",
    status_code=200,
    summary="Redefinir senha com código",
    description="Redefine a senha usando o código recebido por e-mail.",
    responses={
        400: {"description": "Código inválido ou expirado."},
        404: {"description": "E-mail não encontrado."},
        422: {"description": "Dados inválidos."},
    },
)
def redefinir_senha(dados: RedefinirSenhaRequest, db: Session = Depends(get_db)):
    if not verificar_codigo(dados.email, dados.codigo):
        raise HTTPException(status_code=400, detail="Código inválido ou expirado.")
    encontrado = usuario_service.redefinir_senha(
        db, dados.email, dados.nova_senha.get_secret_value()
    )
    if not encontrado:
        raise HTTPException(status_code=404, detail="E-mail não encontrado.")
    return {"detail": "Senha redefinida com sucesso."}