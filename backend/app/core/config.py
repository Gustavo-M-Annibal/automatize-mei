import os
from dotenv import load_dotenv

load_dotenv()

_raw = os.getenv("DATABASE_URL")
if _raw:
    # Garante que o driver psycopg2 é usado mesmo com URLs no formato postgres://
    DATABASE_URL = _raw.replace("postgres://", "postgresql+psycopg2://", 1)
    if not DATABASE_URL.startswith("postgresql+psycopg2://"):
        DATABASE_URL = DATABASE_URL.replace("postgresql://", "postgresql+psycopg2://", 1)
else:
    DB_USER = os.getenv("DB_USER", "postgres")
    DB_PASSWORD = os.getenv("DB_PASSWORD", "postgres")
    DB_HOST = os.getenv("DB_HOST", "localhost")
    DB_PORT = os.getenv("DB_PORT", "5433")
    DB_NAME = os.getenv("DB_NAME", "automatize_mei")
    DATABASE_URL = (
        f"postgresql+psycopg2://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
    )

BUSINESS_TZ = os.getenv("BUSINESS_TZ", "America/Sao_Paulo")
