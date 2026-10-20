import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'arte.dart';
import '../componentes.dart';
import '../estado.dart';
import '../modelos.dart';
import 'dia.dart';
import 'freezer.dart';
import 'gastos.dart';

const _letras = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];

class ResumoPage extends StatefulWidget {
  const ResumoPage({super.key});
  @override
  State<ResumoPage> createState() => _ResumoPageState();
}

class _ResumoPageState extends State<ResumoPage> {
  int periodo = 7;
  int? horaSel;

  @override
  Widget build(BuildContext context) {
    final s = Escopo.de(context);
    final dias = s.ultimosDias(periodo);
    final totais = totaisDias(s, dias);
    final ini = dias.first;
    final vendas = s.vendas.where((v) => !v.data.isBefore(ini)).toList();
    final vendido = cent(totais.fold(0.0, (a, b) => a + b));
    final gastos = cent(s.despesas
        .where((d) => !d.data.isBefore(ini))
        .fold(0.0, (a, d) => a + d.valor));
    final lucro = cent(vendido - gastos);
    final unidades = vendas.fold(0, (a, v) => a + v.quantidade);
    final dinheiro = cent(vendas
        .where((v) => v.forma == Forma.dinheiro)
        .fold(0.0, (a, v) => a + v.valor));
    final cartaoV = cent(vendido - dinheiro);

    final porProduto = <int, int>{};
    final porHora = <int, int>{};
    for (final v in vendas) {
      porProduto[v.produtoId] = (porProduto[v.produtoId] ?? 0) + v.quantidade;
      porHora[v.data.hour] = (porHora[v.data.hour] ?? 0) + v.quantidade;
    }
    final ranking = porProduto.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topo = ranking.isEmpty ? 1 : ranking.first.value;
    int? horaPico;
    var maxHora = 0;
    porHora.forEach((h, q) {
      if (q > maxHora) {
        maxHora = q;
        horaPico = h;
      }
    });
    final horaMostrada = horaSel ?? horaPico;
    final qtdHora = horaMostrada == null ? 0 : (porHora[horaMostrada] ?? 0);
    final maiorDia = totais.fold(0.0, (a, b) => b > a ? b : a);

    return ListView(
      padding: paginaPad(context),
      children: [
        Titulo('Resumo',
            fim: _Seletor(
                periodo: periodo, onMudar: (p) => setState(() => periodo = p))),
        if (vendas.isEmpty && gastos == 0)
          const EstadoVazio(
            icone: Icons.show_chart_rounded,
            titulo: 'Ainda sem movimento',
            texto:
                'Quando você vender ou anotar gastos, os números aparecem aqui.',
          )
        else ...[
          Container(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
            decoration: cartao(raio: 34),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Vendido em $periodo dias',
                  style: const TextStyle(
                      fontSize: 15,
                      color: Cores.suave,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(brl(vendido),
                  style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.8,
                      height: 1.1)),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: [
                Pilula(Icons.shopping_bag_outlined, '$unidades unidades'),
                Pilula(Icons.trending_up_rounded,
                    'média ${brl(vendido / periodo)}/dia'),
              ]),
              const SizedBox(height: 14),
              SizedBox(
                height: 130,
                width: double.infinity,
                child: CustomPaint(painter: LinhaPainter(totais, Cores.tinta)),
              ),
              const SizedBox(height: 6),
              if (periodo == 7)
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (var i = 0; i < 7; i++)
                        SizedBox(
                          width: 28,
                          child: Center(
                            child: Text(_letras[dias[i].weekday - 1],
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: i == 6
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: i == 6 ? Cores.tinta : Cores.suave)),
                          ),
                        ),
                    ])
              else
                const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('há 30 dias',
                          style: TextStyle(
                              fontSize: 12,
                              color: Cores.suave,
                              fontWeight: FontWeight.w600)),
                      Text('hoje',
                          style: TextStyle(
                              fontSize: 12,
                              color: Cores.suave,
                              fontWeight: FontWeight.w600)),
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
                icone: Icons.savings_rounded,
                rotulo: 'Lucro',
                valor: brl(lucro),
                cor: lucro >= 0 ? Cores.ok : Cores.erro,
              ),
            ),
          ]),
          const SizedBox(height: 12),
          _CartaoPagamento(dinheiro: dinheiro, cartao: cartaoV),
          if (horaPico != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: cartao(raio: 30),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                            color: Cores.alerta.withAlpha(40),
                            shape: BoxShape.circle),
                        child: const Icon(Icons.schedule_rounded,
                            color: Cores.alertaEscuro, size: 25),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  horaSel == null
                                      ? 'Mais movimento'
                                      : '$qtdHora unidades',
                                  style: const TextStyle(
                                      fontSize: 14,
                                      color: Cores.suave,
                                      fontWeight: FontWeight.w600)),
                              Text('${horaMostrada}h – ${horaMostrada! + 1}h',
                                  style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.8)),
                            ]),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 70,
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            for (var h = 6; h <= 20; h++)
                              Expanded(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => setState(
                                      () => horaSel = horaSel == h ? null : h),
                                  child: Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 2),
                                      height: 6 +
                                          62 *
                                              ((porHora[h] ?? 0) /
                                                  (maxHora == 0 ? 1 : maxHora)),
                                      decoration: BoxDecoration(
                                        color: h == horaMostrada
                                            ? Cores.tinta
                                            : Cores.linha,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ]),
                    ),
                    const SizedBox(height: 6),
                    const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('6h',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Cores.suave,
                                  fontWeight: FontWeight.w600)),
                          Text('13h',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Cores.suave,
                                  fontWeight: FontWeight.w600)),
                          Text('20h',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Cores.suave,
                                  fontWeight: FontWeight.w600)),
                        ]),
                  ]),
            ),
          ],
          if (ranking.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 26, 0, 10),
              child: Row(children: const [
                Text('Mais vendidos',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5)),
              ]),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(18, 10, 20, 10),
              decoration: cartao(raio: 30),
              child: Column(children: [
                for (final e in ranking.take(5))
                  if (s.produtoPorId(e.key) case final p?)
                    Toque(
                      onTap: () => abrirProduto(context, p),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        child: Row(children: [
                          SizedBox(
                              width: 50,
                              height: 50,
                              child: Center(child: Arte(p, tamanho: 46))),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.nome,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 4),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: e.value / topo,
                                      minHeight: 10,
                                      color: p.visual.cor,
                                      backgroundColor: Cores.fundo,
                                    ),
                                  ),
                                ]),
                          ),
                          const SizedBox(width: 14),
                          SizedBox(
                            width: 36,
                            child: Text('${e.value}',
                                textAlign: TextAlign.end,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w800)),
                          ),
                        ]),
                      ),
                    ),
              ]),
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 26, 0, 10),
            child: Row(children: const [
              Text('Dias',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5)),
            ]),
          ),
          for (var i = dias.length - 1; i >= 0; i--)
            _LinhaDia(
              dia: dias[i],
              total: totais[i],
              fracao: maiorDia == 0 ? 0 : totais[i] / maiorDia,
              fechado: s.fechamentoDoDia(dias[i]) != null,
              pendente: s.fechamentoDoDia(dias[i]) == null &&
                  !mesmoDia(dias[i], DateTime.now()) &&
                  s.vendasDoDia(dias[i]).isNotEmpty,
              onTap: () => abrirDia(context, dias[i]),
            ),
        ],
      ],
    );
  }
}

class _Seletor extends StatelessWidget {
  final int periodo;
  final ValueChanged<int> onMudar;
  const _Seletor({required this.periodo, required this.onMudar});

  @override
  Widget build(BuildContext context) {
    Widget item(int p, String t) => Toque(
          onTap: () => onMudar(p),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: periodo == p ? Cores.tinta : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(t,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: periodo == p ? Colors.white : Cores.suave)),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: cartao(raio: 24),
      child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [item(7, '7 dias'), item(30, '30 dias')]),
    );
  }
}

class _CartaoPagamento extends StatelessWidget {
  final double dinheiro;
  final double cartao;
  const _CartaoPagamento({required this.dinheiro, required this.cartao});

  @override
  Widget build(BuildContext context) {
    final total = dinheiro + cartao;
    final fd = total == 0 ? 50 : (dinheiro / total * 100).round();
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      decoration: cartaoDeco(),
      child: Column(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 14,
            child: total == 0
                ? Container(color: Cores.fundo)
                : Row(children: [
                    Expanded(
                        flex: math.max(fd, 1),
                        child: Container(color: Forma.dinheiro.cor)),
                    Expanded(
                        flex: math.max(100 - fd, 1),
                        child: Container(color: Forma.cartao.cor)),
                  ]),
          ),
        ),
        const SizedBox(height: 8),
        LinhaValor(Forma.dinheiro.icone, 'Dinheiro', brl(dinheiro),
            nota: total == 0 ? null : '$fd% das vendas'),
        LinhaValor(Forma.cartao.icone, 'Cartão', brl(cartao),
            nota: total == 0 ? null : '${100 - fd}% das vendas'),
      ]),
    );
  }

  BoxDecoration cartaoDeco() => cartao_(26);
}

BoxDecoration cartao_(double raio) => cartao(raio: raio);

class _LinhaDia extends StatelessWidget {
  final DateTime dia;
  final double total;
  final double fracao;
  final bool fechado;
  final bool pendente;
  final VoidCallback onTap;
  const _LinhaDia({
    required this.dia,
    required this.total,
    required this.fracao,
    required this.fechado,
    required this.pendente,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Toque(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
        decoration: cartao(raio: 24),
        child: Row(children: [
          SizedBox(
            width: 82,
            child: Text(rotuloDia(dia),
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: fracao.clamp(0.0, 1.0).toDouble(),
                minHeight: 10,
                color: Cores.tinta,
                backgroundColor: Cores.fundo,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 82,
            child: Text(brl(total),
                textAlign: TextAlign.end,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3)),
          ),
          const SizedBox(width: 4),
          if (fechado)
            const Icon(Icons.lock_rounded, size: 18, color: Cores.ok)
          else if (pendente)
            const Icon(Icons.lock_open_rounded,
                size: 18, color: Cores.alertaEscuro)
          else
            const SizedBox(width: 18),
          const Icon(Icons.chevron_right_rounded, color: Cores.suave),
        ]),
      ),
    );
  }
}
