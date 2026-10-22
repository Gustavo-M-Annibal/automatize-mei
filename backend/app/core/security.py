
from gettext import install
import pip
from datetime import datetime, timedelta
from jose import JWTError, jwt
from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def gerar_hash_senha(senha: str) -> str:
    return pwd_context.hash(senha)

def verificar_senha(senha_pura: str, senha_hashed: str) -> bool:
    return pwd_context.verify(senha_pura, senha_hashed)

def criar_access_token(data: dict) -> str:
    dados_copia = data.copy()
    exp_atual = datetime.utcnow() + timedelta(minutes=ACEESS_TOKEN_EXPIRE_MINUTES)
    dados_copia.update({ "exp": exp_atual})
    return jwt.encode(dados_copia, SECRET_KEY, algorithm=ALGORITHM)