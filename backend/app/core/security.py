import os
from datetime import datetime, timedelta, timezone
from dotenv import load_dotenv
from jose import JWTError, jwt
from passlib.context import CryptContext

load_dotenv()

SECRET_KEY = os.getenv("SECRET_KEY", "")
if len(SECRET_KEY) < 32:
    raise RuntimeError(
        "SECRET_KEY ausente ou curta demais (mínimo 32 caracteres). Gere uma com: "
        'python -c "import secrets; print(secrets.token_urlsafe(48))" '
        "e coloque no arquivo .env como SECRET_KEY=..."
    )
ALGORITHM = os.getenv("ALGORITHM", "HS256")
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", 30))

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def gerar_hash_senha(senha: str) -> str:
    return pwd_context.hash(senha)

def verificar_senha(senha_pura: str, senha_hashed: str) -> bool:
    return pwd_context.verify(senha_pura, senha_hashed)

def criar_access_token(data: dict) -> str:
    dados_copia = data.copy()
    exp_atual = datetime.now(timezone.utc) + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    dados_copia.update({"exp": exp_atual})
    return jwt.encode(dados_copia, SECRET_KEY, algorithm=ALGORITHM)