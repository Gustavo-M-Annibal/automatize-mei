"""Mascara senha, token, JWT e hash bcrypt em TODAS as mensagens de log."""
import logging
import re

_PADROES = [
    (re.compile(r"(?i)(bearer\s+)[\w\-.~+/]+=*"), r"\1[REDACTED]"),
    (
        re.compile(
            r"(?i)\b(senha|password|passwd|secret_key|secret|access_token|token)\b"
            r"(\"?\s*[=:]\s*\"?)[^\s&,;\"'}]+"
        ),
        r"\1\2[REDACTED]",
    ),
    (re.compile(r"\$2[abxy]\$\d{2}\$[./A-Za-z0-9]{53}"), "[REDACTED_HASH]"),
    (re.compile(r"\beyJ[\w-]{5,}\.[\w-]{5,}\.[\w-]*"), "[REDACTED_JWT]"),
]


def redigir(texto: str) -> str:
    for padrao, substituto in _PADROES:
        texto = padrao.sub(substituto, texto)
    return texto


_configurado = False


def configurar_logging() -> None:
    """Pode ser chamada mais de uma vez. Vale para uvicorn, sqlalchemy etc."""
    global _configurado
    if _configurado:
        return
    original = logging.getLogRecordFactory()

    def fabrica(*args, **kwargs):
        registro = original(*args, **kwargs)
        try:
            mensagem = registro.getMessage()
        except Exception:
            return registro
        limpa = redigir(mensagem)
        if limpa != mensagem:
            registro.msg, registro.args = limpa, ()
        return registro

    logging.setLogRecordFactory(fabrica)
    logging.getLogger("sqlalchemy.engine").setLevel(logging.WARNING)  # INFO imprime parâmetros
    _configurado = True