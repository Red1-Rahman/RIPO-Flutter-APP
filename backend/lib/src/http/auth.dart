// backend\lib\src\http\auth.dart
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shelf/shelf.dart';

import 'error_response.dart';

const authContextKey = 'auth_context';

class AuthContext {
  const AuthContext({required this.userId, required this.role});

  final int userId;
  final String role;
}

class TokenService {
  TokenService(this._secret);

  final String _secret;

  String issueToken({required int userId, required String role}) {
    final payload = '$userId:$role:${DateTime.now().millisecondsSinceEpoch}';
    final encodedPayload = base64Url.encode(utf8.encode(payload));
    final signature = _sign(encodedPayload);
    return '$encodedPayload.$signature';
  }

  AuthContext? parseToken(String token) {
    final parts = token.split('.');
    if (parts.length != 2) return null;

    final payload = parts[0];
    final signature = parts[1];
    if (_sign(payload) != signature) return null;

    try {
      final decoded = utf8.decode(base64Url.decode(payload));
      final values = decoded.split(':');
      if (values.length < 3) return null;
      final userId = int.tryParse(values[0]);
      final role = values[1];
      if (userId == null || role.isEmpty) return null;
      return AuthContext(userId: userId, role: role);
    } catch (_) {
      return null;
    }
  }

  String _sign(String payload) {
    final hmac = Hmac(sha256, utf8.encode(_secret));
    return base64Url.encode(hmac.convert(utf8.encode(payload)).bytes);
  }
}

String hashPassword(String plainText) {
  final digest = sha256.convert(utf8.encode('ripo-local::$plainText'));
  return digest.toString();
}

Middleware requireAuth(TokenService tokens, {Set<String>? roles}) {
  return (innerHandler) {
    return (request) async {
      final authHeader = request.headers['authorization'];
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return unauthorized('Missing Bearer token.');
      }

      final token = authHeader.substring('Bearer '.length).trim();
      final auth = tokens.parseToken(token);
      if (auth == null) {
        return unauthorized('Invalid or expired token.');
      }

      if (roles != null && !roles.contains(auth.role)) {
        return forbidden('You do not have permission to access this resource.');
      }

      final withContext = request.change(context: {
        ...request.context,
        authContextKey: auth,
      });

      return innerHandler(withContext);
    };
  };
}

AuthContext? authFromRequest(Request request) {
  final value = request.context[authContextKey];
  return value is AuthContext ? value : null;
}
