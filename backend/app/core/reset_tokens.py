import secrets
import string
from datetime import datetime, timedelta, timezone

_tokens: dict[str, tuple[str, datetime]] = {}
_TTL = timedelta(minutes=15)


def gerar_codigo(email: str) -> str:
    codigo = "".join(secrets.choice(string.digits) for _ in range(6))
    _tokens[email.lower()] = (codigo, datetime.now(timezone.utc) + _TTL)
    return codigo


def verificar_codigo(email: str, codigo: str) -> bool:
    entry = _tokens.get(email.lower())
    if not entry:
        return False
    code, expiry = entry
    if datetime.now(timezone.utc) > expiry:
        del _tokens[email.lower()]
        return False
    if code != codigo:
        return False
    del _tokens[email.lower()]
    return True
