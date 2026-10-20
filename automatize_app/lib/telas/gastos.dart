import 'package:flutter/material.dart';
import '../componentes.dart';
import '../dinheiro.dart';
import '../estado.dart';
import '../modelos.dart';

void abrirGastos(BuildContext context) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GastosPage()));
}

Future<void> abrirNovoGasto(BuildContext pai) =>
    mostrarFolha<void>(pai, (_) => _FolhaGasto(pai: pai));

class GastosPage extends StatelessWidget {
  const GastosPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = Escopo.de(context);
    final agora = DateTime.now();
    final limite = DateTime(agora.year, agora.month, agora.day - 60);
    final limite30 = DateTime(agora.year, agora.month, agora.day - 29);
    final lista = s.despesas.where((d) => !d.data.isBefore(limite)).toList()
      ..sort((a, b) => b.data.compareTo(a.data));
    final trinta = cent(s.despesas.where((d) => !d.data.isBefore(limite30)).fold(0.0, (a, d) => a + d.valor));

    final itens = <Widget>[];
    DateTime? diaAtual;
    for (final d in lista) {
      if (diaAtual == null || !mesmoDia(diaAtual, d.data)) {
        diaAtual = d.data;
        itens.add(Padding(
          padding: const EdgeInsets.fromLTRB(4, 18, 0, 8),
          child: Text(rotuloDia(d.data),
              style: const TextStyle(fontSize: 15, color: Cores.suave, fontWeight: FontWeight.w700)),
        ));
      }
      itens.add(_LinhaGasto(d));
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            const TopoVoltar('Gastos'),
            Row(children: [
              Expanded(
                child: CartaoStat(
                  icone: Icons.today_rounded,
                  rotulo: 'Hoje',
                  valor: brl(s.gastosDoDia(agora)),
                  cor: Cores.erro,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CartaoStat(
                  icone: Icons.calendar_month_rounded,
                  rotulo: 'Últimos 30 dias',
                  valor: brl(trinta),
                  cor: Cores.azul,
                ),
              ),
            ]),
            if (lista.isEmpty) ...[
              const SizedBox(height: 18),
              const EstadoVazio(
                icone: Icons.receipt_long_outlined,
                titulo: 'Nenhum gasto ainda',
                texto: 'Anote o que você compra: ingredientes, embalagem, gás.',
              ),
            ] else
              ...itens,
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: SizedBox(
            width: double.infinity,
            child: BotaoAcao(
              icone: Icons.add_rounded,
              texto: 'Novo gasto',
              onTap: () => abrirNovoGasto(context),
            ),
          ),
        ),
      ),
    );
  }
}

class _LinhaGasto extends StatelessWidget {
  final Despesa d;
  const _LinhaGasto(this.d);

  Future<void> _apagar(BuildContext context) async {
    final s = Escopo.de(context);
    final ok = await confirmar(
      context,
      titulo: 'Apagar este gasto?',
      texto: '${d.categoria.rotulo} · ${brl(d.valor)}',
      sim: 'Apagar',
      perigo: true,
    );
    if (!ok || !context.mounted) return;
    try {
      await s.excluirDespesa(d);
    } catch (e) {
      if (context.mounted) aviso(context, msgErro(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = d.categoria;
    return Toque(
      onTap: () => _apagar(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(14, 12, 18, 12),
        decoration: cartao(raio: 24),
        child: Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: c.cor.withAlpha(30), shape: BoxShape.circle),
            child: Icon(c.icone, color: c.cor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.rotulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              Row(children: [
                if (d.daGaveta) ...[
                  const Icon(Icons.payments_rounded, size: 14, color: Cores.suave),
                  const SizedBox(width: 4),
                  const Text('da gaveta · ',
                      style: TextStyle(fontSize: 12, color: Cores.suave, fontWeight: FontWeight.w600)),
                ],
                Text(hora(d.data),
                    style: const TextStyle(fontSize: 12, color: Cores.suave, fontWeight: FontWeight.w600)),
              ]),
            ]),
          ),
          Text(brl(d.valor), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
        ]),
      ),
    );
  }
}

class _FolhaGasto extends StatefulWidget {
  final BuildContext pai;
  const _FolhaGasto({required this.pai});
  @override
  State<_FolhaGasto> createState() => _FolhaGastoState();
}

class _FolhaGastoState extends State<_FolhaGasto> {
  Categoria categoria = Categoria.ingredientes;
  bool daGaveta = true;
  final Map<int, int> contagem = {};
  bool salvando = false;
  String? erro;

  void _mudar(int c, int delta) {
    final novo = (contagem[c] ?? 0) + delta;
    if (novo < 0) return;
    setState(() {
      erro = null;
      novo == 0 ? contagem.remove(c) : contagem[c] = novo;
    });
  }

  Future<void> _salvar() async {
    final valor = somaCentavos(contagem) / 100;
    if (valor <= 0) {
      setState(() => erro = 'Toque no dinheiro para dizer quanto foi.');
      return;
    }
    final s = Escopo.de(context);
    final pai = widget.pai;
    setState(() {
      salvando = true;
      erro = null;
    });
    try {
      await s.criarDespesa(categoria, valor, daGaveta);
      if (!mounted) return;
      Navigator.of(context).pop();
      await mostrarSucesso(pai, brl(valor));
    } catch (e) {
      if (mounted) {
        setState(() {
          salvando = false;
          erro = msgErro(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = somaCentavos(contagem) / 100;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Novo gasto',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.7)),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.3,
          children: [
            for (final c in Categoria.values)
              _Escolha(
                selecionado: categoria == c,
                icone: c.icone,
                rotulo: c.rotulo,
                cor: c.cor,
                onTap: () => setState(() => categoria = c),
              ),
          ],
        ),
        const SizedBox(height: 18),
        const Text('Quanto foi?', style: TextStyle(fontSize: 15, color: Cores.suave, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(brl(total), style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800, letterSpacing: -1.5)),
        const SizedBox(height: 12),
        GradeDinheiro(contagem: contagem, onMudar: _mudar),
        const SizedBox(height: 18),
        const Text('Como pagou?', style: TextStyle(fontSize: 15, color: Cores.suave, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: _Escolha(
              selecionado: daGaveta,
              icone: Icons.payments_rounded,
              rotulo: 'Da gaveta',
              cor: Cores.ok,
              onTap: () => setState(() => daGaveta = true),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _Escolha(
              selecionado: !daGaveta,
              icone: Icons.account_balance_wallet_rounded,
              rotulo: 'Outro jeito',
              cor: Cores.azul,
              onTap: () => setState(() => daGaveta = false),
            ),
          ),
        ]),
        const SizedBox(height: 20),
        if (erro != null) ErroInline(erro!),
        SizedBox(
          width: double.infinity,
          child: BotaoAcao(
            icone: Icons.check_rounded,
            texto: 'Salvar gasto',
            cor: Cores.ok,
            onTap: salvando ? null : _salvar,
          ),
        ),
      ]),
    );
  }
}

class _Escolha extends StatelessWidget {
  final bool selecionado;
  final IconData icone;
  final String rotulo;
  final Color cor;
  final VoidCallback onTap;
  const _Escolha({
    required this.selecionado,
    required this.icone,
    required this.rotulo,
    required this.cor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Toque(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selecionado ? cor.withAlpha(28) : Cores.fundo,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: selecionado ? cor : Colors.transparent, width: 2),
        ),
        child: Row(children: [
          Icon(icone, color: cor, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Text(rotulo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          ),
        ]),
      ),
    );
  }
}