import 'package:flutter/material.dart';
import 'componentes.dart';

const List<int> valoresDinheiro = [5, 10, 25, 50, 100, 200, 500, 1000, 2000, 5000, 10000];

int somaCentavos(Map<int, int> m) => m.entries.fold(0, (a, e) => a + e.key * e.value);

/// Quebra um valor em cédulas e moedas (para mostrar o que já está contado).
Map<int, int> decompor(int centavos) {
  final r = <int, int>{};
  var resto = centavos;
  for (final v in valoresDinheiro.reversed) {
    final n = resto ~/ v;
    if (n > 0) {
      r[v] = n;
      resto -= n * v;
    }
  }
  return r;
}

const _cores = {
  5: Color(0xFFB07A44),
  10: Color(0xFFB98650),
  25: Color(0xFFA2693A),
  50: Color(0xFF9AA5AD),
  100: Color(0xFFD1A62B),
  200: Color(0xFF7C97B0),
  500: Color(0xFF8A62C4),
  1000: Color(0xFFE5484D),
  2000: Color(0xFFE5B400),
  5000: Color(0xFFEE8A1B),
  10000: Color(0xFF2F7FD0),
};

String _rotulo(int c) => c >= 100 ? '${c ~/ 100}' : '0,${c.toString().padLeft(2, '0')}';

/// Cédulas e moedas para tocar: serve para contar a gaveta, o troco e o valor de um gasto.
class GradeDinheiro extends StatelessWidget {
  final Map<int, int> contagem;
  final void Function(int centavos, int delta) onMudar;
  const GradeDinheiro({super.key, required this.contagem, required this.onMudar});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.88,
      children: [
        for (final v in valoresDinheiro)
          _Ficha(
            centavos: v,
            n: contagem[v] ?? 0,
            onMais: () => onMudar(v, 1),
            onMenos: () => onMudar(v, -1),
          ),
      ],
    );
  }
}

class _Ficha extends StatelessWidget {
  final int centavos;
  final int n;
  final VoidCallback onMais;
  final VoidCallback onMenos;
  const _Ficha({required this.centavos, required this.n, required this.onMais, required this.onMenos});

  @override
  Widget build(BuildContext context) {
    final cor = _cores[centavos]!;
    final nota = centavos >= 200;
    final grad = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [clarear(cor, 0.12), escurecer(cor, 0.08)],
    );
    final rotulo = Text(_rotulo(centavos),
        style: TextStyle(
            fontSize: nota ? 22 : 16, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5));

    final forma = nota
        ? Container(
            width: 84,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(gradient: grad, borderRadius: BorderRadius.circular(10)),
            child: Container(
              margin: const EdgeInsets.all(4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: Colors.white.withAlpha(110), width: 1.5),
              ),
              child: rotulo,
            ),
          )
        : Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: grad,
              boxShadow: [BoxShadow(color: cor.withAlpha(70), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withAlpha(110), width: 1.5),
              ),
              child: rotulo,
            ),
          );

    return Material(
      color: Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
        side: BorderSide(color: n > 0 ? Cores.tinta : Cores.linha, width: n > 0 ? 2 : 1.5),
      ),
      child: InkWell(
        customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        onTap: onMais,
        child: Stack(children: [
          Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              forma,
              const SizedBox(height: 10),
              Text(n == 0 ? '–' : '$n',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                      color: n == 0 ? Cores.linha : Cores.tinta)),
            ]),
          ),
          if (n > 0)
            Positioned(
              top: 6,
              right: 6,
              child: BotaoRedondo(icone: Icons.remove_rounded, onTap: onMenos, tamanho: 30),
            ),
        ]),
      ),
    );
  }
}