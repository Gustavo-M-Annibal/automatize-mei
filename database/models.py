# Onde ficam os modelos ORM (ex: UsuarioModel)

from database.conection import Base
from math import integer
from sqlalchemy import Column , Integer , String


class UsuarioModel(Base):
    __tablename__ = "usuarios"

    id = Column(Integer, primary_key= True, index= True)
    nome = Column(String, nullable= False)
    fk_usuario_id = Column(Integer, nullable= False)
    email = Column(String, unique= True, index= True)
    valor = Column(float, nullable= False, default=0.0)
    cargo = Column(String, nullable= False, default="funcionario")



class ProducaoModel(Base):
    __tablename__ = "producao"

    id = Column(Integer, primary_key= True, index= True)
    fk_produto_id = Column(Integer, nullable= False)
    fk_usuario_id = Column(Integer, nullable= False)
    quantidade =  Column(float, nullable= False, default=0.0)


    class EstoqueModel(Base):
        __tablename__ = "estoque"

        id = Column(Integer, primary_key= True, index= True)
        fk_produto_id = Column(Integer, nullable= False)
        quantidade_atual = Column(float, nullable= False, default=0.0)



    class FechamentoModel(Base):
        __tablename__ = "fechamento"

        id = Column(Integer, primary_key= True, index= True)
        fk_usuario_id = Column(Integer, nullable= False)
        data_fechamento = Column(String, nullable= False)
        valor_total =  Column(float, nullable= False, default=0.0)
        status= Column(String, nullable= False, default="aberto")


    class VendaModel(Base):
        __tablename__ = "venda"

        id = Column(Integer, primary_key= True, index= True)
        fk_produto_id = Column(Integer, nullable= False)
        fk_usuario_id = Column(Integer, nullable= False)
        quantidade = Column(float, nullable= False, default=0.0)
        valor_total = Column(float, nullable= False, default=0.0)


    class ItemVendaModel(Base):
        __tablename__ = "item_venda"

        id = Column(Integer, primary_key= True, index= True)
        fk_venda_id = Column(Integer, nullable= False)
        fk_produto_id = Column(Integer, nullable= False)
        quantidade = Column(float, nullable= False, default=0.0)
        valor_unitario = Column(float, nullable= False, default=0.0)


    class ProdutoSaborModel(Base):
        __tablename__ = "produto_sabor"

        id = Column(Integer, primary_key= True, index= True)
        name = Column(String, unique= True, index= True)
        preco_venda = Column(float, nullable= False, default= 0.0)
        