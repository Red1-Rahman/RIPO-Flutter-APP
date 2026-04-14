import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_exception.dart';
import 'session_store.dart';

class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();
  final http.Client _client = http.Client();

  Future<dynamic> get(
    String path, {
    Map<String, String>? query,
    bool authRequired = false,
  }) {
    return _send(
      'GET',
      path,
      query: query,
      authRequired: authRequired,
    );
  }

  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    bool authRequired = false,
  }) {
    return _send('POST', path, body: body, authRequired: authRequired);
  }

  Future<dynamic> patch(
    String path, {
    Map<String, dynamic>? body,
    bool authRequired = false,
  }) {
    return _send('PATCH', path, body: body, authRequired: authRequired);
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
    bool authRequired = false,
  }) async {
    final uri =
        Uri.parse('${ApiConfig.baseUrl}$path').replace(queryParameters: query);

    final headers = <String, String>{
      'content-type': 'application/json',
      'accept': 'application/json',
    };

    if (authRequired) {
      final token = SessionStore.instance.token;
      if (token == null || token.isEmpty) {
        throw const ApiException('You are not logged in.');
      }
      headers['authorization'] = 'Bearer $token';
    }

    late http.Response response;
    try {
      switch (method) {
        case 'GET':
          response = await _client.get(uri, headers: headers);
          break;
        case 'POST':
          response = await _client.post(
            uri,
            headers: headers,
            body: jsonEncode(body ?? <String, dynamic>{}),
          );
          break;
        case 'PATCH':
          response = await _client.patch(
            uri,
            headers: headers,
            body: jsonEncode(body ?? <String, dynamic>{}),
          );
          break;
        default:
          throw ApiException('Unsupported method: $method');
      }
    } catch (_) {
      throw const ApiException('Could not connect to localhost API server.');
    }

    if (response.body.isEmpty) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return <String, dynamic>{};
      }
      throw ApiException('Unexpected empty response.',
          statusCode: response.statusCode);
    }

    final decoded = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    if (decoded is Map<String, dynamic>) {
      final error = decoded['error'];
      if (error is Map<String, dynamic>) {
        throw ApiException(
          (error['message'] as String?) ?? 'Request failed.',
          statusCode: response.statusCode,
          code: error['code'] as String?,
        );
      }
    }

    throw ApiException('Request failed.', statusCode: response.statusCode);
  }
}
