import 'package:http/http.dart' as http;
import 'dart:convert';

class MyHttpClient {
  static const String _baseUrl = 'https://api.orcamentos.app/api/v1/';

  static Future<CustomHttpClient> create() async {
    final client = http.Client();
    return CustomHttpClient(client, _baseUrl);
  }
}

class CustomHttpClient {
  final http.Client _client;
  final String _baseUrl;

  CustomHttpClient(this._client, this._baseUrl);

  Uri _buildUri(String endpoint) => Uri.parse('$_baseUrl$endpoint');

  Future<http.Response> get(String endpoint, {Map<String, String>? headers}) {
    return _client.get(_buildUri(endpoint), headers: headers);
  }

  Future<http.Response> post(
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) {
    return _client.post(
      _buildUri(endpoint),
      headers: headers,
      body: body,
      encoding: encoding,
    );
  }

  Future<http.Response> put(
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) {
    return _client.put(
      _buildUri(endpoint),
      headers: headers,
      body: body,
      encoding: encoding,
    );
  }

  Future<http.Response> patch(
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) {
    return _client.patch(
      _buildUri(endpoint),
      headers: headers,
      body: body,
      encoding: encoding,
    );
  }

  Future<http.Response> delete(
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) {
    return _client.delete(
      _buildUri(endpoint),
      headers: headers,
      body: body,
      encoding: encoding,
    );
  }

  Future<http.Response> head(
    String endpoint, {
    Map<String, String>? headers,
  }) {
    return _client.head(
      _buildUri(endpoint),
      headers: headers,
    );
  }

  void close() {
    _client.close();
  }
}
