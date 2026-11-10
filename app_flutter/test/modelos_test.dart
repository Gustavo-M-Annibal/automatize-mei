import 'package:flutter_test/flutter_test.dart';
import 'package:app_flutter/widgets/modelos.dart';

void main() {
  group('valores monetários da API', () {
    test('converte preço enviado como texto', () {
      final produto = Produto.fromJson({
        'id': 1,
        'nome': 'Chocolate',
        'preco': '3.00',
        'estoque': 30,
      });

      expect(produto.preco, 3.0);
    });

    test('aceita valores enviados como número', () {
      final produto = Produto.fromJson({
        'id': 1,
        'nome': 'Chocolate',
        'preco': 3.0,
        'estoque': 30,
      });

      expect(produto.preco, 3.0);
    });

    test('informa erro para um valor monetário inválido', () {
      expect(
        () => numeroApi('inválido', campo: 'preco'),
        throwsFormatException,
      );
    });
  });
}
