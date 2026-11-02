import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api.dart';
import 'modelos.dart';
import '../screens/repo.dart';

class Estado extends ChangeNotifier {
  final Api api = Api();
  late SharedPreferences prefs;
  late Repo repo;
  Dados dados = Dados.vazio();

  bool carregando = true;
  bool local = false; // true = dados salvos só neste aparelho
  bool semConexao = false; // modo servidor, mas o servidor não respondeu
  String? modo; // 'api' | 'local'
  double trocoFixo = 0; // dinheiro miúdo que já fica na gaveta
  DateTime _diaVisto = soDia(DateTime.now());

  List<Produto> get produtos => dados.produtos;
  List<Venda> get vendas => dados.vendas;
  List<Despesa> get despesas => dados.despesas;
  List<Fechamento> get fechamentos => dados.fechamentos;

  // ------------------------------------------------------------ carregamento

  Future<void> iniciar() async {
    prefs = await SharedPreferences.getInstance();
    api.baseUrl = prefs.getString('api_url') ?? api.baseUrl;
    modo = prefs.getString('modo');
    trocoFixo = prefs.getDouble('troco_fixo') ?? 0;
    await carregar();
  }

  Future<bool> _tentarApi() async {
    try {
      final r = RepoApi(api);
      final d = await r.carregar();
      repo = r;
      dados = d;
      local = false;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _usarLocal() async {
    final r = RepoLocal(prefs);
    dados = await r.carregar();
    repo = r;
    local = true;
    modo = 'local';
    await prefs.setString('modo', 'local');
  }

  /// Regra: se o app já usou o servidor, nunca troca sozinho para o banco local.
  Future<void> carregar() async {
    carregando = true;
    semConexao = false;
    notifyListeners();
    try {
      if (modo == 'local') {
        await _usarLocal();
      } else if (await _tentarApi()) {
        modo = 'api';
        await prefs.setString('modo', 'api');
      } else if (modo == 'api') {
        semConexao = true;
      } else {
        await _usarLocal();
      }
    } finally {
      carregando = false;
      notifyListeners();
    }
  }

  Future<void> conectar(String url) async {
    final antigo = api.baseUrl;
    api.baseUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
    if (!await _tentarApi()) {
      api.baseUrl = antigo;
      throw ApiErro('Não consegui conectar nesse endereço.');
    }
    modo = 'api';
    semConexao = false;
    await prefs.setString('api_url', api.baseUrl);
    await prefs.setString('modo', 'api');
    notifyListeners();
  }

  Future<void> usarLocal() async {
    await _usarLocal();
    semConexao = false;
    notifyListeners();
  }

  Future<void> carregarExemplo() async {
    if (repo is! RepoLocal) return;
    final r = repo as RepoLocal;
    dados = r.exemplo();
    await setTrocoFixo(20);
    await _gravar();
  }

  Future<void> apagarLocal() async {
    dados = Dados.vazio();
    await _gravar();
  }

  /// Chamado quando o app volta para a tela: se virou o dia, atualiza tudo.
  Future<void> aoVoltar() async {
    final hoje = soDia(DateTime.now());
    if (hoje != _diaVisto) {
      _diaVisto = hoje;
      if (modo == 'api') {
        await carregar();
      } else {
        notifyListeners();
      }
    }
  }

  Future<void> _gravar() async {
    await repo.persistir(dados);
    notifyListeners();
  }

  // ----------------------------------------------------------------- consultas

  List<DateTime> ultimosDias(int n) {
    final h = DateTime.now();
    return [
      for (var i = n - 1; i >= 0; i--) DateTime(h.year, h.month, h.day - i)
    ];
  }

  Iterable<Venda> vendasDoDia(DateTime d) =>
      vendas.where((v) => mesmoDia(v.data, d));
  double totalVendasDoDia(DateTime d) =>
      cent(vendasDoDia(d).fold(0.0, (a, v) => a + v.valor));
  double dinheiroDoDia(DateTime d) => cent(vendasDoDia(d)
      .where((v) => v.forma == Forma.dinheiro)
      .fold(0.0, (a, v) => a + v.valor));
  double cartaoDoDia(DateTime d) => cent(vendasDoDia(d)
      .where((v) => v.forma == Forma.cartao)
      .fold(0.0, (a, v) => a + v.valor));
  int itensDoDia(DateTime d) =>
      vendasDoDia(d).fold(0, (a, v) => a + v.quantidade);

  Iterable<Despesa> despesasDoDia(DateTime d) =>
      despesas.where((x) => mesmoDia(x.data, d));
  double gastosDoDia(DateTime d) =>
      cent(despesasDoDia(d).fold(0.0, (a, x) => a + x.valor));
  double saidasGavetaDoDia(DateTime d) => cent(despesasDoDia(d)
      .where((x) => x.daGaveta)
      .fold(0.0, (a, x) => a + x.valor));

  Fechamento? fechamentoDoDia(DateTime d) {
    for (final f in fechamentos.reversed) {
      if (mesmoDia(f.data, d)) return f;
    }
    return null;
  }

  DateTime get hoje => DateTime.now();
  bool get caixaFechadoHoje => fechamentoDoDia(hoje) != null;
  double get vendidoHoje => totalVendasDoDia(hoje);
  int get itensHoje => itensDoDia(hoje);
  double get esperadoGavetaHoje =>
      cent(trocoFixo + dinheiroDoDia(hoje) - saidasGavetaDoDia(hoje));
  List<Produto> get acabando => produtos.where((p) => p.estoque <= 5).toList();

  Produto? produtoPorId(int id) {
    for (final p in produtos) {
      if (p.id == id) return p;
    }
    return null;
  }

  // ------------------------------------------------------------------ produtos

  Future<Produto> criarProduto(String nome, double preco, int estoque) async {
    final p = await repo.criarProduto(nome.trim(), preco, estoque);
    dados.produtos.add(p);
    await _gravar();
    return p;
  }

  Future<void> atualizarProduto(Produto p, String nome, double preco) async {
    final nomeAntigo = p.nome;
    final precoAntigo = p.preco;
    p.nome = nome.trim();
    p.preco = preco;
    try {
      await repo.atualizarProduto(p);
    } catch (_) {
      p.nome = nomeAntigo;
      p.preco = precoAntigo;
      rethrow;
    }
    await _gravar();
  }

  Future<void> excluirProduto(Produto p) async {
    await repo.excluirProduto(p);
    dados.produtos.remove(p);
    await _gravar();
  }

  Future<void> produzir(Produto p, int qtd) async {
    if (qtd <= 0) return;
    await repo.registrarProducao(p, qtd);
    p.estoque += qtd;
    await _gravar();
  }

  Future<void> perder(Produto p, int qtd) async {
    if (qtd <= 0) return;
    if (qtd > p.estoque) throw ApiErro('Só tem ${p.estoque} no freezer.');
    await repo.registrarPerda(p, qtd);
    p.estoque -= qtd;
    await _gravar();
  }

  // -------------------------------------------------------------------- vendas

  Future<List<Venda>> vender(Map<Produto, int> itens, Forma forma) async {
    if (caixaFechadoHoje) {
      throw ApiErro(
          'O caixa de hoje já foi fechado. Reabra o caixa para vender.');
    }
    final criadas = <Venda>[];
    try {
      for (final e in itens.entries) {
        if (e.value <= 0) continue;
        if (e.value > e.key.estoque) {
          throw ApiErro('${e.key.nome}: só tem ${e.key.estoque} no freezer.');
        }
        final v = await repo.registrarVenda(e.key, e.value, forma);
        e.key.estoque -= e.value;
        dados.vendas.add(v);
        criadas.add(v);
      }
    } finally {
      if (criadas.isNotEmpty) await _gravar();
    }
    return criadas;
  }

  Future<void> cancelarVendas(List<Venda> lista) async {
    for (final v in lista) {
      if (fechamentoDoDia(v.data) != null) {
        throw ApiErro(
            'Esse dia já foi fechado. Reabra o caixa para cancelar a venda.');
      }
    }
    try {
      for (final v in lista) {
        await repo.cancelarVenda(v);
        dados.vendas.remove(v);
        final p = produtoPorId(v.produtoId);
        if (p != null) p.estoque += v.quantidade;
      }
    } finally {
      await _gravar();
    }
  }

  // -------------------------------------------------------------------- gastos

  Future<void> criarDespesa(Categoria c, double valor, bool daGaveta) async {
    if (daGaveta && caixaFechadoHoje) {
      throw ApiErro(
          'O caixa de hoje já foi fechado. Reabra para registrar gasto da gaveta.');
    }
    final d = await repo.criarDespesa(c, valor, daGaveta);
    dados.despesas.add(d);
    await _gravar();
  }

  Future<void> excluirDespesa(Despesa d) async {
    if (d.daGaveta && fechamentoDoDia(d.data) != null) {
      throw ApiErro(
          'Esse dia já foi fechado. Reabra o caixa para apagar este gasto.');
    }
    await repo.excluirDespesa(d);
    dados.despesas.remove(d);
    await _gravar();
  }

  // --------------------------------------------------------------------- caixa

  Future<void> setTrocoFixo(double v) async {
    trocoFixo = cent(v);
    await prefs.setDouble('troco_fixo', trocoFixo);
    notifyListeners();
  }

  Future<void> fecharCaixa(double contado) async {
    if (caixaFechadoHoje) throw ApiErro('O caixa de hoje já está fechado.');
    final h = hoje;
    final f = Fechamento(
      data: h,
      troco: trocoFixo,
      dinheiro: dinheiroDoDia(h),
      saidas: saidasGavetaDoDia(h),
      contado: cent(contado),
      cartao: cartaoDoDia(h),
    );
    final salvo = await repo.fecharCaixa(f);
    dados.fechamentos.add(salvo);
    await _gravar();
  }

  Future<void> reabrirCaixa() async {
    final f = fechamentoDoDia(hoje);
    if (f == null) return;
    await repo.reabrirCaixa(f);
    dados.fechamentos.remove(f);
    await _gravar();
  }
}

class Escopo extends InheritedNotifier<Estado> {
  const Escopo({super.key, required Estado estado, required super.child})
      : super(notifier: estado);
  static Estado de(BuildContext c) =>
      c.dependOnInheritedWidgetOfExactType<Escopo>()!.notifier!;
}
