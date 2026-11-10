import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/api.dart';
import '../widgets/modelos.dart';
class Dados {
  List<Produto> produtos;
  List<Venda> vendas;
  List<Despesa> despesas;
  List<Fechamento> fechamentos;

  Dados(
      {required this.produtos,
      required this.vendas,
      required this.despesas,
      required this.fechamentos});

  factory Dados.vazio() =>
      Dados(produtos: [], vendas: [], despesas: [], fechamentos: []);
}

/// Onde os dados vivem: no servidor (RepoApi) ou neste aparelho (RepoLocal).
abstract class Repo {
  Future<Dados> carregar();
  Future<Produto> criarProduto(String nome, double preco, int estoque);
  Future<void> atualizarProduto(Produto p);
  Future<void> excluirProduto(Produto p);
  Future<Venda> registrarVenda(Produto p, int qtd, Forma forma);
  Future<void> cancelarVenda(Venda v);
  Future<void> registrarProducao(Produto p, int qtd);
  Future<void> registrarPerda(Produto p, int qtd);
  Future<Despesa> criarDespesa(Categoria c, double valor, bool daGaveta);
  Future<void> excluirDespesa(Despesa d);
  Future<Fechamento> fecharCaixa(Fechamento f);
  Future<void> reabrirCaixa(Fechamento f);
  Future<void> persistir(Dados d);
}

List<T> _lista<T>(dynamic j, T Function(Map<String, dynamic>) f) =>
    [for (final e in (j as List)) f(e as Map<String, dynamic>)];

int? _idDe(dynamic r) => r is Map ? (r['id'] as num?)?.toInt() : null;

// ---------------------------------------------------------------- servidor

class RepoApi implements Repo {
  final Api api;
  RepoApi(this.api);

  @override
  Future<Dados> carregar() async {
    final produtos = _lista(await api.get('/produtos'), Produto.fromJson);
    final vendas = _lista(await api.get('/vendas'), Venda.fromJson);
    var despesas = <Despesa>[];
    var fechamentos = <Fechamento>[];
    try {
      despesas = _lista(await api.get('/despesas'), Despesa.fromJson);
    } on ApiErro catch (erro) {
      if (erro.statusCode == 401) rethrow;
    } catch (_) {}
    try {
      fechamentos = _lista(await api.get('/fechamentos'), Fechamento.fromJson);
    } on ApiErro catch (erro) {
      if (erro.statusCode == 401) rethrow;
    } catch (_) {}
    return Dados(
        produtos: produtos,
        vendas: vendas,
        despesas: despesas,
        fechamentos: fechamentos);
  }

  @override
  Future<Produto> criarProduto(String nome, double preco, int estoque) async {
    final r = await api
        .post('/produtos', {'nome': nome, 'preco': preco, 'estoque': estoque});
    return Produto.fromJson(r as Map<String, dynamic>);
  }

  @override
  Future<void> atualizarProduto(Produto p) async {
    await api.put('/produtos/${p.id}',
        {'nome': p.nome, 'preco': p.preco, 'estoque': p.estoque});
  }

  @override
  Future<void> excluirProduto(Produto p) async {
    await api.delete('/produtos/${p.id}');
  }

  @override
  Future<Venda> registrarVenda(Produto p, int qtd, Forma forma) async {
    final r = await api.post('/vendas', {
      'produto_id': p.id,
      'quantidade': qtd,
      'forma_pagamento': forma.api,
    });
    final m = r is Map<String, dynamic> ? r : <String, dynamic>{};
    return Venda(
      id: (m['id'] as num?)?.toInt(),
      produtoId: p.id,
      quantidade: qtd,
      valor: numeroApi(m['valor'] ?? p.preco * qtd, campo: 'valor'),
      data: m['data'] != null
          ? DateTime.parse(m['data'] as String).toLocal()
          : DateTime.now(),
      forma: forma,
    );
  }

  @override
  Future<void> cancelarVenda(Venda v) async {
    if (v.id == null) throw ApiErro('Esta venda não pode ser cancelada.');
    await api.delete('/vendas/${v.id}');
  }

  @override
  Future<void> registrarProducao(Produto p, int qtd) async {
    await api.post('/producoes', {'produto_id': p.id, 'quantidade': qtd});
  }

  @override
  Future<void> registrarPerda(Produto p, int qtd) async {
    await api.post('/perdas', {'produto_id': p.id, 'quantidade': qtd});
  }

  @override
  Future<Despesa> criarDespesa(Categoria c, double valor, bool daGaveta) async {
    final agora = DateTime.now();
    final r = await api.post('/despesas', {
      'categoria': c.name,
      'valor': valor,
      'data': agora.toIso8601String(),
      'da_gaveta': daGaveta,
    });
    return Despesa(
        id: _idDe(r),
        categoria: c,
        valor: valor,
        data: agora,
        daGaveta: daGaveta);
  }

  @override
  Future<void> excluirDespesa(Despesa d) async {
    if (d.id == null) throw ApiErro('Este gasto não pode ser apagado.');
    await api.delete('/despesas/${d.id}');
  }

  @override
  Future<Fechamento> fecharCaixa(Fechamento f) async {
    final r = await api.post('/fechamentos', f.toJson()..remove('id'));
    return Fechamento(
      id: _idDe(r),
      data: f.data,
      troco: f.troco,
      dinheiro: f.dinheiro,
      saidas: f.saidas,
      contado: f.contado,
      cartao: f.cartao,
      pix: f.pix,
    );
  }

  @override
  Future<void> reabrirCaixa(Fechamento f) async {
    if (f.id == null) throw ApiErro('Este fechamento não pode ser reaberto.');
    await api.delete('/fechamentos/${f.id}');
  }

  @override
  Future<void> persistir(Dados d) async {}
}

// ------------------------------------------------------------ neste aparelho

class RepoLocal implements Repo {
  final SharedPreferences prefs;
  RepoLocal(this.prefs);

  static const _chave = 'automatize_dados_v1';
  int _prox = 1;
  int _id() => _prox++;

  @override
  Future<Dados> carregar() async {
    final txt = prefs.getString(_chave);
    if (txt == null) return Dados.vazio();
    try {
      final m = jsonDecode(txt) as Map<String, dynamic>;
      final d = Dados(
        produtos: _lista(m['produtos'], Produto.fromJson),
        vendas: _lista(m['vendas'], Venda.fromJson),
        despesas: _lista(m['despesas'], Despesa.fromJson),
        fechamentos: _lista(m['fechamentos'], Fechamento.fromJson),
      );
      var maior = (m['proximo_id'] as num?)?.toInt() ?? 1;
      for (final id in [
        ...d.produtos.map((e) => e.id),
        ...d.vendas.map((e) => e.id ?? 0),
        ...d.despesas.map((e) => e.id ?? 0),
        ...d.fechamentos.map((e) => e.id ?? 0),
      ]) {
        if (id >= maior) maior = id + 1;
      }
      _prox = maior;
      return d;
    } catch (_) {
      return Dados.vazio();
    }
  }

  @override
  Future<void> persistir(Dados d) async {
    await prefs.setString(
      _chave,
      jsonEncode({
        'produtos': d.produtos.map((e) => e.toJson()).toList(),
        'vendas': d.vendas.map((e) => e.toJson()).toList(),
        'despesas': d.despesas.map((e) => e.toJson()).toList(),
        'fechamentos': d.fechamentos.map((e) => e.toJson()).toList(),
        'proximo_id': _prox,
      }),
    );
  }

  @override
  Future<Produto> criarProduto(String nome, double preco, int estoque) async =>
      Produto(id: _id(), nome: nome, preco: preco, estoque: estoque);

  @override
  Future<void> atualizarProduto(Produto p) async {}

  @override
  Future<void> excluirProduto(Produto p) async {}

  @override
  Future<Venda> registrarVenda(Produto p, int qtd, Forma forma) async {
    if (qtd > p.estoque)
      throw ApiErro('${p.nome}: só tem ${p.estoque} no freezer.');
    return Venda(
      id: _id(),
      produtoId: p.id,
      quantidade: qtd,
      valor: cent(p.preco * qtd),
      data: DateTime.now(),
      forma: forma,
    );
  }

  @override
  Future<void> cancelarVenda(Venda v) async {}

  @override
  Future<void> registrarProducao(Produto p, int qtd) async {}

  @override
  Future<void> registrarPerda(Produto p, int qtd) async {
    if (qtd > p.estoque) throw ApiErro('Só tem ${p.estoque} no freezer.');
  }

  @override
  Future<Despesa> criarDespesa(
          Categoria c, double valor, bool daGaveta) async =>
      Despesa(
          id: _id(),
          categoria: c,
          valor: valor,
          data: DateTime.now(),
          daGaveta: daGaveta);

  @override
  Future<void> excluirDespesa(Despesa d) async {}

  @override
  Future<Fechamento> fecharCaixa(Fechamento f) async => Fechamento(
        id: _id(),
        data: f.data,
        troco: f.troco,
        dinheiro: f.dinheiro,
        saidas: f.saidas,
        contado: f.contado,
        cartao: f.cartao,
        pix: f.pix,
      );

  @override
  Future<void> reabrirCaixa(Fechamento f) async {}

  /// Uma semana de dados de exemplo, para ensaiar a apresentação.
  Dados exemplo() {
    _prox = 1;
    final rnd = Random(42);
    final agora = DateTime.now();
    final nomes = [
      ('Morango', 3.0, 24),
      ('Maracujá', 3.0, 4),
      ('Chocolate', 3.5, 18),
      ('Coco', 3.0, 12),
      ('Uva', 3.0, 0),
      ('Salgadinho de copo', 5.0, 15),
    ];
    final produtos = [
      for (final n in nomes)
        Produto(id: _id(), nome: n.$1, preco: n.$2, estoque: n.$3)
    ];
    final vendas = <Venda>[];
    final despesas = <Despesa>[];
    final fechamentos = <Fechamento>[];
    for (var d = 6; d >= 0; d--) {
      final dia = DateTime(agora.year, agora.month, agora.day - d);
      final n = 10 + rnd.nextInt(8);
      var dinheiro = 0.0;
      var cartao = 0.0;
      var pix = 0.0;
      for (var i = 0; i < n; i++) {
        const picos = [11, 12, 12, 12, 13, 16, 17, 17, 17, 18];
        var h = picos[rnd.nextInt(picos.length)];
        if (d == 0 && h > agora.hour) h = max(7, agora.hour);
        final p = produtos[rnd.nextInt(produtos.length)];
        final q = 1 + rnd.nextInt(3);
        final sorteio = rnd.nextInt(10);
        final f = sorteio < 3
            ? Forma.cartao
            : (sorteio < 5 ? Forma.pix : Forma.dinheiro);
        final v = cent(p.preco * q);
        if (f == Forma.dinheiro) {
          dinheiro += v;
        } else if (f == Forma.cartao) {
          cartao += v;
        } else {
          pix += v;
        }
        vendas.add(Venda(
          id: _id(),
          produtoId: p.id,
          quantidade: q,
          valor: v,
          data: dia.add(Duration(hours: h, minutes: rnd.nextInt(60))),
          forma: f,
        ));
      }
      final daGaveta = rnd.nextBool();
      final valorG = 12.0 + rnd.nextInt(25);
      despesas.add(Despesa(
        id: _id(),
        categoria: Categoria.values[rnd.nextInt(3)],
        valor: valorG,
        data: dia.add(const Duration(hours: 9)),
        daGaveta: daGaveta,
      ));
      if (d > 0) {
        final saidas = daGaveta ? valorG : 0.0;
        fechamentos.add(Fechamento(
          id: _id(),
          data: dia.add(const Duration(hours: 19)),
          troco: 20,
          dinheiro: cent(dinheiro),
          saidas: saidas,
          contado: cent(20 + dinheiro - saidas),
          cartao: cent(cartao),
          pix: cent(pix),
        ));
      }
    }
    return Dados(
        produtos: produtos,
        vendas: vendas,
        despesas: despesas,
        fechamentos: fechamentos);
  }
}
