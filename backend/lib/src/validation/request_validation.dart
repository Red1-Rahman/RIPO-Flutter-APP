// backend\lib\src\validation\request_validation.dart
import 'dart:convert';

import 'package:shelf/shelf.dart';

Future<Map<String, dynamic>> readJsonBody(Request request) async {
  final rawBody = await request.readAsString();
  if (rawBody.trim().isEmpty) {
    return <String, dynamic>{};
  }

  final decoded = jsonDecode(rawBody);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Body must be a JSON object.');
  }
  return decoded;
}

List<String> missingRequired(Map<String, dynamic> body, List<String> fields) {
  return fields.where((field) {
    final value = body[field];
    if (value == null) return true;
    if (value is String && value.trim().isEmpty) return true;
    return false;
  }).toList();
}

int? parseIntParam(String? value) {
  if (value == null || value.isEmpty) return null;
  return int.tryParse(value);
}
