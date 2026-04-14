import 'package:shelf/shelf.dart';
import 'package:sqlite3/sqlite3.dart';

import '../http/auth.dart';
import '../http/error_response.dart';
import '../http/json_response.dart';
import '../validation/request_validation.dart';

class AuthHandler {
  AuthHandler({required this.db, required this.tokens});

  final Database db;
  final TokenService tokens;

  Future<Response> login(Request request) async {
    try {
      final body = await readJsonBody(request);
      final identifier = ((body['identifier'] ?? body['email'] ?? body['phone']) as String?)?.trim() ?? '';
      final password = (body['password'] as String?)?.trim() ?? '';

      if (identifier.isEmpty || password.isEmpty) {
        return badRequest('identifier and password are required.');
      }

      final result = db.select(
        '''
          SELECT u.id, u.full_name, u.email, u.phone, u.password_hash, r.name AS role
          FROM users u
          JOIN roles r ON r.id = u.role_id
          WHERE lower(u.email) = lower(?) OR u.phone = ?
          LIMIT 1
        ''',
        [identifier, identifier],
      );

      if (result.isEmpty) {
        return unauthorized('Invalid credentials.');
      }

      final row = result.first;
      final expectedHash = row['password_hash'] as String;
      if (hashPassword(password) != expectedHash) {
        return unauthorized('Invalid credentials.');
      }

      final userId = row['id'] as int;
      final role = row['role'] as String;
      final token = tokens.issueToken(userId: userId, role: role);

      return ok({
        'token': token,
        'role': role,
        'user': {
          'id': userId,
          'fullName': row['full_name'],
          'email': row['email'],
          'phone': row['phone'],
          'role': role,
        }
      });
    } on FormatException catch (e) {
      return badRequest(e.message);
    } catch (_) {
      return internalError();
    }
  }

  Future<Response> register(Request request) async {
    try {
      final body = await readJsonBody(request);
      final missing = missingRequired(body, ['fullName', 'email', 'password']);
      if (missing.isNotEmpty) {
        return badRequest('Missing required fields.', details: {'fields': missing});
      }

      final role = ((body['role'] as String?) ?? 'customer').toLowerCase();
      if (!{'customer', 'provider'}.contains(role)) {
        return badRequest('Invalid role. Only customer/provider are allowed for registration.');
      }

      final email = (body['email'] as String).trim();
      final fullName = (body['fullName'] as String).trim();
      final phone = (body['phone'] as String?)?.trim();
      final password = (body['password'] as String).trim();

      final duplicate = db.select('SELECT id FROM users WHERE lower(email) = lower(?) LIMIT 1', [email]);
      if (duplicate.isNotEmpty) {
        return conflict('Email already exists.');
      }

      final roleRows = db.select('SELECT id FROM roles WHERE name = ? LIMIT 1', [role]);
      final roleId = roleRows.first['id'] as int;

      db.execute(
        'INSERT INTO users (full_name, email, phone, password_hash, role_id, created_at) VALUES (?, ?, ?, ?, ?, ?)',
        [
          fullName,
          email,
          phone,
          hashPassword(password),
          roleId,
          DateTime.now().toIso8601String(),
        ],
      );

      final userId = db.lastInsertRowId;
      final token = tokens.issueToken(userId: userId, role: role);

      return created({
        'token': token,
        'role': role,
        'user': {
          'id': userId,
          'fullName': fullName,
          'email': email,
          'phone': phone,
          'role': role,
        }
      });
    } on FormatException catch (e) {
      return badRequest(e.message);
    } catch (_) {
      return internalError();
    }
  }

  Future<Response> forgotPassword(Request request) async {
    try {
      final body = await readJsonBody(request);
      final email = (body['email'] as String?)?.trim() ?? '';
      if (email.isEmpty) {
        return badRequest('email is required.');
      }

      final rows = db.select('SELECT id FROM users WHERE lower(email) = lower(?) LIMIT 1', [email]);
      if (rows.isEmpty) {
        return ok({
          'success': true,
          'message': 'If the account exists, a reset instruction has been sent.',
        });
      }

      return ok({
        'success': true,
        'message': 'Reset instructions sent to $email',
      });
    } on FormatException catch (e) {
      return badRequest(e.message);
    } catch (_) {
      return internalError();
    }
  }
}
