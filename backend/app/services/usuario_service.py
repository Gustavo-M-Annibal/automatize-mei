from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from ..core.security import gerar_hash_senha, verificar_senha
from ..models.usuario_model import UsuarioModel


class EmailJaCadastradoError(Exception):
    pass


class CredenciaisInvalidasError(Exception):
    pass


# Hash descartável: no login com e-mail inexistente ainda fazemos UMA verificação
# bcrypt, para o tempo de resposta não revelar quais e-mails existem.
_HASH_FALSO = gerar_hash_senha("senha-descartavel")


def _buscar_por_email(db: Session, email: str):
    return db.query(UsuarioModel).filter(UsuarioModel.email == email).first()


def cadastrar_usuario(db: Session, nome: str, email: str, senha: str) -> UsuarioModel:
    email = email.strip().lower()
    if _buscar_por_email(db, email):
        raise EmailJaCadastradoError()

    usuario = UsuarioModel(nome=nome.strip(), email=email, senha_hash=gerar_hash_senha(senha))
    db.add(usuario)
    try:
        db.commit()
    except IntegrityError as exc:
        # Duas requisições ao mesmo tempo: o UNIQUE do banco é a defesa final.
        db.rollback()
        raise EmailJaCadastradoError() from exc
    except Exception:
        db.rollback()
        raise
    db.refresh(usuario)
    return usuario


def redefinir_senha(db: Session, email: str, nova_senha: str) -> bool:
    usuario = _buscar_por_email(db, email.strip().lower())
    if not usuario:
        return False
    usuario.senha_hash = gerar_hash_senha(nova_senha)
    db.commit()
    return True


def autenticar(db: Session, email: str, senha: str) -> UsuarioModel:
    usuario = _buscar_por_email(db, email.strip().lower())
    confere = verificar_senha(senha, usuario.senha_hash if usuario else _HASH_FALSO)
    # Mesma exceção para "e-mail não existe", "senha errada" e "usuário inativo".
    if usuario is None or not confere or not usuario.ativo:
        raise CredenciaisInvalidasError()
    return usuario