import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/botao_grande.dart';
import '../widgets/campo_icone.dart';
import 'home_screen.dart';

/// Tela de login: ícones grandes, cores vivas e o mínimo possível de texto.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usuarioCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _auth = AuthService();

  bool _senhaOculta = true;
  bool _carregando = false;
  String? _erro;

  @override
  void dispose() { 
    _usuarioCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final token = await _auth.login(
        usuario: _usuarioCtrl.text.trim(),
        senha: _senhaCtrl.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomeScreen(token: token)),
      );
    } on AuthException catch (e) {
      if (mounted) setState(() => _erro = e.mensagem);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.rosaClaro, AppColors.fundo],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _cabecalho(),
                      const SizedBox(height: 36),
                      CampoIcone(
                        controller: _usuarioCtrl,
                        icone: Icons.person,
                        dica: 'Usuário',
                        validador: (v) => (v == null || v.trim().isEmpty)
                            ? 'Escreva seu usuário'
                            : null,
                      ),
                      const SizedBox(height: 20),
                      CampoIcone(
                        controller: _senhaCtrl,
                        icone: Icons.lock,
                        dica: 'Senha',
                        senha: true,
                        oculto: _senhaOculta,
                        aoAlternarVisibilidade: () =>
                            setState(() => _senhaOculta = !_senhaOculta),
                        acao: TextInputAction.done,
                        aoEnviar: (_) => _entrar(),
                        validador: (v) => (v == null || v.isEmpty)
                            ? 'Escreva sua senha'
                            : null,
                      ),
                      if (_erro != null) ...[
                        const SizedBox(height: 20),
                        _caixaErro(_erro!),
                      ],
                      const SizedBox(height: 32),
                      Semantics(
                        button: true,
                        label: 'Entrar no aplicativo',
                        child: BotaoGrande(
                          icone: Icons.check_circle,
                          texto: 'Entrar',
                          carregando: _carregando,
                          aoPressionar: _entrar,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _cabecalho() {
    return Column(
      children: [
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.rosa, width: 4),
            boxShadow: [
              BoxShadow(
                color: AppColors.rosa.withAlpha(70),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.icecream, size: 84, color: AppColors.rosa),
        ),
        const SizedBox(height: 16),
        const Text(
          'Automatize MEI',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: AppColors.roxo,
          ),
        ),
      ],
    );
  }

  Widget _caixaErro(String mensagem) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.vermelho, width: 2),
        ),
        child: Row(
          children: [
            const Icon(Icons.error, color: AppColors.vermelho, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                mensagem,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.vermelho,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
