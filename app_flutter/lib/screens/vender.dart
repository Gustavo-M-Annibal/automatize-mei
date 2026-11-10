import 'package:flutter/material.dart';
import 'arte.dart';
import '../widgets/componentes.dart';
import '../widgets/estado.dart';
import '../widgets/modelos.dart';
import 'freezer.dart';

class VenderPage extends StatefulWidget {
  const VenderPage({super.key});
  @override
  State<VenderPage> createState() => _VenderPageState();
}

class _VenderPageState extends State<VenderPage> {
  final Map<Produto, int> carrinho = {};
  bool enviando = false;

  double get total =>
      cent(carrinho.entries.fold(0.0, (a, e) => a + e.key.preco * e.value));
  int get itens => carrinho.values.fold(0, (a, v) => a + v);

  void _mudar(Produto p, int delta) {
    final novo = (carrinho[p] ?? 0) + delta;
    if (novo < 0 || novo > p.estoque) return;
    setState(() => novo == 0 ? carrinho.remove(p) : carrinho[p] = novo);
  }

  /// Pergunta como o cliente pagou com três opções grandes e alinhadas.
  Future<Forma?> _perguntarForma() {
    final valor = total;
    return mostrarFolha<Forma>(
      context,
      (_) => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Como pagou?',
                style: TextStyle(
                    fontSize: 18,
                    color: Cores.suave,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(brl(valor),
                style: const TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.8)),
            const SizedBox(height: 22),
            for (final forma in Forma.values) ...[
              SizedBox(
                width: double.infinity,
                height: 82,
                child: _OpcaoPagamento(forma),
              ),
              if (forma != Forma.values.last) const SizedBox(height: 12),
            ],
          ]),
        ),
      ),
    );
  }

  Future<void> _pagar() async {
    final forma = await _perguntarForma();
    if (forma == null || !mounted) return;
    await _confirmar(forma);
  }

  Future<void> _confirmar(Forma forma) async {
    final s = Escopo.de(context);
    final valor = total;
    final inset = MediaQuery.of(context).padding.bottom;
    final itensVenda = Map<Produto, int>.of(carrinho);
    setState(() => enviando = true);
    try {
      final criadas = await s.vender(itensVenda, forma);
      if (!mounted) return;
      setState(() {
        carrinho.clear();
        enviando = false;
      });
      final msg = ScaffoldMessenger.of(context);
      msg.hideCurrentSnackBar();
      await mostrarSucesso(context, brl(valor));
      if (!mounted) return;
      msg.showSnackBar(SnackBar(
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.fixed,
        backgroundColor: Cores.tinta,
        content: Text('Venda de ${brl(valor)} registrada',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        action: SnackBarAction(
          label: 'Desfazer',
          textColor: Cores.alerta,
          onPressed: () async {
            try {
              await s.cancelarVendas(criadas);
            } catch (e) {
              if (mounted) aviso(context, msgErro(e));
            }
          },
        ),
      ));
    } catch (e) {
      if (mounted) {
        setState(() => enviando = false);
        aviso(context, msgErro(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = Escopo.de(context);
    carrinho.removeWhere((p, _) => !s.produtos.contains(p));
    final tem = itens > 0;
    final fechado = s.caixaFechadoHoje;
    final inset = MediaQuery.of(context).padding.bottom;
    final selecionados = carrinho.keys.take(3).toList();

    return Stack(children: [
      Column(children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child:
              Align(alignment: Alignment.centerLeft, child: Titulo('Vender')),
        ),
        if (fechado)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              decoration: cartao(raio: 24),
              child: Row(children: [
                const Icon(Icons.lock_rounded, color: Cores.ok),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('Caixa fechado hoje',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                ),
                TextButton(
                  onPressed: () => reabrirCaixaUI(context, s),
                  child: const Text('Reabrir',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ]),
            ),
          ),
        Expanded(
          child: s.produtos.isEmpty
              ? ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                      EstadoVazio(
                        icone: Icons.shopping_bag_outlined,
                        titulo: 'Nenhum sabor ainda',
                        texto: 'Cadastre os geladinhos para começar a vender.',
                        botao: 'Cadastrar sabor',
                        onBotao: () => abrirFormProduto(context),
                      ),
                    ])
              : GridView.builder(
                  clipBehavior: Clip.none,
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 200 + inset),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: s.produtos.length,
                  itemBuilder: (_, i) {
                    final p = s.produtos[i];
                    return _CartaoSabor(
                      produto: p,
                      qtd: carrinho[p] ?? 0,
                      bloqueado: fechado,
                      onMais: () => _mudar(p, 1),
                      onMenos: () => _mudar(p, -1),
                    );
                  },
                ),
        ),
      ]),
      Positioned(
        left: 20,
        right: 20,
        bottom: 96 + inset,
        child: IgnorePointer(
          ignoring: !tem,
          child: AnimatedSlide(
            offset: tem ? Offset.zero : const Offset(0, 1.8),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: AnimatedOpacity(
              opacity: tem ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 10, 10, 10),
                decoration: BoxDecoration(
                  color: Cores.tinta,
                  borderRadius: BorderRadius.circular(36),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x40101828),
                        blurRadius: 28,
                        offset: Offset(0, 12))
                  ],
                ),
                child: Row(children: [
                  SizedBox(
                    width: 40.0 +
                        (selecionados.length > 1
                            ? (selecionados.length - 1) * 20.0
                            : 0),
                    height: 44,
                    child: Stack(children: [
                      for (var i = 0; i < selecionados.length; i++)
                        Positioned(
                            left: i * 20.0,
                            top: 0,
                            child: Arte(selecionados[i], tamanho: 44)),
                    ]),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('$itens ${itens == 1 ? 'item' : 'itens'}',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withAlpha(170),
                                  fontWeight: FontWeight.w600)),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(brl(total),
                                style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.8)),
                          ),
                        ]),
                  ),
                  BotaoAcao(
                    icone: Icons.check_rounded,
                    texto: 'Pronto',
                    cor: Cores.ok,
                    onTap: enviando ? null : _pagar,
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    ]);
  }
}

class _OpcaoPagamento extends StatelessWidget {
  final Forma forma;
  const _OpcaoPagamento(this.forma);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: forma.cor,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: () => Navigator.of(context).pop(forma),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(children: [
            Icon(forma.icone, size: 42, color: Colors.white),
            const SizedBox(width: 20),
            Expanded(
              child: Text(forma.rotulo,
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
            ),
            const Icon(Icons.arrow_forward_rounded,
                size: 24, color: Colors.white),
          ]),
        ),
      ),
    );
  }
}

class _CartaoSabor extends StatelessWidget {
  final Produto produto;
  final int qtd;
  final bool bloqueado;
  final VoidCallback onMais;
  final VoidCallback onMenos;
  const _CartaoSabor({
    required this.produto,
    required this.qtd,
    required this.bloqueado,
    required this.onMais,
    required this.onMenos,
  });

  @override
  Widget build(BuildContext context) {
    final v = produto.visual;
    final acabou = produto.estoque == 0;
    final sel = qtd > 0;
    return Opacity(
      opacity: bloqueado ? 0.5 : 1,
      child: GestureDetector(
        onTap: bloqueado
            ? () => aviso(
                context, 'O caixa de hoje está fechado. Reabra para vender.')
            : (acabou
                ? () => aviso(context, '${produto.nome} acabou no freezer')
                : onMais),
        onLongPress: () => abrirProduto(context, produto),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: sombraSuave,
            border:
                Border.all(color: sel ? v.cor : Colors.transparent, width: 2.5),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: RadialGradient(
                    center: const Alignment(0, 0.2),
                    radius: 0.9,
                    colors: [v.cor.withAlpha(46), v.cor.withAlpha(0)],
                  ),
                ),
                child: LayoutBuilder(
                  builder: (_, c) =>
                      Center(child: Arte(produto, tamanho: c.maxHeight * 0.92)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(produto.nome,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3)),
            const SizedBox(height: 2),
            Text(
                acabou
                    ? 'acabou'
                    : '${brl(produto.preco)} · ${produto.estoque} un',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: acabou ? Cores.erro : Cores.suave)),
            const SizedBox(height: 10),
            SizedBox(
              height: 46,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: sel
                    ? Contador(
                        key: const ValueKey('contador'),
                        valor: qtd,
                        onMenos: onMenos,
                        onMais: qtd >= produto.estoque ? null : onMais,
                      )
                    : Container(
                        key: const ValueKey('add'),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: acabou ? Cores.linha : Cores.fundo,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Icon(Icons.add_rounded,
                            size: 26,
                            color: acabou ? Cores.suave : Cores.tinta),
                      ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
