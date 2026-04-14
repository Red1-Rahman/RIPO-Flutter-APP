// backend\test\api_test.dart
import 'dart:convert';
import 'dart:io';

import 'package:ripo_local_api/src/server.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  late Handler handler;
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('ripo_api_test_');
    final dbPath = '${tempDir.path}/test.sqlite3';
    handler = createHandler(dbFilePath: dbPath);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('login returns token and role', () async {
    final response = await _jsonRequest(
      handler,
      'POST',
      '/auth/login',
      body: {
        'identifier': 'customer@ripo.com',
        'password': '1234',
      },
    );

    expect(response.statusCode, 200);
    expect(response.body['token'], isA<String>());
    expect(response.body['role'], 'customer');
  });

  test('invalid login returns unauthorized', () async {
    final response = await _jsonRequest(
      handler,
      'POST',
      '/auth/login',
      body: {
        'identifier': 'customer@ripo.com',
        'password': 'wrong',
      },
    );

    expect(response.statusCode, 401);
    expect(response.body['error']['code'], 'unauthorized');
  });

  test('admin endpoint rejects unauthenticated', () async {
    final response = await _jsonRequest(handler, 'GET', '/admin/dashboard');
    expect(response.statusCode, 401);
  });

  test('admin endpoint rejects wrong role token', () async {
    final login = await _jsonRequest(
      handler,
      'POST',
      '/auth/login',
      body: {
        'identifier': 'customer@ripo.com',
        'password': '1234',
      },
    );

    final response = await _jsonRequest(
      handler,
      'GET',
      '/admin/finance',
      headers: {
        'authorization': 'Bearer ${login.body['token']}',
      },
    );

    expect(response.statusCode, 403);
    expect(response.body['error']['code'], 'forbidden');
  });

  test('booking creation validates required fields', () async {
    final login = await _jsonRequest(
      handler,
      'POST',
      '/auth/login',
      body: {
        'identifier': 'customer@ripo.com',
        'password': '1234',
      },
    );

    final response = await _jsonRequest(
      handler,
      'POST',
      '/bookings/',
      headers: {
        'authorization': 'Bearer ${login.body['token']}',
      },
      body: {
        'serviceId': 1,
        'date': '2026-04-30',
      },
    );

    expect(response.statusCode, 400);
    expect(response.body['error']['code'], 'bad_request');
  });
}

class _JsonResult {
  _JsonResult({required this.statusCode, required this.body});

  final int statusCode;
  final Map<String, dynamic> body;
}

Future<_JsonResult> _jsonRequest(
  Handler handler,
  String method,
  String path, {
  Map<String, String>? headers,
  Map<String, dynamic>? body,
}) async {
  final request = Request(
    method,
    Uri.parse('http://localhost$path'),
    headers: {
      if (body != null) 'content-type': 'application/json',
      ...?headers,
    },
    body: body == null ? null : jsonEncode(body),
  );

  final response = await handler(request);
  final responseBody = await response.readAsString();
  final parsed = jsonDecode(responseBody) as Map<String, dynamic>;

  return _JsonResult(statusCode: response.statusCode, body: parsed);
}
