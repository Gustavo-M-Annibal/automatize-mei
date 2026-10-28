import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _mostrarSenha = false;
  bool _lembrarAcesso = true;

  static const _marinho = Color(0xFF112B46);
  static const _verde = Color(0xFF167C62);
  static const _fundo = Color(0xFFF6F7F4);
  static const _textoSuave = Color(0xFF78838B);

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  void _mostrarAviso(String mensagem) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mensagem),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _marinho,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  void _entrar() {
    if (!_formKey.currentState!.validate()) return;
    _mostrarAviso('Protótipo visual: o acesso ainda não está conectado.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fundo,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 900) {
              return Row(
                children: [
                  const Expanded(flex: 11, child: _PainelBoasVindas()),
                  Expanded(
                    flex: 10,
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 36,
                        ),
                        child: _formulario(largo: true),
                      ),
                    ),
                  ),
                ],
              );
            }

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                24,
                constraints.maxHeight < 700 ? 20 : 36,
                24,
                28,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: _formulario(largo: false),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _formulario({required bool largo}) {
    final conteudo = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Image.asset(
          'assets/logo/automatize.png',
          width: largo ? 218 : 190,
          height: 54,
          alignment: Alignment.centerLeft,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Text(
            'automatize',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: _marinho,
            ),
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Bem-vinda de volta!',
          style: TextStyle(
            color: _marinho,
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.1,
          ),
        ),
        const SizedBox(height: 9),
        const Text(
          'Entre para cuidar do seu negócio com tranquilidade.',
          style: TextStyle(color: _textoSuave, fontSize: 15, height: 1.5),
        ),
        const SizedBox(height: 30),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _LegendaCampo('E-mail'),
              const SizedBox(height: 9),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: _decoracao(
                  dica: 'voce@exemplo.com',
                  icone: Icons.mail_outline_rounded,
                ),
                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return 'Informe seu e-mail.';
                  }
                  if (!valor.contains('@')) {
                    return 'Confira o formato do e-mail.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const _LegendaCampo('Senha'),
              const SizedBox(height: 9),
              TextFormField(
                controller: _senhaController,
                obscureText: !_mostrarSenha,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onFieldSubmitted: (_) => _entrar(),
                decoration: _decoracao(
                  dica: 'Digite sua senha',
                  icone: Icons.lock_outline_rounded,
                  sufixo: IconButton(
                    tooltip: _mostrarSenha ? 'Ocultar senha' : 'Mostrar senha',
                    onPressed: () =>
                        setState(() => _mostrarSenha = !_mostrarSenha),
                    icon: Icon(
                      _mostrarSenha
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: _textoSuave,
                      size: 21,
                    ),
                  ),
                ),
                validator: (valor) => valor == null || valor.isEmpty
                    ? 'Informe sua senha.'
                    : null,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: Checkbox(
                      value: _lembrarAcesso,
                      activeColor: _verde,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      onChanged: (valor) =>
                          setState(() => _lembrarAcesso = valor ?? false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Lembrar de mim',
                      style: TextStyle(color: _textoSuave, fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _mostrarAviso(
                      'Recuperação de senha ainda não configurada.',
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: _verde,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    child: const Text(
                      'Esqueci minha senha',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 54,
                child: FilledButton(
                  onPressed: _entrar,
                  style: FilledButton.styleFrom(
                    backgroundColor: _verde,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Entrar na minha conta'),
                      SizedBox(width: 9),
                      Icon(Icons.arrow_forward_rounded, size: 19),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 25),
              const Row(
                children: [
                  Expanded(child: Divider(color: Color(0xFFE5E9E6))),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 13),
                    child: Text(
                      'É sua primeira vez?',
                      style: TextStyle(color: _textoSuave, fontSize: 13),
                    ),
                  ),
                  Expanded(child: Divider(color: Color(0xFFE5E9E6))),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => _mostrarAviso(
                  'Cadastro ainda não disponível neste protótipo.',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _marinho,
                  side: const BorderSide(color: Color(0xFFDCE3DF)),
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('Criar minha conta'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 25),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline_rounded, size: 15, color: _textoSuave),
            SizedBox(width: 7),
            Text(
              'Seus dados protegidos com segurança',
              style: TextStyle(color: _textoSuave, fontSize: 12),
            ),
          ],
        ),
      ],
    );

    if (!largo) {
      return Container(
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: const Color(0xFFE9EDE9)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0C112B46),
              blurRadius: 30,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: conteudo,
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: conteudo,
    );
  }

  InputDecoration _decoracao({
    required String dica,
    required IconData icone,
    Widget? sufixo,
  }) {
    return InputDecoration(
      hintText: dica,
      hintStyle: const TextStyle(color: Color(0xFFAAB2B4), fontSize: 14),
      prefixIcon: Icon(icone, color: _textoSuave, size: 20),
      suffixIcon: sufixo,
      filled: true,
      fillColor: const Color(0xFFFAFBF9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 17),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8E3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8E3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _verde, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFCF5555)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFCF5555), width: 1.5),
      ),
    );
  }
}

class _LegendaCampo extends StatelessWidget {
  const _LegendaCampo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(
        color: _LoginPageState._marinho,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _PainelBoasVindas extends StatelessWidget {
  const _PainelBoasVindas();

  static const _dourado = Color(0xFFFFC45B);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(14),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF102941), Color(0xFF174A54), Color(0xFF167C62)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -100,
            right: -80,
            child: _BolaDecorativa(
              diametro: 330,
              cor: Colors.white.withValues(alpha: 0.045),
            ),
          ),
          Positioned(
            bottom: -155,
            left: -100,
            child: _BolaDecorativa(
              diametro: 390,
              cor: Colors.white.withValues(alpha: 0.04),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/logo/automatize.png',
                  width: 230,
                  height: 58,
                  fit: BoxFit.contain,
                  color: Colors.white,
                  colorBlendMode: BlendMode.srcIn,
                  errorBuilder: (_, __, ___) => const Text(
                    'automatize',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const Spacer(),
                const Text(
                  'Seu negócio\nmais leve.\nSeu dia mais seu.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    height: 1.14,
                    letterSpacing: -1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Organize vendas, estoque e caixa em um só lugar — sem complicação.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 16,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 32),
                const _CartaoResumo(),
                const Spacer(),
                Row(
                  children: [
                    const Icon(
                      Icons.favorite_rounded,
                      color: _dourado,
                      size: 17,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Feito para quem faz acontecer.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CartaoResumo extends StatelessWidget {
  const _CartaoResumo();

  static const _verde = Color(0xFF167C62);
  static const _dourado = Color(0xFFFFC45B);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _dourado.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_graph_rounded,
              color: _dourado,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tudo sob controle',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Vendas, estoque e caixa',
                  style: TextStyle(color: Color(0xFFC7D8D5), fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: _verde,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 17,
            ),
          ),
        ],
      ),
    );
  }
}

class _BolaDecorativa extends StatelessWidget {
  const _BolaDecorativa({required this.diametro, required this.cor});

  final double diametro;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diametro,
      height: diametro,
      decoration: BoxDecoration(shape: BoxShape.circle, color: cor),
    );
  }
}
