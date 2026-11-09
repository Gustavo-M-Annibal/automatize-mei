import 'package:flutter/material.dart';

class Visual {
  final Color cor;
  final bool copo;
  final String tipo;
  const Visual(this.cor, {this.copo = false, this.tipo = ''});
}

const _paleta = [
  Color(0xFF2FB5D6),
  Color(0xFFF0476B),
  Color(0xFF8E5CF0),
  Color(0xFFFFA927),
  Color(0xFF3CC47C),
  Color(0xFF3F7CF0),
  Color(0xFFE4572E),
];

/// Cada sabor tem a sua cor. Nome desconhecido ganha uma cor fixa da paleta.
Visual visualDe(String nome) {
  final n = nome.toLowerCase();
  if (n.contains('morango')) return const Visual(Color(0xFFF0476B), tipo: 'morango');
  if (n.contains('manga')) return const Visual(Color(0xFFFFA927), tipo: 'manga');
  if (n.contains('uva')) return const Visual(Color(0xFF8E5CF0), tipo: 'uva');
  if (n.contains('lim')) return const Visual(Color(0xFF9BD62E), tipo: 'limao');
  if (n.contains('coco')) return const Visual(Color(0xFFEFE6D8), tipo: 'coco');
  if (n.contains('choc') || n.contains('brigad')) return const Visual(Color(0xFF7A4B34), tipo: 'chocolate');
  if (n.contains('maracuj')) return const Visual(Color(0xFFFFC21F), tipo: 'maracuja');
  if (n.contains('salgad') || n.contains('copo')) return const Visual(Color(0xFFE4572E), copo: true);
  final h = nome.codeUnits.fold<int>(7, (a, b) => (a * 31 + b) & 0x7fffffff);
  return Visual(_paleta[h % _paleta.length]);
}

DateTime soDia(DateTime d) => DateTime(d.year, d.month, d.day);

bool mesmoDia(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

/// Arredonda para centavos (evita erro de ponto flutuante nas somas).
double cent(double v) => (v * 100).round() / 100;

String brl(double v) {
  final neg = v < 0;
  final partes = v.abs().toStringAsFixed(2).split('.');
  final inteiro = partes[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
  return '${neg ? '-' : ''}R\$ $inteiro,${partes[1]}';
}

double _num(dynamic x) => (x as num?)?.toDouble() ?? 0;

/// Como o cliente pagou. Só o dinheiro entra na conferência da gaveta.
enum Forma { dinheiro, cartao, pix }

extension FormaX on Forma {
  String get rotulo => switch (this) {
        Forma.dinheiro => 'Dinheiro',
        Forma.cartao => 'Cartão',
        Forma.pix => 'Pix',
      };
  IconData get icone => switch (this) {
        Forma.dinheiro => Icons.payments_rounded,
        Forma.cartao => Icons.credit_card_rounded,
        Forma.pix => Icons.qr_code_rounded,
      };
  Color get cor => switch (this) {
        Forma.dinheiro => const Color(0xFF12A36E),
        Forma.cartao => const Color(0xFF2F6FEB),
        Forma.pix => const Color(0xFF007C91),
      };
  String get api => name;
}

Forma formaDe(String? s) {
  final v = (s ?? '').toLowerCase();
  if (v == 'pix') return Forma.pix;
  if (v.startsWith('cart') || v.contains('credito') || v.contains('debito')) {
    return Forma.cartao;
  }
  return Forma.dinheiro;
}

enum Categoria { ingredientes, embalagem, gas, outros }

extension CategoriaX on Categoria {
  String get rotulo => switch (this) {
        Categoria.ingredientes => 'Ingredientes',
        Categoria.embalagem => 'Embalagem',
        Categoria.gas => 'Gás',
        Categoria.outros => 'Outros',
      };
  IconData get icone => switch (this) {
        Categoria.ingredientes => Icons.shopping_basket_rounded,
        Categoria.embalagem => Icons.inventory_2_rounded,
        Categoria.gas => Icons.local_fire_department_rounded,
        Categoria.outros => Icons.more_horiz_rounded,
      };
  Color get cor => switch (this) {
        Categoria.ingredientes => const Color(0xFFF0476B),
        Categoria.embalagem => const Color(0xFF3F7CF0),
        Categoria.gas => const Color(0xFFEE8A1B),
        Categoria.outros => const Color(0xFF7A828C),
      };
}

Categoria categoriaDe(String? s) {
  for (final c in Categoria.values) {
    if (c.name == s) return c;
  }
  return Categoria.outros;
}

class Produto {
  final int id;
  String nome;
  double preco;
  int estoque;

  Produto({required this.id, required this.nome, required this.preco, required this.estoque});

  Visual get visual => visualDe(nome);

  factory Produto.fromJson(Map<String, dynamic> m) => Produto(
        id: (m['id'] as num).toInt(),
        nome: m['nome'] as String,
        preco: (m['preco'] as num).toDouble(),
        estoque: (m['estoque'] as num).toInt(),
      );

  Map<String, dynamic> toJson() => {'id': id, 'nome': nome, 'preco': preco, 'estoque': estoque};
}

class Venda {
  final int? id;
  final int produtoId;
  final int quantidade;
  final double valor;
  final DateTime data;
  final Forma forma;

  Venda({
    this.id,
    required this.produtoId,
    required this.quantidade,
    required this.valor,
    required this.data,
    this.forma = Forma.dinheiro,
  });

  factory Venda.fromJson(Map<String, dynamic> m) => Venda(
        id: (m['id'] as num?)?.toInt(),
        produtoId: (m['produto_id'] as num).toInt(),
        quantidade: (m['quantidade'] as num).toInt(),
        valor: (m['valor'] as num).toDouble(),
        data: DateTime.parse((m['data'] ?? m['data_hora']) as String).toLocal(),
        forma: formaDe(m['forma_pagamento'] as String?),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'produto_id': produtoId,
        'quantidade': quantidade,
        'valor': valor,
        'data': data.toIso8601String(),
        'forma_pagamento': forma.api,
      };
}

class Despesa {
  final int? id;
  final Categoria categoria;
  final double valor;
  final DateTime data;
  final bool daGaveta; // true = saiu do dinheiro da gaveta

  Despesa({this.id, required this.categoria, required this.valor, required this.data, required this.daGaveta});

  factory Despesa.fromJson(Map<String, dynamic> m) => Despesa(
        id: (m['id'] as num?)?.toInt(),
        categoria: categoriaDe(m['categoria'] as String?),
        valor: (m['valor'] as num).toDouble(),
        data: DateTime.parse(m['data'] as String).toLocal(),
        daGaveta: m['da_gaveta'] == true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'categoria': categoria.name,
        'valor': valor,
        'data': data.toIso8601String(),
        'da_gaveta': daGaveta,
      };
}

/// Fechamento do caixa de um dia.
class Fechamento {
  final int? id;
  final DateTime data;
  final double troco; // dinheiro que já estava na gaveta
  final double dinheiro; // vendas em dinheiro
  final double saidas; // gastos pagos com dinheiro da gaveta
  final double contado; // dinheiro contado no fim do dia
  final double cartao; // vendas no cartão (não entra na gaveta)
  final double pix; // vendas recebidas por Pix

  Fechamento({
    this.id,
    required this.data,
    required this.troco,
    required this.dinheiro,
    required this.saidas,
    required this.contado,
    required this.cartao,
    required this.pix,
  });

  double get esperado => cent(troco + dinheiro - saidas);
  double get diferenca => cent(contado - esperado);

  factory Fechamento.fromJson(Map<String, dynamic> m) => Fechamento(
        id: (m['id'] as num?)?.toInt(),
        data: DateTime.parse(m['data'] as String).toLocal(),
        troco: _num(m['troco_inicial']),
        dinheiro: _num(m['vendas_dinheiro']),
        saidas: _num(m['saidas_gaveta']),
        contado: _num(m['contado_dinheiro']),
        cartao: _num(m['total_cartao']),
        pix: _num(m['total_pix']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'data': data.toIso8601String(),
        'troco_inicial': troco,
        'vendas_dinheiro': dinheiro,
        'saidas_gaveta': saidas,
        'contado_dinheiro': contado,
        'total_cartao': cartao,
        'total_pix': pix,
      };
}