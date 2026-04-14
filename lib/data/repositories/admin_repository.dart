import '../api_client.dart';

class AdminRepository {
  final ApiClient _client = ApiClient.instance;

  Future<Map<String, dynamic>> fetchDashboard() async {
    final response = await _client.get('/admin/dashboard', authRequired: true);
    return Map<String, dynamic>.from(response as Map);
  }

  Future<List<Map<String, dynamic>>> fetchUsers(String role) async {
    final response = await _client.get(
      '/admin/users',
      authRequired: true,
      query: {'role': role},
    );

    if (response is List) {
      return response
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  Future<Map<String, dynamic>> fetchFinance() async {
    final response = await _client.get('/admin/finance', authRequired: true);
    return Map<String, dynamic>.from(response as Map);
  }
}
