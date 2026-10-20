import 'package:flutter/material.dart';
import '../componentes.dart';
import '../estado.dart';
import 'inicio.dart';

class Abertura extends StatefulWidget {
  const Abertura({super.key});
  @override
  State<Abertura> createState() => _AberturaState();
}

class _AberturaState extends State<Abertura> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final s = Escopo.de(context);
      await Future.delayed(const Duration(milliseconds: 1800));
      while (s.carregando && mounted) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => const AppShell(),
        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (_, v, child) => Opacity(
            opacity: v,
            child: Transform.translate(offset: Offset(0, 14 * (1 - v)), child: child),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Image.asset('assets/logo/automatize.png', width: 300),
          ),
        ),
      ),
    );
  }
}