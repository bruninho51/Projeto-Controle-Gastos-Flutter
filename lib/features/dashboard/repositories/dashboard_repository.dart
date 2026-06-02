import 'dart:convert';

import 'package:orcamentos_app/utils/graphql.dart';
import 'package:orcamentos_app/utils/http.dart';

class DashboardRepository {
  Future<List<dynamic>> fetchOrcamentos(String token) async {
    final client = await MyHttpClient.create();
    final r = await client.get(
      'orcamentos',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return r.statusCode >= 200 && r.statusCode <= 299
        ? json.decode(r.body) as List<dynamic>
        : [];
  }

  Future<Map<String, dynamic>> fetchConsolidado(String token) async {
    final graphql = await MyGraphQLClient.create(token: token);
    final result = await graphql.query('''
      query {
        consolidadoOrcamentos(filter: { encerrado: false }) {
          valorTotal, valorLivre, valorAtual,
          gastosFixosComprometidos, gastosVariadosRealizados, valorPoupado
        }
      }
    ''');
    return result['consolidadoOrcamentos'] as Map<String, dynamic>;
  }
}
