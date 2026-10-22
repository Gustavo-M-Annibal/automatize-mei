import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'api.dart';
import 'estado.dart';
import 'modelos.dart';

class Cores {
  static const fundo = Color(0xFFF3F4F6);
  static const tinta = Color(0xFF0F1115);
  static const suave = Color(0xFF7A828C);
  static const linha = Color(0xFFE7E9EE);
  static const ok = Color(0xFF12A36E);
  static const alerta = Color(0xFFF5A524);
  static const alertaEscuro = Color(0xFFB26B00);
  static const erro = Color(0xFFE5484D);
  static const azul = Color(0xFF2F6FEB);
}

/// Aba aberta na barra de baixo. Qualquer tela pode trocar de aba por aqui.
final ValueNotifier<int> abaGlobal = ValueNotifier<int>(0);

void irParaAba(BuildContext context, int i) {
  Navigator.of(context).popUntil((r) => r.isFirst);
  abaGlobal.value = i;
}

Color clarear(Color c, [double q = 0.15]) {
  final h = HSLColor.fromColor(c);
  return h.withLightness((h.lightness + q).clamp(0.0, 1.0).toDouble()).toColor();
}

Color escurecer(Color c, [double q = 0.15]) => clarear(c, -q);

const List<BoxShadow> sombraSuave = [
  BoxShadow(color: Color(0x14101828), blurRadius: 24, offset: Offset(0, 8)),
];

BoxDecoration cartao({double raio = 28, Color cor = Colors.white, bool sombra = true}) => BoxDecoration(
      color: cor,
      borderRadius: BorderRadius.circular(raio),
      boxShadow: sombra ? sombraSuave : null,
    );

/// Espaço no fim das telas para a barra flutuante não cobrir o conteúdo.
EdgeInsets paginaPad(BuildContext c) =>
    EdgeInsets.fromLTRB(20, 0, 20, 120 + MediaQuery.of(c).padding.bottom);

List<double> totaisDias(Estado s, List<DateTime> dias) => [for (final d in dias) s.totalVendasDoDia(d)];

String msgErro(Object e) => e is ApiErro ? e.mensagem : 'Algo deu errado. Tente de novo.';

// ------------------------------------------------------------------- datas

const _semana = ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'];
const _meses = [
  'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
  'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
];

String dataLonga(DateTime d) => '${_semana[d.weekday - 1]}, ${d.day} de ${_meses[d.month - 1]}';

String rotuloDia(DateTime d) {
  final h = soDia(DateTime.now());
  final x = soDia(d);
  if (mesmoDia(x, h)) return 'Hoje';
  if (mesmoDia(x, DateTime(h.year, h.month, h.day - 1))) return 'Ontem';
  return '${_semana[x.weekday - 1].substring(0, 3)}, '
      '${x.day.toString().padLeft(2, '0')}/${x.month.toString().padLeft(2, '0')}';
}

String hora(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

// ----------------------------------------------------------------- widgets

class Titulo extends StatelessWidget {
  final String texto;
  final Widget? fim;
  const Titulo(this.texto, {super.key, this.fim});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 22, 0, 16),
      child: Row(children: [
        Expanded(
          child: Text(texto,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1)),
        ),
        if (fim != null) fim!,
      ]),
    );
  }
}

/// Topo das telas que abrem por cima (voltar + título).
class TopoVoltar extends StatelessWidget {
  final String titulo;
  const TopoVoltar(this.titulo, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 14, 0, 14),
      child: Row(children: [
        BotaoRedondo(
          icone: Icons.arrow_back_rounded,
          onTap: () => Navigator.of(context).pop(),
          cor: Colors.white,
          tamanho: 48,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(titulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.7)),
        ),
      ]),
    );
  }
}

class Toque extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const Toque({super.key, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) =>
      GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: child);
}

class BotaoRedondo extends StatelessWidget {
  final IconData icone;
  final VoidCallback? onTap;
  final Color cor;
  final Color corIcone;
  final double tamanho;
  const BotaoRedondo({
    super.key,
    required this.icone,
    required this.onTap,
    this.cor = Cores.fundo,
    this.corIcone = Cores.tinta,
    this.tamanho = 44,
  });

  @override
  Widget build(BuildContext context) {
    final ativo = onTap != null;
    return Material(
      color: ativo ? cor : cor.withAlpha(120),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: tamanho,
          height: tamanho,
          child: Icon(icone, size: tamanho * 0.5, color: corIcone.withAlpha(ativo ? 255 : 80)),
        ),
      ),
    );
  }
}

class Contador extends StatelessWidget {
  final int valor;
  final VoidCallback? onMais;
  final VoidCallback? onMenos;
  final bool grande;
  final Color fundo;
  const Contador({
    super.key,
    required this.valor,
    required this.onMais,
    required this.onMenos,
    this.grande = false,
    this.fundo = Cores.fundo,
  });

  @override
  Widget build(BuildContext context) {
    final t = grande ? 56.0 : 38.0;
    return Container(
      padding: EdgeInsets.all(grande ? 6 : 4),
      decoration: BoxDecoration(color: fundo, borderRadius: BorderRadius.circular(40)),
      child: Row(children: [
        BotaoRedondo(icone: Icons.remove_rounded, onTap: onMenos, tamanho: t, cor: Colors.white),
        Expanded(
          child: Center(
            child: Text('$valor',
                style: TextStyle(fontSize: grande ? 36 : 20, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          ),
        ),
        BotaoRedondo(
            icone: Icons.add_rounded, onTap: onMais, tamanho: t, cor: Cores.tinta, corIcone: Colors.white),
      ]),
    );
  }
}

class BotaoAcao extends StatelessWidget {
  final IconData icone;
  final String texto;
  final VoidCallback? onTap;
  final Color cor;
  const BotaoAcao({super.key, required this.icone, required this.texto, required this.onTap, this.cor = Cores.tinta});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: FilledButton.icon(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: cor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Cores.linha,
          disabledForegroundColor: Cores.suave,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        icon: Icon(icone, size: 26),
        label: Text(texto, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class BotaoSecundario extends StatelessWidget {
  final IconData icone;
  final String texto;
  final VoidCallback? onTap;
  const BotaoSecundario({super.key, required this.icone, required this.texto, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: Cores.tinta,
          backgroundColor: Colors.white,
          side: const BorderSide(color: Cores.linha, width: 1.5),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 18),
        ),
        icon: Icon(icone, size: 24),
        label: Text(texto, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class Pilula extends StatelessWidget {
  final IconData icone;
  final String texto;
  final Color cor;
  const Pilula(this.icone, this.texto, {super.key, this.cor = Cores.suave});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: Cores.fundo, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icone, size: 17, color: cor),
        const SizedBox(width: 6),
        Text(texto, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class CartaoStat extends StatelessWidget {
  final IconData icone;
  final String rotulo;
  final String valor;
  final Color cor;
  final VoidCallback? onTap;
  const CartaoStat({
    super.key,
    required this.icone,
    required this.rotulo,
    required this.valor,
    required this.cor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Toque(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: cartao(raio: 26),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: cor.withAlpha(30), shape: BoxShape.circle),
              child: Icon(icone, size: 20, color: cor),
            ),
            const Spacer(),
            if (onTap != null) const Icon(Icons.chevron_right_rounded, color: Cores.suave),
          ]),
          const SizedBox(height: 10),
          Text(rotulo, style: const TextStyle(fontSize: 13, color: Cores.suave, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(valor, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.6)),
          ),
        ]),
      ),
    );
  }
}

class LinhaValor extends StatelessWidget {
  final IconData icone;
  final String rotulo;
  final String valor;
  final Color cor;
  final String? nota;
  final VoidCallback? onTap;
  final bool forte;
  const LinhaValor(
    this.icone,
    this.rotulo,
    this.valor, {
    super.key,
    this.cor = Cores.tinta,
    this.nota,
    this.onTap,
    this.forte = false,
  });

  @override
  Widget build(BuildContext context) {
    final linha = Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(children: [
        Icon(icone, size: 22, color: Cores.suave),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(rotulo,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: forte ? FontWeight.w800 : FontWeight.w600,
                    color: forte ? Cores.tinta : Cores.suave)),
            if (nota != null)
              Text(nota!, style: const TextStyle(fontSize: 12, color: Cores.suave, fontWeight: FontWeight.w600)),
          ]),
        ),
        Text(valor, style: TextStyle(fontSize: forte ? 19 : 17, fontWeight: FontWeight.w800, color: cor)),
        if (onTap != null) ...[
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded, color: Cores.suave),
        ],
      ]),
    );
    return onTap == null ? linha : Toque(onTap: onTap, child: linha);
  }
}

class EstadoVazio extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String texto;
  final String? botao;
  final VoidCallback? onBotao;
  const EstadoVazio({
    super.key,
    required this.icone,
    required this.titulo,
    required this.texto,
    this.botao,
    this.onBotao,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: cartao(raio: 30),
      child: Column(children: [
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(color: Cores.fundo, shape: BoxShape.circle),
          child: Icon(icone, size: 34, color: Cores.suave),
        ),
        const SizedBox(height: 16),
        Text(titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
        const SizedBox(height: 6),
        Text(texto,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, color: Cores.suave, fontWeight: FontWeight.w600)),
        if (botao != null) ...[
          const SizedBox(height: 18),
          BotaoAcao(icone: Icons.add_rounded, texto: botao!, onTap: onBotao),
        ],
      ]),
    );
  }
}

/// Erro mostrado dentro das janelas (o aviso de baixo ficaria escondido atrás delas).
class ErroInline extends StatelessWidget {
  final String texto;
  const ErroInline(this.texto, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Cores.erro.withAlpha(24), borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded, color: Cores.erro, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text(texto,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Cores.erro)),
        ),
      ]),
    );
  }
}

class BarraEstoque extends StatelessWidget {
  final Produto produto;
  const BarraEstoque(this.produto, {super.key});

  @override
  Widget build(BuildContext context) {
    const seg = 10;
    final cheios = (produto.estoque / 3).ceil().clamp(0, seg).toInt();
    final baixo = produto.estoque <= 5;
    final cor = baixo ? Cores.alerta : produto.visual.cor;
    return Row(children: [
      for (var i = 0; i < seg; i++)
        Expanded(
          child: Container(
            height: 7,
            margin: EdgeInsets.only(right: i == seg - 1 ? 0 : 3),
            decoration: BoxDecoration(
              color: i < cheios ? cor : Cores.linha,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
    ]);
  }
}

class LinhaPainter extends CustomPainter {
  final List<double> v;
  final Color cor;
  LinhaPainter(this.v, this.cor);

  @override
  void paint(Canvas canvas, Size size) {
    if (v.length < 2) return;
    const inset = 14.0, pad = 12.0;
    final mx = math.max(v.reduce(math.max), 1.0);
    final passo = (size.width - inset * 2) / (v.length - 1);
    final pts = [
      for (var i = 0; i < v.length; i++)
        Offset(inset + i * passo, pad + (size.height - pad * 2) * (1 - v[i] / mx)),
    ];
    final linha = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      final a = pts[i - 1], b = pts[i];
      final meio = (a.dx + b.dx) / 2;
      linha.cubicTo(meio, a.dy, meio, b.dy, b.dx, b.dy);
    }
    final area = Path.from(linha)
      ..lineTo(pts.last.dx, size.height)
      ..lineTo(pts.first.dx, size.height)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [cor.withAlpha(55), cor.withAlpha(0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      linha,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..color = cor,
    );
    canvas.drawCircle(pts.last, 8, Paint()..color = Colors.white);
    canvas.drawCircle(
      pts.last,
      8,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..color = cor,
    );
  }

  @override
  bool shouldRepaint(covariant LinhaPainter old) => old.v != v || old.cor != cor;
}

// ---------------------------------------------------------- janelas e avisos

Future<T?> mostrarFolha<T>(BuildContext context, Widget Function(BuildContext) builder) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(36))),
    builder: builder,
  );
}

Future<bool> confirmar(
  BuildContext context, {
  required String titulo,
  String? texto,
  String sim = 'Sim',
  String nao = 'Voltar',
  bool perigo = false,
}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w800)),
      content: texto == null ? null : Text(texto),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(nao)),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: perigo ? Cores.erro : Cores.tinta),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(sim),
        ),
      ],
    ),
  );
  return r == true;
}

/// Confirmação grande que fecha sozinha (ou ao tocar fora).
Future<void> mostrarSucesso(BuildContext context, String texto) async {
  if (!context.mounted) return;
  final nav = Navigator.of(context, rootNavigator: true);
  var aberto = true;
  showDialog<void>(
    context: context,
    barrierColor: Colors.black26,
    builder: (_) => Dialog(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(40, 32, 40, 30),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.6, end: 1),
            duration: const Duration(milliseconds: 420),
            curve: Curves.elasticOut,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(color: Cores.ok.withAlpha(30), shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, size: 58, color: Cores.ok),
            ),
          ),
          const SizedBox(height: 16),
          Text(texto, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        ]),
      ),
    ),
  ).then((_) => aberto = false);
  await Future.delayed(const Duration(milliseconds: 1000));
  if (aberto) nav.pop();
}

void aviso(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    backgroundColor: Cores.tinta,
    content: Row(children: [
      const Icon(Icons.error_outline_rounded, color: Cores.alerta),
      const SizedBox(width: 12),
      Expanded(child: Text(msg, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
    ]),
  ));
}

// ------------------------------------------------------------------- caixa

/// Cor, ícone e frase da conferência da gaveta (valores em centavos).
({Color cor, Color txt, IconData icone, String texto}) statusCaixa(int contado, int esperado) {
  final dif = contado - esperado;
  if (contado == 0 && esperado <= 0) {
    return (cor: Cores.ok, txt: Cores.ok, icone: Icons.check_circle_rounded, texto: 'Sem dinheiro para conferir');
  }
  if (contado == 0) {
    return (cor: Cores.suave, txt: Cores.suave, icone: Icons.touch_app_rounded, texto: 'Toque no dinheiro para contar');
  }
  if (dif == 0) {
    return (cor: Cores.ok, txt: Cores.ok, icone: Icons.check_circle_rounded, texto: 'Bateu certinho');
  }
  if (dif < 0) {
    return (cor: Cores.alerta, txt: Cores.alertaEscuro, icone: Icons.south_rounded, texto: 'Faltam ${brl(-dif / 100)}');
  }
  return (cor: Cores.azul, txt: Cores.azul, icone: Icons.north_rounded, texto: 'Sobram ${brl(dif / 100)}');
}

Future<void> reabrirCaixaUI(BuildContext context, Estado s) async {
  final ok = await confirmar(
    context,
    titulo: 'Reabrir o caixa de hoje?',
    texto: 'O fechamento de hoje será apagado e você poderá vender de novo. Depois é só fechar outra vez.',
    sim: 'Reabrir',
  );
  if (!ok || !context.mounted) return;
  try {
    await s.reabrirCaixa();
  } catch (e) {
    if (context.mounted) aviso(context, msgErro(e));
  }
}