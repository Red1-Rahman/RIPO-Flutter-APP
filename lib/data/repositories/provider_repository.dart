import '../api_client.dart';

class ProviderRepository {
  final ApiClient _client = ApiClient.instance;

  Future<List<Map<String, dynamic>>> fetchServices() async {
    final response =
        await _client.get('/provider/services', authRequired: true);
    if (response is List) {
      return response
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  Future<Map<String, List<Map<String, dynamic>>>> fetchJobs() async {
    final response = await _client.get('/provider/jobs', authRequired: true);
    final payload = Map<String, dynamic>.from(response as Map);

    List<Map<String, dynamic>> toList(String key) {
      final value = payload[key];
      if (value is List) {
        return value
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      }
      return <Map<String, dynamic>>[];
    }

    return {
      'requests': toList('requests'),
      'active': toList('active'),
      'completed': toList('completed'),
    };
  }

  Future<Map<String, dynamic>> updateServiceStatus({
    required String serviceId,
    required bool isActive,
  }) async {
    final response = await _client.patch(
      '/provider/services/$serviceId/status',
      authRequired: true,
      body: {'isActive': isActive},
    );

    return Map<String, dynamic>.from(response as Map);
  }

  Future<void> acceptJob(String jobId) async {
    await _client.post('/provider/jobs/$jobId/accept', authRequired: true);
  }

  Future<void> declineJob(String jobId) async {
    await _client.post('/provider/jobs/$jobId/decline', authRequired: true);
  }

  Future<void> completeJob(String jobId) async {
    await _client.post('/provider/jobs/$jobId/complete', authRequired: true);
  }
}
