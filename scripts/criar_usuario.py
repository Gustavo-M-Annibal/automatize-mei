"""Cria um usuário (ou redefine a senha dele). Rode da RAIZ do projeto:

    python -m scripts.criar_usuario admin "Administrador"

A senha é pedida no terminal (não aparece na tela nem fica no histórico).
Use "admin" como login para manter o mesmo usuário que o login antigo usava.
"""
import getpass
import sys

from database.connection import SessionLocal
from backend.app.services import usuario_service


def main() -> None:
    if len(sys.argv) != 3:
        sys.exit('Uso: python -m scripts.criar_usuario <login/email> "<nome>"')
    login, nome = sys.argv[1], sys.argv[2]
    senha = getpass.getpass("Senha (mín. 8 caracteres): ")
    if len(senha) < 8 or len(senha.encode("utf-8")) > 72:
        sys.exit("A senha deve ter de 8 caracteres até 72 bytes.")
    if senha != getpass.getpass("Repita a senha: "):
        sys.exit("As senhas não conferem.")

    db = SessionLocal()
    try:
        if usuario_service.redefinir_senha(db, login, senha):
            print(f"Senha de '{login}' redefinida.")
        else:
            usuario_service.cadastrar_usuario(db, nome=nome, email=login, senha=senha)
            print(f"Usuário '{login}' criado.")
    finally:
        db.close()


if __name__ == "__main__":
    main()