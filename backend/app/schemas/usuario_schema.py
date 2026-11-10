import re

from pydantic import BaseModel, ConfigDict, Field, SecretStr, field_validator

_EMAIL = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")


class UsuarioCreate(BaseModel):
    """O que a API RECEBE no cadastro (a senha em texto puro existe só aqui, na memória)."""

    nome: str = Field(min_length=2, max_length=100)
    email: str = Field(max_length=255)
    senha: SecretStr  # SecretStr aparece como '**********' em print/log

    @field_validator("email")
    @classmethod
    def _email_valido(cls, v: str) -> str:
        v = v.strip().lower()
        if not _EMAIL.match(v):
            raise ValueError("E-mail inválido.")
        return v

    @field_validator("senha")
    @classmethod
    def _senha_valida(cls, v: SecretStr) -> SecretStr:
        s = v.get_secret_value()
        if len(s) < 8:
            raise ValueError("A senha deve ter pelo menos 8 caracteres.")
        if len(s.encode("utf-8")) > 72:  # o bcrypt só usa os 72 primeiros bytes
            raise ValueError("A senha deve ter no máximo 72 bytes.")
        return v


class UsuarioResponse(BaseModel):
    """O que a API DEVOLVE. Não tem campo de senha nem de hash: não tem como vazar."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    nome: str
    email: str
    cargo: str

class TokenResponse(BaseModel):
    """Resposta do login: o token JWT e o tipo (sempre "bearer")."""

    access_token: str
    token_type: str = "bearer"


class SolicitarResetRequest(BaseModel):
    email: str = Field(max_length=255)

    @field_validator("email")
    @classmethod
    def _email_valido(cls, v: str) -> str:
        v = v.strip().lower()
        if not _EMAIL.match(v):
            raise ValueError("E-mail inválido.")
        return v


class RedefinirSenhaRequest(BaseModel):
    email: str = Field(max_length=255)
    codigo: str = Field(min_length=6, max_length=6)
    nova_senha: SecretStr

    @field_validator("email")
    @classmethod
    def _email_valido(cls, v: str) -> str:
        v = v.strip().lower()
        if not _EMAIL.match(v):
            raise ValueError("E-mail inválido.")
        return v

    @field_validator("nova_senha")
    @classmethod
    def _senha_valida(cls, v: SecretStr) -> SecretStr:
        s = v.get_secret_value()
        if len(s) < 8:
            raise ValueError("A senha deve ter pelo menos 8 caracteres.")
        if len(s.encode("utf-8")) > 72:
            raise ValueError("A senha deve ter no máximo 72 bytes.")
        return v