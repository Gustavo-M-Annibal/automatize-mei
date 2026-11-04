import 'package:flutter/material.dart';
import 'arte.dart';
import '../widgets/componentes.dart';
import '../widgets/estado.dart';
import '../widgets/modelos.dart';
import 'caixa.dart';
import 'dia.dart';
import 'freezer.dart';
import 'gastos.dart';
import 'resumo.dart';
import 'vender.dart';

const _letras = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) Escopo.de(context).aoVoltar();
  }

  @override
  Widget build(BuildContext context) {
    final s = Escopo.de(context);
    if (s.semConexao) return const _SemConexao();
    return Scaffold(
      body: ValueListenableBuilder<int>(
        valueListenable: abaGlobal,
        builder: (context, aba, _) => Stack(children: [
          SafeArea(
            bottom: false,
            child: IndexedStack(index: aba, children: const [
              InicioPage(),
              VenderPage(),
              FreezerPage(),
              CaixaPage(),
              ResumoPage(),
            ]),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 14 + MediaQuery.of(context).padding.bottom,
            child: _Barra(aba: aba, onTap: (i) => abaGlobal.value = i),
          ),
        ]),
      ),
    );
  }
}

/// Ajuda a reagir quando o app volta para a tela (para detectar a virada do dia).
mixin WidgetBindingObserverMixin<T extends StatefulWidget> on State<T>
    implements WidgetsBindingObserver {
  void aoVoltarParaApp();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) aoVoltarParaApp();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _Barra extends StatelessWidget {
  final int aba;
  final ValueChanged<int> onTap;
  const _Barra({required this.aba, required this.onTap});

  static const _itens = [
    (Icons.home_rounded, 'Início'),
    (Icons.shopping_bag_rounded, 'Vender'),
    (Icons.ac_unit_rounded, 'Freezer'),
    (Icons.payments_rounded, 'Caixa'),
    (Icons.show_chart_rounded, 'Resumo'),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, c) {
      const selW = 122.0;
      final outroW = (c.maxWidth - 16 - selW) / 4;
      return Container(
        height: 70,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(35),
          boxShadow: const [
            BoxShadow(
                color: Color(0x26101828), blurRadius: 30, offset: Offset(0, 10))
          ],
        ),
        child: Row(children: [
          for (var i = 0; i < _itens.length; i++)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                width: i == aba ? selW : outroW,
                height: 54,
                decoration: BoxDecoration(
                  color: i == aba ? Cores.tinta : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: ClipRect(
                  child: Center(
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(_itens[i].$1,
                          size: 25,
                          color: i == aba ? Colors.white : Cores.suave),
                      if (i == aba) ...[
                        const SizedBox(width: 7),
                        Text(_itens[i].$2,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700)),
                      ],
                    ]),
                  ),
                ),
              ),
            ),
        ]),
      );
    });
  }
}

class InicioPage extends StatelessWidget {
  const InicioPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = Escopo.de(context);
    final agora = DateTime.now();
    final saudacao = agora.hour < 12
        ? 'Bom dia'
        : (agora.hour < 18 ? 'Boa tarde' : 'Boa noite');
    final dias = s.ultimosDias(7);
    final t = totaisDias(s, dias);
    final media = t.fold(0.0, (a, b) => a + b) / 7;
    final acabando = s.acabando;
    final ontem = DateTime(agora.year, agora.month, agora.day - 1);
    final ontemPendente =
        s.fechamentoDoDia(ontem) == null && s.vendasDoDia(ontem).isNotEmpty;
    final fechado = s.caixaFechadoHoje;

    return RefreshIndicator(
      onRefresh: s.carregar,
      child: ListView(
        padding: paginaPad(context),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 18, 0, 18),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Image.asset('assets/logo/automatize.png', height: 26),
                const Spacer(),
                const _Conexao(),
              ]),
              const SizedBox(height: 18),
              Text(saudacao,
                  style: const TextStyle(
                      fontSize: 15,
                      color: Cores.suave,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(dataLonga(agora),
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.7)),
            ]),
          ),
          Toque(
            onTap: () => abrirDia(context, agora),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 22, 20, 18),
              decoration: cartao(raio: 34),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Text('Vendido hoje',
                          style: TextStyle(
                              fontSize: 15,
                              color: Cores.suave,
                              fontWeight: FontWeight.w600)),
                      const Spacer(),
                      const Icon(Icons.chevron_right_rounded,
                          color: Cores.suave),
                    ]),
                    const SizedBox(height: 2),
                    Text.rich(TextSpan(children: [
                      const TextSpan(
                          text: 'R\$ ',
                          style: TextStyle(
                              fontSize: 26,
                              color: Cores.suave,
                              fontWeight: FontWeight.w700)),
                      TextSpan(
                          text: brl(s.vendidoHoje).replaceFirst('R\$ ', ''),
                          style: const TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -2.5,
                              height: 1)),
                    ])),
                    const SizedBox(height: 14),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      Pilula(Icons.shopping_bag_outlined,
                          '${s.itensHoje} unidades'),
                      Pilula(
                          Icons.trending_up_rounded, 'média ${brl(media)}/dia'),
                      if (fechado)
                        const Pilula(Icons.lock_rounded, 'caixa fechado',
                            cor: Cores.ok),
                    ]),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 90,
                      width: double.infinity,
                      child: CustomPaint(painter: LinhaPainter(t, Cores.tinta)),
                    ),
                    const SizedBox(height: 6),
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
                                        color: i == 6
                                            ? Cores.tinta
                                            : Cores.suave)),
                              ),
                            ),
                        ]),
                  ]),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: BotaoAcao(
                icone: Icons.add_rounded,
                texto: 'Nova venda',
                onTap: () => abaGlobal.value = 1),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: BotaoSecundario(
                icone: Icons.receipt_long_outlined,
                texto: 'Gastos',
                onTap: () => abrirGastos(context),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: BotaoSecundario(
                icone: fechado ? Icons.lock_rounded : Icons.payments_outlined,
                texto: fechado ? 'Caixa fechado' : 'Caixa',
                onTap: () => abaGlobal.value = 3,
              ),
            ),
          ]),
          if (ontemPendente) ...[
            const SizedBox(height: 14),
            Toque(
              onTap: () => abrirDia(context, ontem),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: cartao(raio: 26),
                child: Row(children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                        color: Cores.alerta.withAlpha(36),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.lock_open_rounded,
                        color: Cores.alertaEscuro, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Ontem o caixa ficou aberto',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Cores.suave),
                ]),
              ),
            ),
          ],
          if (acabando.isNotEmpty) ...[
            const SizedBox(height: 14),
            Toque(
              onTap: () => abaGlobal.value = 2,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: cartao(raio: 26),
                child: Row(children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                        color: Cores.alerta.withAlpha(36),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.priority_high_rounded,
                        color: Cores.alertaEscuro, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Wrap(spacing: 14, runSpacing: 6, children: [
                      for (final p in acabando)
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          Arte(p, tamanho: 34),
                          const SizedBox(width: 4),
                          Text('${p.estoque}',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w800)),
                        ]),
                    ]),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Cores.suave),
                ]),
              ),
            ),
          ],
          if (s.produtos.isEmpty) ...[
            const SizedBox(height: 18),
            EstadoVazio(
              icone: Icons.ac_unit_rounded,
              titulo: 'Cadastre seus sabores',
              texto: 'Comece cadastrando os geladinhos que você vende.',
              botao: 'Cadastrar sabor',
              onBotao: () => abrirFormProduto(context),
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 28, 0, 8),
              child: Row(children: [
                const Expanded(
                  child: Text('No freezer',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5)),
                ),
                TextButton(
                  onPressed: () => abaGlobal.value = 2,
                  child: const Text('Ver tudo',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Cores.suave)),
                ),
              ]),
            ),
            SizedBox(
              height: 176,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: s.produtos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) {
                  final p = s.produtos[i];
                  return Toque(
                    onTap: () => abrirProduto(context, p),
                    child: Container(
                      width: 128,
                      padding: const EdgeInsets.all(14),
                      decoration: cartao(raio: 28),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(child: Arte(p, tamanho: 76)),
                            const Spacer(),
                            Text('${p.estoque}',
                                style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.8)),
                            const SizedBox(height: 6),
                            BarraEstoque(p),
                          ]),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Conexao extends StatelessWidget {
  const _Conexao();

  @override
  Widget build(BuildContext context) {
    final s = Escopo.de(context);
    return Toque(
      onTap: () => configurarConexao(context, s),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: cartao(raio: 22),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
                color: s.local ? Cores.alerta : Cores.ok,
                shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(s.local ? 'Local' : 'Online',
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

void configurarConexao(BuildContext context, Estado s) {
  final c = TextEditingController(text: s.api.baseUrl);
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(s.local ? 'Modo local' : 'Conectado ao servidor'),
      content: SingleChildScrollView(
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.local
                  ? 'Os dados ficam salvos só neste aparelho. Para usar o servidor do projeto, informe o endereço e toque em Conectar.'
                  : 'Os dados vêm e vão para o servidor do projeto.'),
              const SizedBox(height: 14),
              TextField(
                controller: c,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                    labelText: 'Endereço da API', border: OutlineInputBorder()),
              ),
              if (s.local) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final ok = await confirmar(
                      context,
                      titulo: 'Carregar dados de exemplo?',
                      texto:
                          'Os dados deste aparelho serão trocados por uma semana de vendas de exemplo.',
                      sim: 'Carregar',
                    );
                    if (ok) await s.carregarExemplo();
                  },
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: const Text('Dados de exemplo'),
                ),
                TextButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final ok = await confirmar(
                      context,
                      titulo: 'Apagar tudo?',
                      texto:
                          'Vendas, gastos, fechamentos e sabores deste aparelho serão apagados.',
                      sim: 'Apagar',
                      perigo: true,
                    );
                    if (ok) await s.apagarLocal();
                  },
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: Cores.erro),
                  label: const Text('Apagar dados deste aparelho',
                      style: TextStyle(color: Cores.erro)),
                ),
              ],
            ]),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx), child: const Text('Fechar')),
        FilledButton(
          onPressed: () async {
            Navigator.pop(ctx);
            try {
              await s.conectar(c.text);
            } catch (e) {
              if (context.mounted) aviso(context, msgErro(e));
            }
          },
          child: const Text('Conectar'),
        ),
      ],
    ),
  );
}

class _SemConexao extends StatelessWidget {
  const _SemConexao();

  @override
  Widget build(BuildContext context) {
    final s = Escopo.de(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                    color: Cores.alerta.withAlpha(40), shape: BoxShape.circle),
                child: const Icon(Icons.cloud_off_rounded,
                    size: 46, color: Cores.alertaEscuro),
              ),
              const SizedBox(height: 20),
              const Text('Sem conexão',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8)),
              const SizedBox(height: 8),
              const Text(
                'Não consegui falar com o servidor. Confira a internet e tente de novo.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 15,
                    color: Cores.suave,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                child: BotaoAcao(
                    icone: Icons.refresh_rounded,
                    texto: 'Tentar de novo',
                    onTap: s.carregar),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => configurarConexao(context, s),
                child: const Text('Mudar endereço da API'),
              ),
              TextButton(
                onPressed: () async {
                  final ok = await confirmar(
                    context,
                    titulo: 'Usar só neste aparelho?',
                    texto:
                        'O app vai funcionar sem o servidor. Os dados ficarão salvos só neste aparelho.',
                    sim: 'Usar aqui',
                  );
                  if (ok) await s.usarLocal();
                },
                child: const Text('Usar só neste aparelho'),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
