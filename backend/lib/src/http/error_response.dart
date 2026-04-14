// backend\lib\src\http\error_response.dart
import 'package:shelf/shelf.dart';

import 'json_response.dart';

Map<String, Object?> _errorBody(
  String code,
  String message, {
  Object? details,
}) {
  return {
    'error': {
      'code': code,
      'message': message,
      if (details != null) 'details': details,
    },
  };
}

Object badRequestBody(String message, {Object? details}) {
  return _errorBody('bad_request', message, details: details);
}

Object unauthorizedBody(String message) {
  return _errorBody('unauthorized', message);
}

Object forbiddenBody(String message) {
  return _errorBody('forbidden', message);
}

Object notFoundBody(String message) {
  return _errorBody('not_found', message);
}

Object conflictBody(String message) {
  return _errorBody('conflict', message);
}

Object internalBody() {
  return _errorBody('internal_error', 'Something went wrong.');
}

Response badRequest(String message, {Object? details}) {
  return jsonResponse(400, badRequestBody(message, details: details));
}

Response unauthorized(String message) {
  return jsonResponse(401, unauthorizedBody(message));
}

Response forbidden(String message) {
  return jsonResponse(403, forbiddenBody(message));
}

Response notFound(String message) {
  return jsonResponse(404, notFoundBody(message));
}

Response conflict(String message) {
  return jsonResponse(409, conflictBody(message));
}

Response internalError() {
  return jsonResponse(500, internalBody());
}
