import '../api_client.dart';
import '../session_store.dart';

class AuthRepository {
  final ApiClient _client = ApiClient.instance;

  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
  }) async {
    final response = await _client.post(
      '/auth/login',
      body: {
        'identifier': identifier,
        'password': password,
      },
    );

    final payload = response as Map<String, dynamic>;
    final token = payload['token'] as String;
    final role = payload['role'] as String;
    final user = Map<String, dynamic>.from(payload['user'] as Map);

    SessionStore.instance.setSession(token: token, role: role, user: user);
    return payload;
  }

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    String? phone,
    required String password,
    String role = 'customer',
  }) async {
    final response = await _client.post(
      '/auth/register',
      body: {
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'password': password,
        'role': role,
      },
    );

    return Map<String, dynamic>.from(response as Map);
  }

  Future<String> forgotPassword(String email) async {
    final response = await _client.post(
      '/auth/forgot-password',
      body: {'email': email},
    );

    final payload = response as Map<String, dynamic>;
    return (payload['message'] as String?) ?? 'Reset instruction sent.';
  }
}
