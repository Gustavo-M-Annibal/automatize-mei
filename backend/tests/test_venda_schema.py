from pydantic import ValidationError

from backend.app.schemas.venda_schema import VendaCreate


def test_venda_create_aceita_dinheiro_ou_pix():
    venda = VendaCreate(produto_id=1, quantidade=2, forma_pagamento="pix")
    assert venda.produto_id == 1
    assert venda.quantidade == 2
    assert venda.forma_pagamento == "pix"


def test_venda_create_rejeita_cartao():
    try:
        VendaCreate(produto_id=1, quantidade=2, forma_pagamento="cartao")
        assert False, "cartao deve ser rejeitado"
    except ValidationError:
        pass
