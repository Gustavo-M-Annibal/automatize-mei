import 'package:flutter/material.dart';
import 'arte.dart';
import '../widgets/componentes.dart';
import '../widgets/estado.dart';
import '../widgets/modelos.dart';
import 'gastos.dart';

void abrirDia(BuildContext context, DateTime dia) {
  Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => DiaPage(dia: dia)));
}

class DiaPage extends StatelessWidget {
  final DateTime dia;
  const DiaPage({super.key, required this.dia});

  Future<void> _cancelar(
      BuildContext context, Estado s, Venda v, Produto? p) async {
    if (s.fechamentoDoDia(v.data) != null) {
      aviso(
        context,
        mesmoDia(v.data, DateTime.now())
            ? 'O caixa já foi fechado. Reabra o caixa para cancelar.'
            : 'Esse dia já foi fechado. Não dá para cancelar vendas.',
      );
      return;
    }
    final ok = await confirmar(
      context,
      titulo: 'Cancelar esta venda?',
      texto:
          '${v.quantidade} × ${p?.nome ?? 'produto'} · ${brl(v.valor)}\nO estoque volta para o freezer.',
      sim: 'Cancelar venda',
      nao: 'Manter',
      perigo: true,
    );
    if (!ok || !context.mounted) return;
    try {
      await s.cancelarVendas([v]);
    } catch (e) {
      if (context.mounted) aviso(context, msgErro(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = Escopo.de(context);
    final vendas = s.vendasDoDia(dia).toList()
      ..sort((a, b) => b.data.compareTo(a.data));
    final vendido = s.totalVendasDoDia(dia);
    final gastos = s.gastosDoDia(dia);
    final lucro = cent(vendido - gastos);
    final f = s.fechamentoDoDia(dia);
    final eHoje = mesmoDia(dia, DateTime.now());

    Widget? cartaoCaixa;
    if (f != null) {
      final st =
          statusCaixa((f.contado * 100).round(), (f.esperado * 100).round());
      final dif = (f.diferenca * 100).round();
      cartaoCaixa = Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        decoration: cartao(raio: 28),
        child: Column(children: [
          Row(children: [
            const Icon(Icons.lock_rounded, color: Cores.ok),
            const SizedBox(width: 10),
            Text('Caixa fechado às ${hora(f.data)}',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 6),
          LinhaValor(Icons.account_balance_wallet_rounded, 'Esperado',
              brl(f.esperado)),
          LinhaValor(Icons.back_hand_rounded, 'Contado', brl(f.contado)),
          LinhaValor(st.icone, 'Diferença',
              dif == 0 ? 'Bateu certinho' : brl(dif / 100),
              cor: st.txt),
          LinhaValor(Icons.credit_card_rounded, 'Cartão', brl(f.cartao)),
        ]),
      );
    } else if (eHoje) {
      cartaoCaixa = Container(
        padding: const EdgeInsets.all(18),
        decoration: cartao(raio: 28),
        child: Column(children: [
          const Row(children: [
            Icon(Icons.lock_open_rounded, color: Cores.alertaEscuro),
            SizedBox(width: 10),
            Text('Caixa aberto',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: BotaoAcao(
                icone: Icons.payments_rounded,
                texto: 'Ir para o caixa',
                onTap: () => irParaAba(context, 3)),
          ),
        ]),
      );
    } else if (vendas.isNotEmpty) {
      cartaoCaixa = Container(
        padding: const EdgeInsets.all(16),
        decoration: cartao(raio: 28),
        child: const Row(children: [
          Icon(Icons.lock_open_rounded, color: Cores.alertaEscuro),
          SizedBox(width: 10),
          Expanded(
            child: Text('O caixa deste dia não foi fechado',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          ),
        ]),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            TopoVoltar(dataLonga(dia)),
            Container(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
              decoration: cartao(raio: 34),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Vendido',
                        style: TextStyle(
                            fontSize: 15,
                            color: Cores.suave,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text.rich(TextSpan(children: [
                      const TextSpan(
                          text: 'R\$ ',
                          style: TextStyle(
                              fontSize: 24,
                              color: Cores.suave,
                              fontWeight: FontWeight.w700)),
                      TextSpan(
                          text: brl(vendido).replaceFirst('R\$ ', ''),
                          style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -2,
                              height: 1)),
                    ])),
                    const SizedBox(height: 14),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      Pilula(Icons.shopping_bag_outlined,
                          '${s.itensDoDia(dia)} unidades'),
                      Pilula(Forma.dinheiro.icone, brl(s.dinheiroDoDia(dia)),
                          cor: Forma.dinheiro.cor),
                      Pilula(Forma.cartao.icone, brl(s.cartaoDoDia(dia)),
                          cor: Forma.cartao.cor),
                    ]),
                  ]),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: CartaoStat(
                  icone: Icons.receipt_long_rounded,
                  rotulo: 'Gastos',
                  valor: brl(gastos),
                  cor: Cores.erro,
                  onTap: () => abrirGastos(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CartaoStat(
                  icone: Icons.trending_up_rounded,
                  rotulo: 'Lucro',
                  valor: brl(lucro),
                  cor: lucro >= 0 ? Cores.ok : Cores.erro,
                ),
              ),
            ]),
            if (cartaoCaixa != null) ...[
              const SizedBox(height: 12),
              cartaoCaixa
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 26, 0, 10),
              child: Row(children: [
                const Text('Vendas',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5)),
                const SizedBox(width: 10),
                Pilula(Icons.tag_rounded, '${vendas.length}'),
              ]),
            ),
            if (vendas.isEmpty)
              const EstadoVazio(
                icone: Icons.shopping_bag_outlined,
                titulo: 'Sem vendas neste dia',
                texto: 'Quando houver vendas, elas aparecem aqui.',
              )
            else
              for (final v in vendas)
                _LinhaVenda(
                    v: v,
                    onTap: () =>
                        _cancelar(context, s, v, s.produtoPorId(v.produtoId))),
            if (vendas.isNotEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text('Toque numa venda para cancelar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13,
                        color: Cores.suave,
                        fontWeight: FontWeight.w600)),
              ),
          ],
        ),
      ),
    );
  }
}

class _LinhaVenda extends StatelessWidget {
  final Venda v;
  final VoidCallback onTap;
  const _LinhaVenda({required this.v, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = Escopo.de(context).produtoPorId(v.produtoId);
    return Toque(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
        decoration: cartao(raio: 24),
        child: Row(children: [
          SizedBox(
            width: 52,
            height: 52,
            child: p != null
                ? Center(child: Arte(p, tamanho: 46))
                : const Icon(Icons.icecream_outlined,
                    color: Cores.suave, size: 30),
          ),
          const SizedBox(width: 10),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p?.nome ?? 'Sabor removido',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
              Row(children: [
                Icon(v.forma.icone, size: 14, color: v.forma.cor),
                const SizedBox(width: 4),
                Text('${v.quantidade} × · ${hora(v.data)}',
                    style: const TextStyle(
                        fontSize: 12,
                        color: Cores.suave,
                        fontWeight: FontWeight.w600)),
              ]),
            ]),
          ),
          Text(brl(v.valor),
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4)),
        ]),
      ),
    );
  }
}
