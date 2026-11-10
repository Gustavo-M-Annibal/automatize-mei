import 'package:flutter/material.dart';
import '../widgets/api.dart';
import '../widgets/estado.dart';

class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  bool _mostrarSenha = false;
  bool _mostrarConfirmacao = false;
  bool _aceitouTermos = false;
  bool _erroTermos = false;
  bool _cadastrando = false;

  static const _marinho = Color(0xFF112B46);
  static const _verde = Color(0xFF167C62);
  static const _fundo = Color(0xFFF6F7F4);
  static const _textoSuave = Color(0xFF78838B);
  static const _erro = Color(0xFFCF5555);

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
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

  void _voltarParaLogin() => Navigator.of(context).pop();

  Future<void> _cadastrar() async {
    final formularioValido = _formKey.currentState!.validate();
    setState(() => _erroTermos = !_aceitouTermos);

    if (!formularioValido || !_aceitouTermos || _cadastrando) return;

    setState(() => _cadastrando = true);
    final email = _emailController.text.trim().toLowerCase();
    try {
      await Escopo.de(context).cadastrarUsuario(
        nome: _nomeController.text,
        email: email,
        senha: _senhaController.text,
      );
      if (mounted) Navigator.of(context).pop(email);
    } catch (erro) {
      if (mounted) {
        _mostrarAviso(
          erro is ApiErro
              ? erro.mensagem
              : 'Não foi possível criar a conta. Tente novamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _cadastrando = false);
    }
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
        Row(
          children: [
            Expanded(
              child: Image.asset(
                'assets/logo/automatize.png',
                width: largo ? 218 : 190,
                height: 54,
                alignment: Alignment.centerLeft,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'automatize',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: _marinho,
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Voltar para o login',
              onPressed: _voltarParaLogin,
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: _marinho,
                size: 24,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        const Text(
          'Crie sua conta',
          style: TextStyle(
            color: _marinho,
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.1,
          ),
        ),
        const SizedBox(height: 9),
        const Text(
          'Leva menos de um minuto para começar a organizar seu negócio.',
          style: TextStyle(color: _textoSuave, fontSize: 15, height: 1.5),
        ),
        const SizedBox(height: 30),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _LegendaCampo('Nome completo'),
              const SizedBox(height: 9),
              TextFormField(
                controller: _nomeController,
                keyboardType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                decoration: _decoracao(
                  dica: 'Como podemos te chamar?',
                  icone: Icons.person_outline_rounded,
                ),
                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return 'Informe seu nome.';
                  }
                  if (valor.trim().length < 3) {
                    return 'O nome precisa ter ao menos 3 caracteres.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
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
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                decoration: _decoracao(
                  dica: 'Mínimo de 8 caracteres',
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
                validator: (valor) {
                  if (valor == null || valor.isEmpty) {
                    return 'Crie uma senha.';
                  }
                  if (valor.length < 8) {
                    return 'A senha precisa ter ao menos 8 caracteres.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const _LegendaCampo('Confirmar senha'),
              const SizedBox(height: 9),
              TextFormField(
                controller: _confirmarSenhaController,
                obscureText: !_mostrarConfirmacao,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                onFieldSubmitted: (_) => _cadastrar(),
                decoration: _decoracao(
                  dica: 'Repita a senha',
                  icone: Icons.lock_outline_rounded,
                  sufixo: IconButton(
                    tooltip: _mostrarConfirmacao
                        ? 'Ocultar senha'
                        : 'Mostrar senha',
                    onPressed: () => setState(
                      () => _mostrarConfirmacao = !_mostrarConfirmacao,
                    ),
                    icon: Icon(
                      _mostrarConfirmacao
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: _textoSuave,
                      size: 21,
                    ),
                  ),
                ),
                validator: (valor) {
                  if (valor == null || valor.isEmpty) {
                    return 'Confirme sua senha.';
                  }
                  if (valor != _senhaController.text) {
                    return 'As senhas não conferem.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: Checkbox(
                      value: _aceitouTermos,
                      activeColor: _verde,
                      side: BorderSide(
                        color: _erroTermos ? _erro : _textoSuave,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      onChanged: (valor) => setState(() {
                        _aceitouTermos = valor ?? false;
                        if (_aceitouTermos) _erroTermos = false;
                      }),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Li e aceito os Termos de Uso e a Política de Privacidade.',
                        style: TextStyle(
                          color: _erroTermos ? _erro : _textoSuave,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_erroTermos)
                const Padding(
                  padding: EdgeInsets.only(top: 6, left: 32),
                  child: Text(
                    'Aceite os termos para continuar.',
                    style: TextStyle(color: _erro, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 24),
              SizedBox(
                height: 54,
                child: FilledButton(
                  onPressed: _cadastrando ? null : _cadastrar,
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _cadastrando
                        ? [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 10),
                            Text('Criando conta...'),
                          ]
                        : [
                            Text('Criar minha conta'),
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
                      'Já tem uma conta?',
                      style: TextStyle(color: _textoSuave, fontSize: 13),
                    ),
                  ),
                  Expanded(child: Divider(color: Color(0xFFE5E9E6))),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _voltarParaLogin,
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
                child: const Text('Entrar na minha conta'),
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
        borderSide: const BorderSide(color: _erro),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _erro, width: 1.5),
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
        color: _CadastroPageState._marinho,
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
                  'Comece agora.\nSeu negócio\nvai agradecer.',
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
                  'Crie sua conta e organize vendas, estoque e caixa em um só lugar.',
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
              Icons.rocket_launch_rounded,
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
                  'Cadastro rápido e simples',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Poucos campos, sem burocracia',
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