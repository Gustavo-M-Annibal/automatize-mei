import 'package:flutter/material.dart';
import '../widgets/componentes.dart';
import '../widgets/dinheiro.dart';
import '../widgets/estado.dart';
import '../widgets/modelos.dart';
import 'dia.dart';
import 'gastos.dart';

class CaixaPage extends StatefulWidget {
  const CaixaPage({super.key});
  @override
  State<CaixaPage> createState() => _CaixaPageState();
}

class _CaixaPageState extends State<CaixaPage> {
  final Map<int, int> contagem = {};
  bool enviando = false;

  void _mudar(int centavos, int delta) {
    final novo = (contagem[centavos] ?? 0) + delta;
    if (novo < 0) return;
    setState(() => novo == 0 ? contagem.remove(centavos) : contagem[centavos] = novo);
  }

  Future<void> _fechar(Estado s, int esperado) async {
    final contado = somaCentavos(contagem);
    final dif = contado - esperado;
    final resumo = dif == 0
        ? 'A conta bateu certinho.'
        : (dif < 0 ? 'Faltam ${brl(-dif / 100)} na gaveta.' : 'Sobram ${brl(dif / 100)} na gaveta.');
    final ok = await confirmar(
      context,
      titulo: 'Fechar o caixa de hoje?',
      texto: '$resumo\n\nDepois de fechar, não dá para registrar vendas hoje. Se precisar, é só reabrir.',
      sim: 'Fechar caixa',
    );
    if (!ok || !mounted) return;
    setState(() => enviando = true);
    try {
      await s.fecharCaixa(contado / 100);
      if (!mounted) return;
      setState(() {
        contagem.clear();
        enviando = false;
      });
      await mostrarSucesso(context, 'Caixa fechado');
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
    final agora = DateTime.now();
    final fechamento = s.fechamentoDoDia(agora);
    if (fechamento != null) return _CaixaFechado(f: fechamento);

    final inset = MediaQuery.of(context).padding.bottom;
    final troco = (s.trocoFixo * 100).round();
    final dinheiro = (s.dinheiroDoDia(agora) * 100).round();
    final saidas = (s.saidasGavetaDoDia(agora) * 100).round();
    final esperado = troco + dinheiro - saidas;
    final contado = somaCentavos(contagem);
    final st = statusCaixa(contado, esperado);
    final progresso = esperado <= 0 ? 0.0 : (contado / esperado).clamp(0.0, 1.0).toDouble();
    final podeFechar = (s.vendasDoDia(agora).isNotEmpty || s.despesasDoDia(agora).isNotEmpty) && !enviando;

    return Stack(children: [
      ListView(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 200 + inset),
        children: [
          Titulo(
            'Caixa',
            fim: BotaoRedondo(
              icone: Icons.restart_alt_rounded,
              cor: Colors.white,
              tamanho: 46,
              onTap: contagem.isEmpty ? null : () => setState(contagem.clear),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
            decoration: cartao(raio: 34),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Dinheiro na gaveta',
                  style: TextStyle(fontSize: 15, color: Cores.suave, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text.rich(TextSpan(children: [
                const TextSpan(
                    text: 'R\$ ',
                    style: TextStyle(fontSize: 24, color: Cores.suave, fontWeight: FontWeight.w700)),
                TextSpan(
                    text: brl(contado / 100).replaceFirst('R\$ ', ''),
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w800, letterSpacing: -2, height: 1)),
              ])),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: progresso),
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) => LinearProgressIndicator(
                    value: v,
                    minHeight: 10,
                    color: st.cor,
                    backgroundColor: Cores.fundo,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(color: st.cor.withAlpha(30), borderRadius: BorderRadius.circular(16)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(st.icone, size: 20, color: st.txt),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(st.texto,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: st.txt)),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 10),
              const Divider(color: Cores.linha, height: 1),
              LinhaValor(
                Icons.savings_rounded,
                'Troco da gaveta',
                brl(troco / 100),
                nota: 'toque para mudar',
                onTap: () => mostrarFolha<void>(context, (_) => _FolhaTroco(atual: s.trocoFixo)),
              ),
              LinhaValor(Icons.payments_rounded, 'Vendas em dinheiro', '+ ${brl(dinheiro / 100)}'),
              LinhaValor(
                Icons.shopping_basket_rounded,
                'Gastos pagos da gaveta',
                '− ${brl(saidas / 100)}',
                onTap: () => abrirGastos(context),
              ),
              const Divider(color: Cores.linha, height: 1),
              LinhaValor(Icons.account_balance_wallet_rounded, 'Esperado na gaveta', brl(esperado / 100), forte: true),
              LinhaValor(
                Icons.credit_card_rounded,
                'Cartão',
                brl(s.cartaoDoDia(agora)),
                nota: 'não entra na gaveta',
              ),
            ]),
          ),
          const SizedBox(height: 14),
          GradeDinheiro(contagem: contagem, onMudar: _mudar),
        ],
      ),
      Positioned(
        left: 20,
        right: 20,
        bottom: 96 + inset,
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 10, 10, 10),
          decoration: BoxDecoration(
            color: Cores.tinta,
            borderRadius: BorderRadius.circular(36),
            boxShadow: const [BoxShadow(color: Color(0x40101828), blurRadius: 28, offset: Offset(0, 12))],
          ),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text('Contado',
                    style: TextStyle(fontSize: 12, color: Colors.white.withAlpha(170), fontWeight: FontWeight.w600)),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(brl(contado / 100),
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.8)),
                ),
              ]),
            ),
            BotaoAcao(
              icone: Icons.lock_rounded,
              texto: 'Fechar',
              cor: Cores.ok,
              onTap: podeFechar ? () => _fechar(s, esperado) : null,
            ),
          ]),
        ),
      ),
    ]);
  }
}

/// Define o troco que fica na gaveta todo dia.
class _FolhaTroco extends StatefulWidget {
  final double atual;
  const _FolhaTroco({required this.atual});
  @override
  State<_FolhaTroco> createState() => _FolhaTrocoState();
}

class _FolhaTrocoState extends State<_FolhaTroco> {
  late Map<int, int> contagem = decompor((widget.atual * 100).round());
  bool salvando = false;
  String? erro;

  void _mudar(int c, int delta) {
    final novo = (contagem[c] ?? 0) + delta;
    if (novo < 0) return;
    setState(() => novo == 0 ? contagem.remove(c) : contagem[c] = novo);
  }

  Future<void> _salvar() async {
    setState(() => salvando = true);
    try {
      await Escopo.de(context).setTrocoFixo(somaCentavos(contagem) / 100);
      if (mounted) Navigator.of(context).pop();
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
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Troco da gaveta',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.7)),
        const SizedBox(height: 4),
        const Text('É o dinheiro miúdo que você já deixa na gaveta antes de começar a vender.',
            style: TextStyle(fontSize: 14, color: Cores.suave, fontWeight: FontWeight.w600)),
        const SizedBox(height: 14),
        Text(brl(somaCentavos(contagem) / 100),
            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800, letterSpacing: -1.5)),
        const SizedBox(height: 14),
        GradeDinheiro(contagem: contagem, onMudar: _mudar),
        const SizedBox(height: 18),
        if (erro != null) ErroInline(erro!),
        SizedBox(
          width: double.infinity,
          child: BotaoAcao(
            icone: Icons.check_rounded,
            texto: 'Salvar troco',
            cor: Cores.ok,
            onTap: salvando ? null : _salvar,
          ),
        ),
      ]),
    );
  }
}

/// Resumo do dia depois de fechar o caixa.
class _CaixaFechado extends StatelessWidget {
  final Fechamento f;
  const _CaixaFechado({required this.f});

  @override
  Widget build(BuildContext context) {
    final s = Escopo.de(context);
    final st = statusCaixa((f.contado * 100).round(), (f.esperado * 100).round());
    final dif = (f.diferenca * 100).round();
    final guardar = f.contado - s.trocoFixo;
    return ListView(
      padding: paginaPad(context),
      children: [
        const Titulo('Caixa'),
        Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 18),
          decoration: cartao(raio: 34),
          child: Column(children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(color: Cores.ok.withAlpha(30), shape: BoxShape.circle),
              child: const Icon(Icons.lock_rounded, size: 42, color: Cores.ok),
            ),
            const SizedBox(height: 14),
            const Text('Caixa fechado',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.8)),
            Text('hoje às ${hora(f.data)}',
                style: const TextStyle(fontSize: 15, color: Cores.suave, fontWeight: FontWeight.w600)),
            const SizedBox(height: 18),
            LinhaValor(Icons.savings_rounded, 'Troco da gaveta', brl(f.troco)),
            LinhaValor(Icons.payments_rounded, 'Vendas em dinheiro', '+ ${brl(f.dinheiro)}'),
            LinhaValor(Icons.shopping_basket_rounded, 'Gastos da gaveta', '− ${brl(f.saidas)}'),
            LinhaValor(Icons.account_balance_wallet_rounded, 'Esperado', brl(f.esperado), forte: true),
            LinhaValor(Icons.back_hand_rounded, 'Contado', brl(f.contado), forte: true),
            LinhaValor(st.icone, 'Diferença', dif == 0 ? 'Bateu certinho' : brl(dif / 100), cor: st.txt),
            const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Divider(color: Cores.linha, height: 1)),
            LinhaValor(Icons.credit_card_rounded, 'Cartão', brl(f.cartao)),
            LinhaValor(Forma.pix.icone, 'Pix', brl(f.pix)),
            LinhaValor(Icons.receipt_long_rounded, 'Total vendido', brl(f.dinheiro + f.cartao + f.pix)),
            LinhaValor(
              Icons.savings_outlined,
              'Para guardar',
              brl(guardar < 0 ? 0 : guardar),
              nota: 'o contado menos o troco de amanhã',
              cor: Cores.ok,
            ),
          ]),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: BotaoAcao(
            icone: Icons.receipt_long_rounded,
            texto: 'Ver vendas do dia',
            onTap: () => abrirDia(context, DateTime.now()),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: BotaoSecundario(
            icone: Icons.lock_open_rounded,
            texto: 'Reabrir caixa',
            onTap: () => reabrirCaixaUI(context, s),
          ),
        ),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.nights_stay_rounded, size: 18, color: Cores.suave),
          const SizedBox(width: 8),
          Flexible(
            child: Text('Amanhã o caixa abre sozinho, com troco de ${brl(s.trocoFixo)}.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Cores.suave, fontWeight: FontWeight.w600)),
          ),
        ]),
      ],
    );
  }
}