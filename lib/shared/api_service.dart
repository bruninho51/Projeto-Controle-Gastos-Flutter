import 'dart:convert';
import 'dart:ui';

import 'package:http/http.dart' as http;
import 'package:orcamentos_app/shared/auth_manager.dart';

import 'api_models.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException: $message (status: $statusCode)';
}

class ApiService {
  static const String _defaultBaseUrl = 'https://api.orcamentos.app/api/v1';

  static VoidCallback? onUnauthorized;

  final String baseUrl;
  final http.Client client;

  final String? Function() tokenProvider;

  ApiService({
    required this.tokenProvider,
    String? baseUrl,
    http.Client? client,
  })  : baseUrl = baseUrl ?? _defaultBaseUrl,
        client = client ?? http.Client();

  /// Método genérico para requisições HTTP com autenticação
  Future<T> _request<T>({
    required String method,
    required String path,
    Map<String, dynamic>? queryParams,
    dynamic body,
    required T Function(dynamic) fromJson,
  }) async {
    final cleanBaseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$cleanBaseUrl$cleanPath')
        .replace(queryParameters: queryParams?.map((k, v) => MapEntry(k, v.toString())));

    final token = tokenProvider.call();

    final headers = {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty)
        'Authorization': 'Bearer $token',
    };

    http.Response response;
    try {
      if (method == 'GET') {
        response = await client.get(uri, headers: headers);
      } else if (method == 'POST') {
        response = await client.post(uri, headers: headers, body: jsonEncode(body));
      } else if (method == 'PUT') {
        response = await client.put(uri, headers: headers, body: jsonEncode(body));
      } else if (method == 'PATCH') {
        response = await client.patch(uri, headers: headers, body: jsonEncode(body));
      } else if (method == 'DELETE') {
        response = await client.delete(uri, headers: headers);
      } else {
        throw ApiException('Método HTTP não suportado: $method');
      }
    } catch (e) {
      throw ApiException('Erro de rede: $e');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return null as T;
      }
      try {
        final json = jsonDecode(utf8.decode(response.bodyBytes));
        return fromJson(json);
      } catch (e) {
        throw ApiException('Erro ao decodificar resposta JSON: $e', statusCode: response.statusCode);
      }
    } else if (response.statusCode == 401) {
      await AuthManager().logout();
      throw ApiException('Token expirado', statusCode: 401);
    } else {
      String errorMessage = 'Erro na requisição';
      try {
        final errorJson = jsonDecode(utf8.decode(response.bodyBytes));
        errorMessage = errorJson['message'] ?? errorJson['error'] ?? 'Erro desconhecido';
      } catch (_) {}
      throw ApiException(errorMessage, statusCode: response.statusCode);
    }
  }

  // -------------------- Autenticação --------------------
  Future<AuthResponseDto> verifyGoogle(String idToken) async {
    return await _request(
      method: 'POST',
      path: '/auth/google/verify',
      body: AuthCreateDto(idToken: idToken).toJson(),
      fromJson: (json) => AuthResponseDto.fromJson(json),
    );
  }

  // -------------------- Categorias de Gastos --------------------
  Future<List<CategoriaGastoResponseDto>> getCategorias({String? nome}) async {
    return await _request(
      method: 'GET',
      path: '/categorias-gastos',
      queryParams: nome != null ? {'nome': nome} : null,
      fromJson: (json) => (json as List).map((e) => CategoriaGastoResponseDto.fromJson(e)).toList(),
    );
  }

  Future<CategoriaGastoResponseDto> createCategoria(CategoriaGastoCreateDto dto) async {
    return await _request(
      method: 'POST',
      path: '/categorias-gastos',
      body: dto.toJson(),
      fromJson: (json) => CategoriaGastoResponseDto.fromJson(json),
    );
  }

  Future<CategoriaGastoResponseDto> updateCategoria(int id, CategoriaGastoUpdateDto dto) async {
    return await _request(
      method: 'PATCH',
      path: '/categorias-gastos/$id',
      body: dto.toJson(),
      fromJson: (json) => CategoriaGastoResponseDto.fromJson(json),
    );
  }

  Future<CategoriaGastoResponseDto> deleteCategoria(int id) async {
    return await _request(
      method: 'DELETE',
      path: '/categorias-gastos/$id',
      fromJson: (json) => CategoriaGastoResponseDto.fromJson(json),
    );
  }

  // -------------------- Orçamentos --------------------
  Future<List<OrcamentoResponseDto>> getOrcamentos({
    String? nome,
    bool? encerrado,
    bool? inativo,
  }) async {
    final query = <String, dynamic>{};
    if (nome != null) query['nome'] = nome;
    if (encerrado != null) query['encerrado'] = encerrado;
    if (inativo != null) query['inativo'] = inativo;

    return await _request(
      method: 'GET',
      path: '/orcamentos',
      queryParams: query.isNotEmpty ? query : null,
      fromJson: (json) => (json as List).map((e) => OrcamentoResponseDto.fromJson(e)).toList(),
    );
  }

  Future<OrcamentoResponseDto> getOrcamentoById(int id) async {
    return await _request(
      method: 'GET',
      path: '/orcamentos/$id',
      fromJson: (json) => OrcamentoResponseDto.fromJson(json),
    );
  }

  Future<OrcamentoResponseDto> createOrcamento(OrcamentoCreateDto dto) async {
    return await _request(
      method: 'POST',
      path: '/orcamentos',
      body: dto.toJson(),
      fromJson: (json) => OrcamentoResponseDto.fromJson(json),
    );
  }

  Future<OrcamentoResponseDto> updateOrcamento(int id, OrcamentoUpdateDto dto) async {
    return await _request(
      method: 'PATCH',
      path: '/orcamentos/$id',
      body: dto.toJson(),
      fromJson: (json) => OrcamentoResponseDto.fromJson(json),
    );
  }

  Future<OrcamentoResponseDto> deleteOrcamento(int id) async {
    return await _request(
      method: 'DELETE',
      path: '/orcamentos/$id',
      fromJson: (json) => OrcamentoResponseDto.fromJson(json),
    );
  }

  // -------------------- Gastos Fixos --------------------
  Future<List<GastoFixoResponseDto>> getGastosFixos({
    required int orcamentoId,
    String? descricao,
    String? status,
    DateTime? dataPgto,
    DateTime? dataPgtoInicio,
    DateTime? dataPgtoFim,
    bool? vencido,
    String? nomeCategoria,
  }) async {
    final query = <String, dynamic>{};
    if (descricao != null) query['descricao'] = descricao;
    if (status != null) query['status'] = status;
    if (dataPgto != null) query['data_pgto'] = dataPgto.toIso8601String();
    if (dataPgtoInicio != null) query['data_pgto_inicio'] = dataPgtoInicio.toIso8601String();
    if (dataPgtoFim != null) query['data_pgto_fim'] = dataPgtoFim.toIso8601String();
    if (vencido != null) query['vencido'] = vencido;
    if (nomeCategoria != null) query['nome_categoria'] = nomeCategoria;

    return await _request(
      method: 'GET',
      path: '/orcamentos/$orcamentoId/gastos-fixos',
      queryParams: query.isNotEmpty ? query : null,
      fromJson: (json) => (json as List).map((e) => GastoFixoResponseDto.fromJson(e)).toList(),
    );
  }

  Future<GastoFixoResponseDto> getGastoFixoById(int orcamentoId, int id) async {
    return await _request(
      method: 'GET',
      path: '/orcamentos/$orcamentoId/gastos-fixos/$id',
      fromJson: (json) => GastoFixoResponseDto.fromJson(json),
    );
  }

  Future<GastoFixoResponseDto> createGastoFixo(int orcamentoId, GastoFixoCreateDto dto) async {
    return await _request(
      method: 'POST',
      path: '/orcamentos/$orcamentoId/gastos-fixos',
      body: dto.toJson(),
      fromJson: (json) => GastoFixoResponseDto.fromJson(json),
    );
  }

  Future<GastoFixoResponseDto> updateGastoFixo(int orcamentoId, int id, GastoFixoUpdateDto dto) async {
    return await _request(
      method: 'PATCH',
      path: '/orcamentos/$orcamentoId/gastos-fixos/$id',
      body: dto.toJson(),
      fromJson: (json) => GastoFixoResponseDto.fromJson(json),
    );
  }

  Future<GastoFixoResponseDto> deleteGastoFixo(int orcamentoId, int id) async {
    return await _request(
      method: 'DELETE',
      path: '/orcamentos/$orcamentoId/gastos-fixos/$id',
      fromJson: (json) => GastoFixoResponseDto.fromJson(json),
    );
  }

  // -------------------- Gastos Variados --------------------
  Future<List<GastoVariadoResponseDto>> getGastosVariados({
    required int orcamentoId,
    String? descricao,
    DateTime? dataPgto,
    DateTime? dataPgtoInicio,
    DateTime? dataPgtoFim,
    String? nomeCategoria,
  }) async {
    final query = <String, dynamic>{};
    if (descricao != null) query['descricao'] = descricao;
    if (dataPgto != null) query['data_pgto'] = dataPgto.toIso8601String();
    if (dataPgtoInicio != null) query['data_pgto_inicio'] = dataPgtoInicio.toIso8601String();
    if (dataPgtoFim != null) query['data_pgto_fim'] = dataPgtoFim.toIso8601String();
    if (nomeCategoria != null) query['nome_categoria'] = nomeCategoria;

    return await _request(
      method: 'GET',
      path: '/orcamentos/$orcamentoId/gastos-variados',
      queryParams: query.isNotEmpty ? query : null,
      fromJson: (json) => (json as List).map((e) => GastoVariadoResponseDto.fromJson(e)).toList(),
    );
  }

  Future<GastoVariadoResponseDto> getGastoVariadoById(int orcamentoId, int id) async {
    return await _request(
      method: 'GET',
      path: '/orcamentos/$orcamentoId/gastos-variados/$id',
      fromJson: (json) => GastoVariadoResponseDto.fromJson(json),
    );
  }

  Future<GastoVariadoResponseDto> createGastoVariado(int orcamentoId, GastoVariadoCreateDto dto) async {
    return await _request(
      method: 'POST',
      path: '/orcamentos/$orcamentoId/gastos-variados',
      body: dto.toJson(),
      fromJson: (json) => GastoVariadoResponseDto.fromJson(json),
    );
  }

  Future<GastoVariadoResponseDto> updateGastoVariado(int orcamentoId, int id, GastoVariadoUpdateDto dto) async {
    return await _request(
      method: 'PATCH',
      path: '/orcamentos/$orcamentoId/gastos-variados/$id',
      body: dto.toJson(),
      fromJson: (json) => GastoVariadoResponseDto.fromJson(json),
    );
  }

  Future<GastoVariadoResponseDto> deleteGastoVariado(int orcamentoId, int id) async {
    return await _request(
      method: 'DELETE',
      path: '/orcamentos/$orcamentoId/gastos-variados/$id',
      fromJson: (json) => GastoVariadoResponseDto.fromJson(json),
    );
  }

  // -------------------- Tokens de Dispositivos --------------------
  Future<TokenDispositivoResponseDto> upsertTokenDispositivo(TokenDispositivoUpsertDto dto) async {
    return await _request(
      method: 'PUT',
      path: '/tokens-dispositivos',
      body: dto.toJson(),
      fromJson: (json) => TokenDispositivoResponseDto.fromJson(json),
    );
  }

  Future<List<TokenDispositivoResponseDto>> getTokensDispositivos() async {
    return await _request(
      method: 'GET',
      path: '/tokens-dispositivos',
      fromJson: (json) => (json as List).map((e) => TokenDispositivoResponseDto.fromJson(e)).toList(),
    );
  }

  Future<TokenDispositivoResponseDto> getTokenDispositivoById(int id) async {
    return await _request(
      method: 'GET',
      path: '/tokens-dispositivos/$id',
      fromJson: (json) => TokenDispositivoResponseDto.fromJson(json),
    );
  }

  Future<TokenDispositivoResponseDto> deleteTokenDispositivo(int id) async {
    return await _request(
      method: 'DELETE',
      path: '/tokens-dispositivos/$id',
      fromJson: (json) => TokenDispositivoResponseDto.fromJson(json),
    );
  }
}