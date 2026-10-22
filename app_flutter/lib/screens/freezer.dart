import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'arte.dart';
import '../widgets/componentes.dart';
import '../widgets/estado.dart';
import '../widgets/modelos.dart';

class FreezerPage extends StatelessWidget {
  const FreezerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = Escopo.de(context);
    final total = s.produtos.fold(0, (a, p) => a + p.estoque);
    return ListView(
      padding: paginaPad(context),
      children: [
        Titulo(
          'Freezer',
          fim: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: cartao(raio: 22),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.ac_unit_rounded, size: 18, color: Cores.suave),
                const SizedBox(width: 6),
                Text('$total',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
              ]),
            ),
            const SizedBox(width: 10),
            BotaoRedondo(
              icone: Icons.add_rounded,
              cor: Cores.tinta,
              corIcone: Colors.white,
              tamanho: 46,
              onTap: () => abrirFormProduto(context),
            ),
          ]),
        ),
        if (s.produtos.isEmpty)
          EstadoVazio(
            icone: Icons.ac_unit_rounded,
            titulo: 'Nenhum sabor ainda',
            texto: 'Toque no + para cadastrar o primeiro geladinho.',
            botao: 'Cadastrar sabor',
            onBotao: () => abrirFormProduto(context),
          )
        else
          for (final p in s.produtos) _LinhaEstoque(produto: p),
      ],
    );
  }
}

class _LinhaEstoque extends StatelessWidget {
  final Produto produto;
  const _LinhaEstoque({required this.produto});

  @override
  Widget build(BuildContext context) {
    final v = produto.visual;
    final baixo = produto.estoque <= 5;
    return Toque(
      onTap: () => abrirProduto(context, produto),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
        decoration: cartao(raio: 30),
        child: Row(children: [
          Container(
            width: 88,
            height: 88,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: RadialGradient(
                  colors: [v.cor.withAlpha(50), v.cor.withAlpha(8)]),
            ),
            child: Arte(produto, tamanho: 72),
          ),
          const SizedBox(width: 14),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(
                  child: Text(produto.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3)),
                ),
                if (baixo) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: Cores.alerta.withAlpha(40),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.priority_high_rounded,
                        size: 16, color: Cores.alertaEscuro),
                  ),
                ],
              ]),
              Text(brl(produto.preco),
                  style: const TextStyle(
                      fontSize: 13,
                      color: Cores.suave,
                      fontWeight: FontWeight.w600)),
              Text('${produto.estoque}',
                  style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.2,
                      height: 1.1)),
              const SizedBox(height: 6),
              BarraEstoque(produto),
            ]),
          ),
          const SizedBox(width: 14),
          BotaoRedondo(
            icone: Icons.add_rounded,
            cor: Cores.tinta,
            corIcone: Colors.white,
            tamanho: 50,
            onTap: () => abrirEstoque(context, produto, entrada: true),
          ),
        ]),
      ),
    );
  }
}

// ------------------------------------------------------------------ janelas

void abrirProduto(BuildContext pai, Produto p) {
  mostrarFolha<void>(pai, (_) => _OpcoesProduto(produto: p, pai: pai));
}

void abrirEstoque(BuildContext pai, Produto p, {required bool entrada}) {
  mostrarFolha<void>(
      pai, (_) => _FolhaEstoque(produto: p, entrada: entrada, pai: pai));
}

Future<void> abrirFormProduto(BuildContext pai, [Produto? p]) =>
    mostrarFolha<void>(pai, (_) => _FormProduto(produto: p, pai: pai));

class _OpcoesProduto extends StatelessWidget {
  final Produto produto;
  final BuildContext pai;
  const _OpcoesProduto({required this.produto, required this.pai});

  void _ir(BuildContext context, VoidCallback acao) {
    Navigator.of(context).pop();
    if (pai.mounted) acao();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Arte(produto, tamanho: 96),
        const SizedBox(height: 8),
        Text(produto.nome,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6)),
        const SizedBox(height: 2),
        Text('${brl(produto.preco)} · ${produto.estoque} no freezer',
            style: const TextStyle(
                fontSize: 15, color: Cores.suave, fontWeight: FontWeight.w600)),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(
            child: _Opcao(
                Icons.add_circle_rounded,
                'Produzi',
                Cores.ok,
                () => _ir(
                    context, () => abrirEstoque(pai, produto, entrada: true))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _Opcao(
                Icons.remove_circle_rounded,
                'Perdi',
                Cores.alerta,
                () => _ir(
                    context, () => abrirEstoque(pai, produto, entrada: false))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _Opcao(Icons.edit_rounded, 'Editar', Cores.tinta,
                () => _ir(context, () => abrirFormProduto(pai, produto))),
          ),
        ]),
      ]),
    );
  }
}

class _Opcao extends StatelessWidget {
  final IconData icone;
  final String rotulo;
  final Color cor;
  final VoidCallback onTap;
  const _Opcao(this.icone, this.rotulo, this.cor, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cor.withAlpha(24),
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(children: [
            Icon(icone, size: 38, color: cor),
            const SizedBox(height: 8),
            Text(rotulo,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ]),
        ),
      ),
    );
  }
}

/// Entrada (produzi) ou saída (perdi) de estoque.
class _FolhaEstoque extends StatefulWidget {
  final Produto produto;
  final bool entrada;
  final BuildContext pai;
  const _FolhaEstoque(
      {required this.produto, required this.entrada, required this.pai});
  @override
  State<_FolhaEstoque> createState() => _FolhaEstoqueState();
}

class _FolhaEstoqueState extends State<_FolhaEstoque> {
  int qtd = 0;
  bool enviando = false;
  String? erro;

  int get maximo => widget.entrada ? 9999 : widget.produto.estoque;

  Future<void> _salvar() async {
    final s = Escopo.de(context);
    final pai = widget.pai;
    final texto = widget.entrada ? '+$qtd' : '−$qtd';
    setState(() {
      enviando = true;
      erro = null;
    });
    try {
      if (widget.entrada) {
        await s.produzir(widget.produto, qtd);
      } else {
        await s.perder(widget.produto, qtd);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      await mostrarSucesso(pai, texto);
    } catch (e) {
      if (mounted) {
        setState(() {
          enviando = false;
          erro = msgErro(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.produto.visual;
    final atalhos = widget.entrada ? [5, 10, 20] : [1, 5, 10];
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          24, 0, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 140,
          height: 140,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
                colors: [v.cor.withAlpha(60), v.cor.withAlpha(0)]),
          ),
          child: Arte(widget.produto, tamanho: 112),
        ),
        const SizedBox(height: 8),
        Text(widget.entrada ? 'Quantos fiz?' : 'Quantos perdi?',
            style: const TextStyle(
                fontSize: 18, color: Cores.suave, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        Contador(
          grande: true,
          valor: qtd,
          onMenos: qtd > 0 ? () => setState(() => qtd--) : null,
          onMais: qtd < maximo ? () => setState(() => qtd++) : null,
        ),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (final n in atalhos)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: ActionChip(
                label: Text('+$n',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                backgroundColor: Cores.fundo,
                side: BorderSide.none,
                shape: const StadiumBorder(),
                onPressed: () =>
                    setState(() => qtd = math.min(qtd + n, maximo)),
              ),
            ),
        ]),
        const SizedBox(height: 20),
        if (erro != null) ErroInline(erro!),
        SizedBox(
          width: double.infinity,
          child: BotaoAcao(
            icone: widget.entrada
                ? Icons.ac_unit_rounded
                : Icons.delete_outline_rounded,
            texto: widget.entrada ? 'Guardar no freezer' : 'Tirar do freezer',
            cor: widget.entrada ? Cores.ok : Cores.erro,
            onTap: qtd == 0 || enviando ? null : _salvar,
          ),
        ),
      ]),
    );
  }
}

/// Cadastrar ou editar um sabor.
class _FormProduto extends StatefulWidget {
  final Produto? produto;
  final BuildContext pai;
  const _FormProduto({required this.produto, required this.pai});
  @override
  State<_FormProduto> createState() => _FormProdutoState();
}

class _FormProdutoState extends State<_FormProduto> {
  late final TextEditingController nome =
      TextEditingController(text: widget.produto?.nome ?? '');
  late double preco = widget.produto?.preco ?? 3.0;
  int estoque = 0;
  bool salvando = false;
  String? erro;

  bool get editando => widget.produto != null;

  void _preco(double delta) {
    setState(() {
      preco = math.max(0.10, ((preco + delta) * 100).round() / 100);
      erro = null;
    });
  }

  Future<void> _salvar() async {
    final s = Escopo.de(context);
    final pai = widget.pai;
    final n = nome.text.trim();
    if (n.isEmpty) {
      setState(() => erro = 'Dê um nome ao sabor.');
      return;
    }
    setState(() {
      salvando = true;
      erro = null;
    });
    try {
      if (editando) {
        await s.atualizarProduto(widget.produto!, n, preco);
      } else {
        await s.criarProduto(n, preco, estoque);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      await mostrarSucesso(pai, 'Salvo');
    } catch (e) {
      if (mounted) {
        setState(() {
          salvando = false;
          erro = msgErro(e);
        });
      }
    }
  }

  Future<void> _excluir() async {
    final s = Escopo.de(context);
    final pai = widget.pai;
    final ok = await confirmar(
      context,
      titulo: 'Excluir ${widget.produto!.nome}?',
      texto:
          'O sabor sai da lista. As vendas já feitas continuam no histórico.',
      sim: 'Excluir',
      perigo: true,
    );
    if (!ok || !mounted) return;
    setState(() => salvando = true);
    try {
      await s.excluirProduto(widget.produto!);
      if (!mounted) return;
      Navigator.of(context).pop();
      await mostrarSucesso(pai, 'Excluído');
    } catch (e) {
      if (mounted) {
        setState(() {
          salvando = false;
          erro = msgErro(e);
        });
      }
    }
  }

  @override
  void dispose() {
    nome.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          24, 0, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(editando ? 'Editar sabor' : 'Novo sabor',
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.7)),
        const SizedBox(height: 18),
        TextField(
          controller: nome,
          autofocus: !editando,
          maxLength: 30,
          textCapitalization: TextCapitalization.sentences,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          onChanged: (_) => setState(() => erro = null),
          decoration: InputDecoration(
            labelText: 'Nome do sabor',
            counterText: '',
            filled: true,
            fillColor: Cores.fundo,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 18),
        const Text('Preço',
            style: TextStyle(
                fontSize: 15, color: Cores.suave, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
              color: Cores.fundo, borderRadius: BorderRadius.circular(40)),
          child: Row(children: [
            BotaoRedondo(
                icone: Icons.remove_rounded,
                onTap: () => _preco(-0.5),
                cor: Colors.white,
                tamanho: 52),
            Expanded(
              child: Center(
                child: Text(brl(preco),
                    style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1)),
              ),
            ),
            BotaoRedondo(
                icone: Icons.add_rounded,
                onTap: () => _preco(0.5),
                cor: Cores.tinta,
                corIcone: Colors.white,
                tamanho: 52),
          ]),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (final d in [-0.10, 0.10])
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: ActionChip(
                label: Text(d < 0 ? '−0,10' : '+0,10',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                backgroundColor: Cores.fundo,
                side: BorderSide.none,
                shape: const StadiumBorder(),
                onPressed: () => _preco(d),
              ),
            ),
        ]),
        if (!editando) ...[
          const SizedBox(height: 14),
          const Text('Quantos tem no freezer agora?',
              style: TextStyle(
                  fontSize: 15,
                  color: Cores.suave,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Contador(
            grande: true,
            valor: estoque,
            onMenos: estoque > 0 ? () => setState(() => estoque--) : null,
            onMais: () => setState(() => estoque++),
          ),
        ],
        const SizedBox(height: 20),
        if (erro != null) ErroInline(erro!),
        SizedBox(
          width: double.infinity,
          child: BotaoAcao(
            icone: Icons.check_rounded,
            texto: 'Salvar',
            cor: Cores.ok,
            onTap: salvando ? null : _salvar,
          ),
        ),
        if (editando)
          Center(
            child: TextButton.icon(
              onPressed: salvando ? null : _excluir,
              icon: const Icon(Icons.delete_outline_rounded, color: Cores.erro),
              label: const Text('Excluir sabor',
                  style: TextStyle(
                      color: Cores.erro, fontWeight: FontWeight.w700)),
            ),
          ),
      ]),
    );
  }
}
