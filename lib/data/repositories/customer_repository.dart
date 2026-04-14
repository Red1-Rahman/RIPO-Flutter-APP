import '../api_client.dart';

class CustomerRepository {
  final ApiClient _client = ApiClient.instance;

  Future<List<Map<String, dynamic>>> fetchRecommendedServices() async {
    final response = await _client.get('/customer/services/recommended');
    return _listOfMaps(response);
  }

  Future<List<Map<String, dynamic>>> fetchAllServices(
      {String query = ''}) async {
    final response = await _client.get(
      '/customer/services',
      query: query.trim().isEmpty ? null : {'query': query.trim()},
    );
    return _listOfMaps(response);
  }

  Future<List<Map<String, dynamic>>> fetchCategories() async {
    final response = await _client.get('/customer/categories');
    return _listOfMaps(response);
  }

  Future<Map<String, dynamic>> fetchServiceById(String serviceId) async {
    final response = await _client.get('/customer/services/$serviceId');
    return Map<String, dynamic>.from(response as Map);
  }

  List<Map<String, dynamic>> _listOfMaps(dynamic response) {
    if (response is List) {
      return response
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }
}
