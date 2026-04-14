// backend\lib\src\handlers\customer_handler.dart
import 'package:shelf/shelf.dart';
import 'package:sqlite3/sqlite3.dart';

import '../http/error_response.dart';
import '../http/json_response.dart';

class CustomerHandler {
  CustomerHandler({required this.db});

  final Database db;

  Response getServices(Request request) {
    try {
      final query = (request.url.queryParameters['query'] ??
              request.url.queryParameters['q'] ??
              '')
          .trim()
          .toLowerCase();

      final whereClause = query.isEmpty
          ? ''
          : 'WHERE lower(s.name) LIKE ? OR lower(c.name) LIKE ?';
      final params = query.isEmpty ? <Object?>[] : ['%$query%', '%$query%'];

      final rows = db.select(
        '''
          SELECT s.id, s.name, c.name AS category, s.image, s.price, s.original_price,
                 s.discount, s.rating, s.reviews, s.duration, s.distance, s.is_active
          FROM services s
          JOIN categories c ON c.id = s.category_id
          $whereClause
          ORDER BY s.rating DESC, s.id DESC
        ''',
        params,
      );

      return ok(rows.map(_serviceToMap).toList());
    } catch (_) {
      return internalError();
    }
  }

  Response getRecommendedServices(Request request) {
    try {
      final rows = db.select(
        '''
          SELECT s.id, s.name, c.name AS category, s.image, s.price, s.original_price,
                 s.discount, s.rating, s.reviews, s.duration, s.distance, s.is_active
          FROM services s
          JOIN categories c ON c.id = s.category_id
          WHERE s.is_active = 1
          ORDER BY s.rating DESC, s.reviews DESC
          LIMIT 6
        ''',
      );

      return ok(rows.map(_serviceToMap).toList());
    } catch (_) {
      return internalError();
    }
  }

  Response getCategories(Request request) {
    try {
      final rows =
          db.select('SELECT id, name, image FROM categories ORDER BY name ASC');
      return ok(
        rows
            .map(
              (row) => {
                'id': row['id'],
                'name': row['name'],
                'image': row['image'],
              },
            )
            .toList(),
      );
    } catch (_) {
      return internalError();
    }
  }

  Response getServiceById(Request request, String id) {
    try {
      final parsedId = int.tryParse(id);
      if (parsedId == null) {
        return badRequest('Invalid service id.');
      }

      final rows = db.select(
        '''
          SELECT s.id, s.name, c.name AS category, s.image, s.price, s.original_price,
                 s.discount, s.rating, s.reviews, s.duration, s.distance, s.is_active
          FROM services s
          JOIN categories c ON c.id = s.category_id
          WHERE s.id = ?
          LIMIT 1
        ''',
        [parsedId],
      );

      if (rows.isEmpty) {
        return notFound('Service not found.');
      }

      return ok(_serviceToMap(rows.first));
    } catch (_) {
      return internalError();
    }
  }

  Map<String, Object?> _serviceToMap(Row row) {
    final price = row['price'] as int;
    final originalPrice = row['original_price'] as int;
    return {
      'id': row['id'],
      'name': row['name'],
      'category': row['category'],
      'image': row['image'],
      'price': price,
      'originalPrice': originalPrice,
      'discount': row['discount'],
      'rating': row['rating'],
      'reviews': row['reviews'],
      'duration': row['duration'],
      'distance': row['distance'],
      'isActive': (row['is_active'] as int) == 1,
      'isFavorite': false,
    };
  }
}
