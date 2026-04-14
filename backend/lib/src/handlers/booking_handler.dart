import 'package:shelf/shelf.dart';
import 'package:sqlite3/sqlite3.dart';

import '../http/auth.dart';
import '../http/error_response.dart';
import '../http/json_response.dart';
import '../validation/request_validation.dart';

class BookingHandler {
  BookingHandler({required this.db});

  final Database db;

  static const _defaultSlots = <String>[
    '10 AM - 11 AM',
    '11 AM - 12 PM',
    '12 PM - 1 PM',
    '1 PM - 2 PM',
    '2 PM - 3 PM',
    '3 PM - 4 PM',
    '4 PM - 5 PM',
    '9 PM - 10 PM',
  ];

  Response getAvailability(Request request) {
    try {
      final serviceId = parseIntParam(request.url.queryParameters['serviceId']);
      final date = request.url.queryParameters['date']?.trim();
      if (serviceId == null || date == null || date.isEmpty) {
        return badRequest('serviceId and date are required.');
      }

      final bookedRows = db.select(
        'SELECT time_slot FROM bookings WHERE service_id = ? AND booking_date = ?',
        [serviceId, date],
      );
      final bookedSlots = bookedRows.map((row) => row['time_slot'] as String).toSet();

      return ok({
        'serviceId': serviceId,
        'date': date,
        'slots': _defaultSlots
            .map((slot) => {
                  'time': slot,
                  'isBooked': bookedSlots.contains(slot),
                })
            .toList(),
      });
    } catch (_) {
      return internalError();
    }
  }

  Future<Response> createBooking(Request request) async {
    try {
      final auth = authFromRequest(request);
      if (auth == null) {
        return unauthorized('Missing auth context.');
      }

      final body = await readJsonBody(request);
      final missing = missingRequired(body, ['serviceId', 'date', 'timeSlot', 'address']);
      if (missing.isNotEmpty) {
        return badRequest('Missing required fields.', details: {'fields': missing});
      }

      final serviceId = int.tryParse(body['serviceId'].toString());
      if (serviceId == null) {
        return badRequest('serviceId must be an integer.');
      }

      final date = body['date'].toString();
      final timeSlot = body['timeSlot'].toString();
      final address = body['address'].toString();

      final slotTaken = db.select(
        'SELECT id FROM bookings WHERE service_id = ? AND booking_date = ? AND time_slot = ? LIMIT 1',
        [serviceId, date, timeSlot],
      );
      if (slotTaken.isNotEmpty) {
        return conflict('The selected slot is already booked.');
      }

      final serviceRows = db.select(
        'SELECT id, provider_id, name, price, category_id FROM services WHERE id = ? LIMIT 1',
        [serviceId],
      );
      if (serviceRows.isEmpty) {
        return notFound('Service not found.');
      }
      final service = serviceRows.first;
      final providerId = service['provider_id'] as int;
      final price = service['price'] as int;

      final now = DateTime.now().toIso8601String();
      db.execute(
        '''
          INSERT INTO bookings
          (customer_id, provider_id, service_id, status, booking_date, time_slot, address, price, created_at)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [auth.userId, providerId, serviceId, 'Pending', date, timeSlot, address, price, now],
      );
      final bookingId = db.lastInsertRowId;

      db.execute(
        'INSERT INTO provider_jobs (provider_id, booking_id, status, updated_at) VALUES (?, ?, ?, ?)',
        [providerId, bookingId, 'Pending Request', now],
      );

      return created({
        'bookingId': bookingId,
        'status': 'Pending',
        'date': date,
        'timeSlot': timeSlot,
        'address': address,
        'price': price,
      });
    } on FormatException catch (e) {
      return badRequest(e.message);
    } catch (_) {
      return internalError();
    }
  }

  Response listMyBookings(Request request) {
    try {
      final auth = authFromRequest(request);
      if (auth == null) {
        return unauthorized('Missing auth context.');
      }

      final rows = db.select(
        '''
          SELECT b.id, b.status, b.price, b.booking_date, b.time_slot, b.address, s.name AS service_name
          FROM bookings b
          JOIN services s ON s.id = b.service_id
          WHERE b.customer_id = ?
          ORDER BY b.id DESC
        ''',
        [auth.userId],
      );

      return ok(
        rows
            .map(
              (row) => {
                'id': row['id'].toString(),
                'status': row['status'],
                'price': row['price'],
                'date': '${row['booking_date']} ${row['time_slot']}',
                'address': row['address'],
                'serviceName': row['service_name'],
              },
            )
            .toList(),
      );
    } catch (_) {
      return internalError();
    }
  }

  Response bookingDetails(Request request, String id) {
    try {
      final bookingId = int.tryParse(id);
      if (bookingId == null) {
        return badRequest('Invalid booking id.');
      }

      final auth = authFromRequest(request);
      if (auth == null) {
        return unauthorized('Missing auth context.');
      }

      final rows = db.select(
        '''
          SELECT
            b.id,
            b.customer_id,
            b.provider_id,
            b.status,
            b.booking_date,
            b.time_slot,
            b.address,
            b.price,
            s.name AS service_name,
            c.name AS category_name,
            provider.full_name AS provider_name
          FROM bookings b
          JOIN services s ON s.id = b.service_id
          JOIN categories c ON c.id = s.category_id
          JOIN users provider ON provider.id = b.provider_id
          WHERE b.id = ?
          LIMIT 1
        ''',
        [bookingId],
      );

      if (rows.isEmpty) {
        return notFound('Booking not found.');
      }

      final row = rows.first;
      final customerId = row['customer_id'] as int;
      final providerId = row['provider_id'] as int;

      if (auth.role == 'customer' && auth.userId != customerId) {
        return forbidden('You are not allowed to view this booking.');
      }

      if (auth.role == 'provider' && auth.userId != providerId) {
        return forbidden('You are not allowed to view this booking.');
      }

      return ok({
        'id': row['id'].toString(),
        'status': row['status'],
        'dateTime': '${row['booking_date']} ${row['time_slot']}',
        'address': row['address'],
        'price': row['price'],
        'service': {
          'name': row['service_name'],
          'category': row['category_name'],
          'qty': 1,
        },
        'provider': {
          'name': row['provider_name'],
          'isOnline': true,
        },
        'payment': {
          'method': 'Pay Offline',
          'status': 'Unpaid',
          'amount': row['price'],
        },
      });
    } catch (_) {
      return internalError();
    }
  }
}
