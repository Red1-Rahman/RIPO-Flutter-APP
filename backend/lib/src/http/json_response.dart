// backend\lib\src\http\json_response.dart
import 'dart:convert';

import 'package:shelf/shelf.dart';

Response jsonResponse(int statusCode, Object payload) {
  return Response(
    statusCode,
    body: jsonEncode(payload),
    headers: const {'content-type': 'application/json'},
  );
}

Response ok(Object payload) => jsonResponse(200, payload);
Response created(Object payload) => jsonResponse(201, payload);
