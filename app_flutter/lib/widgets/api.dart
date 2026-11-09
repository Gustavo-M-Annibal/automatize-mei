import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiErro implements Exception {
  final String mensagem;
  final int? statusCode;
  ApiErro(this.mensagem, {this.statusCode});
  @override
  String toString() => mensagem;
}

/// Cliente HTTP da API FastAPI do projeto.
/// No emulador Android o computador é 10.0.2.2; no iOS/desktop use localhost.
class Api {
  String baseUrl;
  String? token;
  Future<void> Function()? aoReceber401;

  Api({String? baseUrl})
      : baseUrl = baseUrl ??
            (kIsWeb ? 'http://localhost:8000' : 'http://10.0.2.2:8000');

  Map<String, String> _cab({
    required bool incluirToken,
    required bool formulario,
  }) => {
        'Content-Type': formulario
            ? 'application/x-www-form-urlencoded'
            : 'application/json',
        if (incluirToken && token != null) 'Authorization': 'Bearer $token',
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

  Future<dynamic> _enviar(
    String metodo,
    String caminho, [
    Object? corpo,
  ], {
    Map<String, String>? formulario,
    bool incluirToken = true,
  }) async {
    try {
      final req = http.Request(metodo, Uri.parse('$baseUrl$caminho'));
      req.headers.addAll(_cab(
        incluirToken: incluirToken,
        formulario: formulario != null,
      ));
      if (formulario != null) {
        req.bodyFields = formulario;
      } else if (corpo != null) {
        req.body = jsonEncode(corpo);
      }
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
      if (r.statusCode == 401 && incluirToken) await aoReceber401?.call();
      throw ApiErro(_mensagem(r.statusCode, json), statusCode: r.statusCode);
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

  Future<String> autenticar(String email, String senha) async {
    final resposta = await _enviar(
      'POST',
      '/auth/login',
      formulario: {'username': email, 'password': senha},
      incluirToken: false,
    );
    if (resposta is! Map ||
        resposta['access_token'] is! String ||
        (resposta['access_token'] as String).isEmpty ||
        resposta['token_type'] is! String ||
        (resposta['token_type'] as String).toLowerCase() != 'bearer') {
      throw ApiErro('Não foi possível concluir o acesso.');
    }
    return resposta['access_token'] as String;
  }
}