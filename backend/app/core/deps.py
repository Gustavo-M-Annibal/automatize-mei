from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from backend.app.core.security import SECRET_KEY, ALGORITHM

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")


def obter_usuario_atual(token: str = Depends(oauth2_scheme)) -> str:
  credentials_exception = HTTPException(
      status_code=status.HTTP_401_UNAUTHORIZED,
      detail="Token de acesso ausente ou inválido.",
      headers={"WWW-Authenticate": "Bearer"},
  )
  try:
    payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
    username: str = payload.get("sub")
    if username is None:
      raise credentials_exception
    return username
  except JWTError:
    raise credentials_exception


def verificar_permissao_admin(
    usuario_atual: str = Depends(obter_usuario_atual),
) -> str:
  # Exemplo de regra de permissão: apenas o usuário 'admin' pode acessar certas rotas
  if usuario_atual != "admin":
    raise HTTPException(
        status_code=status.HTTP_403_FORBIDDEN,
        detail="Usuário sem permissão para realizar esta operação.",
    )
  return usuario_atual