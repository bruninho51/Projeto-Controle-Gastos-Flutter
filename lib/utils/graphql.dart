import 'package:graphql_flutter/graphql_flutter.dart';

class MyGraphQLClient {
  static const String _baseUrl = 'https://api.orcamentos.app/analytics/graphql';

  /// Cria o client GraphQL
  static Future<CustomGraphQLClient> create({required String token}) async {
    final httpLink = HttpLink(
      _baseUrl,
      defaultHeaders: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final client = GraphQLClient(
      link: httpLink,
      cache: GraphQLCache(store: InMemoryStore()),
    );

    return CustomGraphQLClient(client);
  }
}

class CustomGraphQLClient {
  final GraphQLClient _client;

  CustomGraphQLClient(this._client);

  /// Query GraphQL
  Future<Map<String, dynamic>> query(String document, {Map<String, dynamic>? variables}) async {
    final options = QueryOptions(
      document: gql(document),
      variables: variables ?? {},
      fetchPolicy: FetchPolicy.networkOnly,
    );

    final result = await _client.query(options);

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    return result.data ?? {};
  }

  /// Mutation GraphQL
  Future<Map<String, dynamic>> mutate(String document, {Map<String, dynamic>? variables}) async {
    final options = MutationOptions(
      document: gql(document),
      variables: variables ?? {},
    );

    final result = await _client.mutate(options);

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    return result.data ?? {};
  }
}
