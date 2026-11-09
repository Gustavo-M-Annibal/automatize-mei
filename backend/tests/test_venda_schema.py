from pydantic import ValidationError

from backend.app.schemas.venda_schema import VendaCreate


def test_venda_create_aceita_dinheiro_cartao_ou_pix():
    for forma in ("dinheiro", "cartao", "pix"):
        venda = VendaCreate(produto_id=1, quantidade=2, forma_pagamento=forma)
        assert venda.produto_id == 1
        assert venda.quantidade == 2
        assert venda.forma_pagamento == forma


def test_venda_create_rejeita_forma_desconhecida():
    try:
        VendaCreate(produto_id=1, quantidade=2, forma_pagamento="cheque")
        assert False, "forma de pagamento desconhecida deve ser rejeitada"
    except ValidationError:
        pass
