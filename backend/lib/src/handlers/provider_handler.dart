// backend\lib\src\handlers\provider_handler.dart
import 'package:shelf/shelf.dart';
import 'package:sqlite3/sqlite3.dart';

import '../http/auth.dart';
import '../http/error_response.dart';
import '../http/json_response.dart';
import '../validation/request_validation.dart';

class ProviderHandler {
  ProviderHandler({required this.db});

  final Database db;

  Response listServices(Request request) {
    try {
      final auth = authFromRequest(request);
      if (auth == null) {
        return unauthorized('Missing auth context.');
      }

      final rows = db.select(
        '''
          SELECT s.id, s.name, c.name AS category, s.image, s.price, s.original_price,
                 s.duration, s.rating, s.reviews, s.is_active
          FROM services s
          JOIN categories c ON c.id = s.category_id
          WHERE s.provider_id = ?
          ORDER BY s.id DESC
        ''',
        [auth.userId],
      );

      return ok(
        rows
            .map(
              (row) => {
                'id': row['id'].toString(),
                'name': row['name'],
                'category': row['category'],
                'image': row['image'],
                'price': row['price'],
                'originalPrice': row['original_price'],
                'duration': row['duration'],
                'rating': row['rating'],
                'reviews': row['reviews'],
                'isActive': (row['is_active'] as int) == 1,
              },
            )
            .toList(),
      );
    } catch (_) {
      return internalError();
    }
  }

  Future<Response> updateServiceStatus(Request request, String id) async {
    try {
      final auth = authFromRequest(request);
      if (auth == null) {
        return unauthorized('Missing auth context.');
      }

      final serviceId = int.tryParse(id);
      if (serviceId == null) {
        return badRequest('Invalid service id.');
      }

      final body = await readJsonBody(request);
      if (body['isActive'] is! bool) {
        return badRequest('isActive (boolean) is required.');
      }
      final isActive = body['isActive'] as bool;

      final found = db.select(
        'SELECT id FROM services WHERE id = ? AND provider_id = ? LIMIT 1',
        [serviceId, auth.userId],
      );
      if (found.isEmpty) {
        return notFound('Service not found for this provider.');
      }

      db.execute(
        'UPDATE services SET is_active = ? WHERE id = ? AND provider_id = ?',
        [isActive ? 1 : 0, serviceId, auth.userId],
      );

      return ok({'serviceId': serviceId, 'isActive': isActive});
    } on FormatException catch (e) {
      return badRequest(e.message);
    } catch (_) {
      return internalError();
    }
  }

  Response listJobs(Request request) {
    try {
      final auth = authFromRequest(request);
      if (auth == null) {
        return unauthorized('Missing auth context.');
      }

      final rows = db.select(
        '''
          SELECT
            pj.id,
            pj.status AS job_status,
            b.status AS booking_status,
            b.booking_date,
            b.time_slot,
            b.address,
            b.price,
            c.full_name AS customer_name,
            s.name AS service_name
          FROM provider_jobs pj
          JOIN bookings b ON b.id = pj.booking_id
          JOIN users c ON c.id = b.customer_id
          JOIN services s ON s.id = b.service_id
          WHERE pj.provider_id = ?
          ORDER BY pj.id DESC
        ''',
        [auth.userId],
      );

      final requests = <Map<String, Object?>>[];
      final active = <Map<String, Object?>>[];
      final completed = <Map<String, Object?>>[];

      for (final row in rows) {
        final mapped = {
          'id': row['id'].toString(),
          'status': row['job_status'],
          'name': row['customer_name'],
          'service': row['service_name'],
          'address': row['address'],
          'date': '${row['booking_date']} ${row['time_slot']}',
          'price': row['price'],
        };

        final status = (row['job_status'] as String).toLowerCase();
        if (status.contains('pending')) {
          requests.add(mapped);
        } else if (status.contains('progress')) {
          active.add(mapped);
        } else {
          completed.add(mapped);
        }
      }

      return ok(
          {'requests': requests, 'active': active, 'completed': completed});
    } catch (_) {
      return internalError();
    }
  }

  Response acceptJob(Request request, String id) {
    return _updateJobStatus(
        id: id, newJobStatus: 'In Progress', newBookingStatus: 'Accepted');
  }

  Response declineJob(Request request, String id) {
    return _updateJobStatus(
        id: id, newJobStatus: 'Declined', newBookingStatus: 'Rejected');
  }

  Response completeJob(Request request, String id) {
    return _updateJobStatus(
        id: id, newJobStatus: 'Completed', newBookingStatus: 'Completed');
  }

  Response _updateJobStatus({
    required String id,
    required String newJobStatus,
    required String newBookingStatus,
  }) {
    try {
      final jobId = int.tryParse(id);
      if (jobId == null) {
        return badRequest('Invalid job id.');
      }

      final rows = db.select(
        'SELECT booking_id FROM provider_jobs WHERE id = ? LIMIT 1',
        [jobId],
      );
      if (rows.isEmpty) {
        return notFound('Provider job not found.');
      }

      final bookingId = rows.first['booking_id'] as int;
      db.execute(
        'UPDATE provider_jobs SET status = ?, updated_at = ? WHERE id = ?',
        [newJobStatus, DateTime.now().toIso8601String(), jobId],
      );
      db.execute('UPDATE bookings SET status = ? WHERE id = ?',
          [newBookingStatus, bookingId]);

      return ok({
        'jobId': jobId,
        'jobStatus': newJobStatus,
        'bookingStatus': newBookingStatus,
      });
    } catch (_) {
      return internalError();
    }
  }
}
