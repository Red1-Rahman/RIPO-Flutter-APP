import '../api_client.dart';

class BookingRepository {
  final ApiClient _client = ApiClient.instance;

  Future<List<Map<String, dynamic>>> fetchAvailability({
    required int serviceId,
    required String date,
  }) async {
    final response = await _client.get(
      '/bookings/availability',
      query: {'serviceId': '$serviceId', 'date': date},
    );

    final payload = Map<String, dynamic>.from(response as Map);
    final slots = payload['slots'];
    if (slots is List) {
      return slots
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  Future<Map<String, dynamic>> createBooking({
    required int serviceId,
    required String date,
    required String timeSlot,
    required String address,
  }) async {
    final response = await _client.post(
      '/bookings/',
      authRequired: true,
      body: {
        'serviceId': serviceId,
        'date': date,
        'timeSlot': timeSlot,
        'address': address,
      },
    );

    return Map<String, dynamic>.from(response as Map);
  }

  Future<List<Map<String, dynamic>>> fetchMyBookings() async {
    final response = await _client.get('/bookings/my', authRequired: true);
    if (response is List) {
      return response
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  Future<Map<String, dynamic>> fetchBookingDetails(String bookingId) async {
    final response =
        await _client.get('/bookings/$bookingId', authRequired: true);
    return Map<String, dynamic>.from(response as Map);
  }
}
