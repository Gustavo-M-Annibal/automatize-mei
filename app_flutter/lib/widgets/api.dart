import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiErro implements Exception {
  final String mensagem;
  ApiErro(this.mensagem);
  @override
  String toString() => mensagem;
}

/// Cliente HTTP da API FastAPI do projeto.
/// No emulador Android o computador é 10.0.2.2; no iOS/desktop use localhost.
class Api {
  String baseUrl;
  String? token; // preenchido se o grupo implementar login com JWT

  Api({this.baseUrl = 'http://10.0.2.2:8000'});

  Map<String, String> get _cab => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  String _mensagem(int codigo, dynamic json) {
    if (json is Map && json['detail'] is String) return json['detail'] as String;
    switch (codigo) {
      case 401:
        return 'É preciso entrar de novo.';
      case 404:
        return 'Não encontrei esse registro.';
      case 409:
        return 'Essa ação não é permitida agora.';
      case 400:
      case 422:
        return 'Dados inválidos.';
      default:
        return 'Algo deu errado ($codigo).';
    }
  }

  Future<dynamic> _enviar(String metodo, String caminho, [Object? corpo]) async {
    try {
      final req = http.Request(metodo, Uri.parse('$baseUrl$caminho'))..headers.addAll(_cab);
      if (corpo != null) req.body = jsonEncode(corpo);
      final streamed = await req.send().timeout(const Duration(seconds: 6));
      final r = await http.Response.fromStream(streamed);
      dynamic json;
      if (r.bodyBytes.isNotEmpty) {
        try {
          json = jsonDecode(utf8.decode(r.bodyBytes));
        } catch (_) {
          json = null;
        }
      }
      if (r.statusCode >= 200 && r.statusCode < 300) return json;
      throw ApiErro(_mensagem(r.statusCode, json));
    } on ApiErro {
      rethrow;
    } catch (_) {
      throw ApiErro('Sem conexão com o servidor. Confira a internet e o endereço da API.');
    }
  }

  Future<dynamic> get(String caminho) => _enviar('GET', caminho);
  Future<dynamic> post(String caminho, Object corpo) => _enviar('POST', caminho, corpo);
  Future<dynamic> put(String caminho, Object corpo) => _enviar('PUT', caminho, corpo);
  Future<dynamic> delete(String caminho) => _enviar('DELETE', caminho);
}