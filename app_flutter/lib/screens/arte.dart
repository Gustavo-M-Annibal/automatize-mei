import 'package:flutter/material.dart';
import '../widgets/componentes.dart';
import '../widgets/modelos.dart';
/// "Morango" -> "morango"; "Salgadinho de copo" -> "salgadinho_de_copo"
String slugDe(String nome) {
  const de = 'áàâãäéèêëíìîïóòôõöúùûüç';
  const para = 'aaaaaeeeeiiiiooooouuuuc';
  var s = nome.toLowerCase();
  for (var i = 0; i < de.length; i++) {
    s = s.replaceAll(de[i], para[i]);
  }
  return s
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
}

/// Mostra a foto do produto se ela existir em assets/sabores/<nome>.png|jpg.
/// Sem foto, usa o desenho (geladinho em saquinho ou copo de salgadinho).
class Arte extends StatelessWidget {
  final Produto produto;
  final double tamanho;
  const Arte(this.produto, {super.key, this.tamanho = 80});

  @override
  Widget build(BuildContext context) {
    final v = produto.visual;
    final slug = slugDe(produto.nome);

    final desenho = SizedBox(
      width: tamanho,
      height: tamanho,
      child: CustomPaint(
        painter: v.copo ? _CopoPainter(v.cor) : _SacolePainter(v.cor, v.tipo),
      ),
    );

    Widget foto(String ext, Widget alternativa) => ClipRRect(
          borderRadius: BorderRadius.circular(tamanho * 0.22),
          child: Image.asset(
            'assets/sabores/$slug.$ext',
            width: tamanho,
            height: tamanho,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => alternativa,
          ),
        );

    return Opacity(
      opacity: produto.estoque == 0 ? 0.35 : 1,
      child: SizedBox(
        width: tamanho,
        height: tamanho,
        child: foto('png', foto('jpg', desenho)),
      ),
    );
  }
}

/// Geladinho gourmet: saquinho transparente amarrado, recheio cremoso e pedaços do sabor.
class _SacolePainter extends CustomPainter {
  final Color cor;
  final String tipo;
  _SacolePainter(this.cor, this.tipo);

  static const _pts = [
    Offset(.36, .52),
    Offset(.60, .50),
    Offset(.47, .62),
    Offset(.66, .68),
    Offset(.35, .73),
    Offset(.55, .79),
    Offset(.68, .84),
    Offset(.42, .86),
    Offset(.48, .46),
    Offset(.30, .62),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height, cx = w / 2;

    // sombra no chão
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, h * 0.955), width: w * 0.62, height: h * 0.06),
      Paint()
        ..color = Colors.black.withAlpha(34)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // formato do saquinho (pescoço apertado, ombros, base reta)
    final saco = Path()
      ..moveTo(w * 0.435, h * 0.21)
      ..lineTo(w * 0.425, h * 0.28)
      ..cubicTo(w * 0.425, h * 0.37, w * 0.20, h * 0.36, w * 0.20, h * 0.49)
      ..lineTo(w * 0.20, h * 0.85)
      ..quadraticBezierTo(w * 0.20, h * 0.94, w * 0.29, h * 0.94)
      ..lineTo(w * 0.71, h * 0.94)
      ..quadraticBezierTo(w * 0.80, h * 0.94, w * 0.80, h * 0.85)
      ..lineTo(w * 0.80, h * 0.49)
      ..cubicTo(w * 0.80, h * 0.36, w * 0.575, h * 0.37, w * 0.575, h * 0.28)
      ..lineTo(w * 0.565, h * 0.21)
      ..close();

    // plástico
    canvas.drawPath(saco, Paint()..color = Colors.white.withAlpha(70));

    canvas.save();
    canvas.clipPath(saco);

    // recheio
    final conteudo = Rect.fromLTWH(0, h * 0.36, w, h * 0.62);
    canvas.drawRect(
      conteudo,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [clarear(cor, 0.10), cor, escurecer(cor, 0.10)],
        ).createShader(conteudo),
    );
    // volume nas laterais
    canvas.drawRect(
      conteudo,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.black.withAlpha(38),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withAlpha(34)
          ],
          stops: const [0, 0.22, 0.7, 1],
        ).createShader(Rect.fromLTWH(w * 0.2, 0, w * 0.6, h)),
    );
    // faixa cremosa mais clara
    final onda = Path()
      ..moveTo(w * 0.12, h * 0.43)
      ..quadraticBezierTo(w * 0.26, h * 0.37, w * 0.40, h * 0.42)
      ..quadraticBezierTo(w * 0.54, h * 0.47, w * 0.68, h * 0.41)
      ..quadraticBezierTo(w * 0.78, h * 0.37, w * 0.90, h * 0.43);
    canvas.drawPath(
      onda,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * 0.075
        ..strokeCap = StrokeCap.round
        ..color = clarear(cor, 0.2).withAlpha(210),
    );

    _detalhes(canvas, w, h);

    // gelinho / cristais
    final cristal = Paint()..color = Colors.white.withAlpha(70);
    for (var i = 1; i < _pts.length; i += 2) {
      canvas.drawCircle(
          Offset(w * (_pts[i].dx + 0.05), h * (_pts[i].dy - 0.03)),
          w * 0.012,
          cristal);
    }
    canvas.restore();

    // brilho do plástico
    final brilho = Paint()..color = Colors.white.withAlpha(110);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.245, h * 0.50, w * 0.035, h * 0.34),
          Radius.circular(w * 0.02)),
      brilho,
    );
    canvas.drawCircle(Offset(w * 0.2625, h * 0.45), w * 0.018, brilho);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.745, h * 0.52, w * 0.018, h * 0.28),
          Radius.circular(w * 0.01)),
      Paint()..color = Colors.white.withAlpha(60),
    );

    // contorno
    canvas.drawPath(
      saco,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = Colors.black.withAlpha(46),
    );
    canvas.drawPath(
      saco,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withAlpha(170),
    );

    // dobrinhas do plástico no pescoço
    final vinco = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = Colors.black.withAlpha(36);
    canvas.drawLine(
        Offset(w * 0.455, h * 0.225), Offset(w * 0.445, h * 0.275), vinco);
    canvas.drawLine(
        Offset(w * 0.50, h * 0.225), Offset(w * 0.50, h * 0.28), vinco);
    canvas.drawLine(
        Offset(w * 0.545, h * 0.225), Offset(w * 0.555, h * 0.275), vinco);

    // pontas de plástico acima do nó
    final pontaE = Path()
      ..moveTo(cx - w * 0.02, h * 0.18)
      ..quadraticBezierTo(cx - w * 0.14, h * 0.10, cx - w * 0.10, h * 0.03)
      ..quadraticBezierTo(cx - w * 0.05, h * 0.09, cx + w * 0.01, h * 0.17)
      ..close();
    final pontaD = Path()
      ..moveTo(cx + w * 0.02, h * 0.18)
      ..quadraticBezierTo(cx + w * 0.14, h * 0.10, cx + w * 0.10, h * 0.03)
      ..quadraticBezierTo(cx + w * 0.05, h * 0.09, cx - w * 0.01, h * 0.17)
      ..close();
    for (final p in [pontaE, pontaD]) {
      canvas.drawPath(p, Paint()..color = Colors.white.withAlpha(170));
      canvas.drawPath(
        p,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = Colors.black.withAlpha(60),
      );
    }

    // nó
    final no = Rect.fromCenter(
        center: Offset(cx, h * 0.205), width: w * 0.17, height: h * 0.075);
    canvas.drawOval(no, Paint()..color = Colors.white.withAlpha(225));
    canvas.drawOval(
      no,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = Colors.black.withAlpha(64),
    );
  }

  void _detalhes(Canvas c, double w, double h) {
    switch (tipo) {
      case 'morango':
        for (var i = 0; i < _pts.length; i += 2) {
          final p = Offset(_pts[i].dx * w, _pts[i].dy * h);
          c.drawCircle(p, w * 0.055, Paint()..color = escurecer(cor, 0.12));
          c.drawCircle(p.translate(-w * 0.015, -w * 0.015), w * 0.016,
              Paint()..color = Colors.white.withAlpha(120));
        }
      case 'maracuja':
        final s = Paint()..color = const Color(0xFF2B2118);
        for (final o in _pts) {
          c.save();
          c.translate(o.dx * w, o.dy * h);
          c.rotate(o.dx * 6);
          c.drawOval(
              Rect.fromCenter(
                  center: Offset.zero, width: w * 0.035, height: w * 0.06),
              s);
          c.restore();
        }
      case 'chocolate':
        final s = Paint()..color = const Color(0xFF3A2013);
        for (final o in _pts) {
          c.save();
          c.translate(o.dx * w, o.dy * h);
          c.rotate(o.dy * 5);
          c.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromCenter(
                    center: Offset.zero, width: w * 0.07, height: w * 0.04),
                Radius.circular(w * 0.01)),
            s,
          );
          c.restore();
        }
      case 'coco':
        final s = Paint()..color = Colors.white.withAlpha(235);
        for (final o in _pts) {
          c.save();
          c.translate(o.dx * w, o.dy * h);
          c.rotate(o.dx * 8);
          c.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromCenter(
                    center: Offset.zero, width: w * 0.06, height: w * 0.022),
                Radius.circular(w * 0.01)),
            s,
          );
          c.restore();
        }
      case 'uva':
        for (final o in _pts) {
          c.drawCircle(Offset(o.dx * w, o.dy * h), w * 0.03,
              Paint()..color = clarear(cor, 0.2).withAlpha(150));
        }
      case 'manga':
        final veio = Path()
          ..moveTo(w * 0.34, h * 0.55)
          ..quadraticBezierTo(w * 0.50, h * 0.60, w * 0.45, h * 0.72)
          ..quadraticBezierTo(w * 0.40, h * 0.82, w * 0.62, h * 0.86);
        c.drawPath(
          veio,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = w * 0.045
            ..strokeCap = StrokeCap.round
            ..color = clarear(cor, 0.18).withAlpha(140),
        );
      case 'limao':
        for (final o in _pts) {
          c.drawCircle(Offset(o.dx * w, o.dy * h), w * 0.014,
              Paint()..color = escurecer(cor, 0.22));
        }
      default:
        for (final o in _pts) {
          c.drawCircle(Offset(o.dx * w, o.dy * h), w * 0.018,
              Paint()..color = Colors.white.withAlpha(90));
        }
    }
  }

  @override
  bool shouldRepaint(covariant _SacolePainter old) =>
      old.cor != cor || old.tipo != tipo;
}

class _CopoPainter extends CustomPainter {
  final Color cor;
  _CopoPainter(this.cor);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final rimY = h * 0.38, botY = h * 0.93;
    final topL = w * 0.14, topR = w * 0.86, botL = w * 0.28, botR = w * 0.72;

    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w / 2, h * 0.95), width: w * 0.55, height: h * 0.07),
      Paint()
        ..color = Colors.black.withAlpha(30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // salgadinhos saindo do copo
    const tons = [
      Color(0xFFFFC857),
      Color(0xFFF4A259),
      Color(0xFFE88A12),
      Color(0xFFFFD98A)
    ];
    for (var i = 0; i < 18; i++) {
      final fx = ((i * 37) % 100) / 100;
      final pico = 1 - (fx - 0.5).abs() * 1.6;
      final alt = 0.04 + 0.16 * pico * (((i * 53) % 100) / 100 * 0.6 + 0.4);
      final p = Offset(w * (0.2 + 0.6 * fx), rimY - h * alt);
      canvas.drawCircle(p, w * 0.06, Paint()..color = tons[i % tons.length]);
      canvas.drawCircle(p.translate(-w * 0.015, -w * 0.015), w * 0.018,
          Paint()..color = Colors.white.withAlpha(90));
    }

    final copo = Path()
      ..moveTo(topL, rimY)
      ..lineTo(topR, rimY)
      ..lineTo(botR, botY - h * 0.04)
      ..quadraticBezierTo(botR - w * 0.02, botY, botR - w * 0.06, botY)
      ..lineTo(botL + w * 0.06, botY)
      ..quadraticBezierTo(botL + w * 0.02, botY, botL, botY - h * 0.04)
      ..close();

    canvas.drawPath(
      copo,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [clarear(cor, 0.14), cor, escurecer(cor, 0.12)],
        ).createShader(Offset.zero & size),
    );

    canvas.save();
    canvas.clipPath(copo);
    canvas.drawRect(Rect.fromLTWH(0, rimY, w, h * 0.06),
        Paint()..color = Colors.white.withAlpha(60));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.27, h * 0.52, w * 0.07, h * 0.30),
          Radius.circular(w * 0.035)),
      Paint()..color = Colors.white.withAlpha(90),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CopoPainter old) => old.cor != cor;
}
