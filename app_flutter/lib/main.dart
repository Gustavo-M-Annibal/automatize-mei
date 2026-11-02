import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/estado.dart';
import 'widgets/componentes.dart';
//import 'screens/abertura.dart';
import 'screens/telaLogin.dart';

void main() => runApp(const AutomatizeApp());

class AutomatizeApp extends StatefulWidget {
  const AutomatizeApp({super.key});

  @override
  State<AutomatizeApp> createState() => _AutomatizeAppState();
}

class _AutomatizeAppState extends State<AutomatizeApp> {
  final estado = Estado();

  @override
  void initState() {
    super.initState();
    estado.iniciar();
  }

  @override
  Widget build(BuildContext context) {
    final esquema = ColorScheme.fromSeed(seedColor: Cores.tinta, brightness: Brightness.light)
        .copyWith(surface: Cores.fundo, primary: Cores.tinta);
    final base = ThemeData(useMaterial3: true, colorScheme: esquema);
    
    return Escopo(
      estado: estado,
      child: MaterialApp(
        title: 'Geladinhos',
        debugShowCheckedModeBanner: false,
        theme: base.copyWith(
          scaffoldBackgroundColor: Cores.fundo,
          splashFactory: InkSparkle.splashFactory,
          textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme)
              .apply(bodyColor: Cores.tinta, displayColor: Cores.tinta),
          snackBarTheme: SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          ),
        ),
        // Alterado de Abertura() para TelaLogin() para ser a primeira tela do app
        home: const LoginPage(),
      ),
    );
  }
}